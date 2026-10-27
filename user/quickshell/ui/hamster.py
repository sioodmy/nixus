"""Private file shelf and explicitly started, temporary Cloudflare downloads.

Quickshell owns this process. JSON lines on stdin are commands; stdout is state.
The shelf stores references, while each share serves a private snapshot.
"""

import ctypes
import json
import os
from pathlib import Path
import queue
import re
import secrets
import shutil
import signal
import stat
import subprocess
import sys
import tempfile
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import quote, unquote, urlsplit
import zipfile


def local_file(value):
    url = urlsplit(value)
    if url.scheme == "file" and url.netloc in ("", "localhost"):
        path = Path(unquote(url.path))
    elif not url.scheme and value.startswith("/"):
        path = Path(value)
    else:
        raise ValueError("Upuść lokalny plik, nie adres internetowy.")
    path = path.resolve(strict=True)
    if not path.is_file():
        raise ValueError("Schowek przyjmuje pliki. Spakuj folder przed dodaniem.")
    return path


def die_with_parent(expected=None):
    # Linux: also clean up cloudflared if the desktop/backend is killed abruptly.
    parent = os.getppid()
    if expected is not None and parent != expected:
        os._exit(0)
    ctypes.CDLL(None).prctl(1, signal.SIGTERM)
    if os.getppid() != parent:
        os._exit(0)


class Share:
    def __init__(self, paths, minutes, events):
        self.events = events
        self.directory = tempfile.TemporaryDirectory(prefix="aero-hamster-")
        self.server = None
        self.process = None
        self.expires = time.time() + minutes * 60
        self.started = time.monotonic()
        self.url = ""
        self.secret = secrets.token_urlsafe(32)
        try:
            self.filename = paths[0].name if len(paths) == 1 else "Chomik.zip"
            self.snapshot = Path(self.directory.name) / "download"
            # Open nonblocking and reject nonregular replacements (FIFOs/devices).
            def open_file(path):
                fd = os.open(path, os.O_RDONLY | os.O_NONBLOCK | os.O_NOFOLLOW)
                source = os.fdopen(fd, "rb")
                if not stat.S_ISREG(os.fstat(fd).st_mode):
                    source.close()
                    raise ValueError("Można udostępniać tylko zwykłe pliki.")
                return source
            if len(paths) == 1:
                with open_file(paths[0]) as source, self.snapshot.open("wb") as dest:
                    shutil.copyfileobj(source, dest)
            else:
                with zipfile.ZipFile(self.snapshot, "w", zipfile.ZIP_STORED) as archive:
                    for index, path in enumerate(paths, 1):
                        with open_file(path) as source, archive.open(f"{index}/{path.name}", "w", force_zip64=True) as dest:
                            shutil.copyfileobj(source, dest)
            self.route = f"/{self.secret}/{quote(self.filename, safe='')}"
            share = self

            class Handler(BaseHTTPRequestHandler):
                def log_message(self, *_):
                    pass

                def do_HEAD(self):
                    self.respond(False)

                def do_GET(self):
                    self.respond(True)

                def respond(self, body):
                    if time.time() >= share.expires or urlsplit(self.path).path != share.route:
                        self.send_error(404)
                        return
                    try:
                        source = share.snapshot.open("rb")
                    except OSError:
                        self.send_error(410)
                        return
                    with source:
                        self.send_response(200)
                        self.send_header("Content-Type", "application/octet-stream")
                        self.send_header("Content-Length", str(os.fstat(source.fileno()).st_size))
                        self.send_header("Content-Disposition", "attachment; filename=download; filename*=UTF-8''" + quote(share.filename, safe=""))
                        self.send_header("Cache-Control", "no-store, private, max-age=0")
                        self.send_header("X-Content-Type-Options", "nosniff")
                        self.end_headers()
                        if body:
                            try:
                                shutil.copyfileobj(source, self.wfile)
                            except (BrokenPipeError, ConnectionResetError):
                                pass

            self.server = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
            self.server.daemon_threads = True
            threading.Thread(target=self.server.serve_forever, daemon=True).start()
            # An isolated config avoids picking up a user's named tunnel ingress.
            config = Path(self.directory.name) / "config.yml"
            config.write_text("{}\n")
            self.process = subprocess.Popen(
                [sys.executable, __file__, "--tunnel", str(os.getpid()), "tunnel", "--config", str(config), "--url",
                 f"http://127.0.0.1:{self.server.server_port}", "--no-autoupdate"],
                stdout=subprocess.DEVNULL, stderr=subprocess.PIPE, text=True,
            )
            threading.Thread(target=self.read_tunnel, daemon=True).start()
        except Exception:
            self.close()
            raise

    def read_tunnel(self):
        for line in self.process.stderr:
            match = re.search(r"https://[a-z0-9-]+\.trycloudflare\.com(?=[\s|/]|$)", line)
            if match:
                self.events.put((self, match.group(0) + self.route))

    def close(self):
        if self.process is not None:
            self.process.terminate()
            try:
                self.process.wait(timeout=3)
            except subprocess.TimeoutExpired:
                self.process.kill()
                self.process.wait()
            if self.process.stderr:
                self.process.stderr.close()
        if self.server is not None:
            self.server.shutdown()
            self.server.server_close()
        self.directory.cleanup()


class Stash:
    def __init__(self, state_dir=None):
        self.directory = Path(state_dir or os.environ.get("XDG_STATE_HOME", str(Path.home() / ".local/state"))) / "amethyst-aero"
        self.directory.mkdir(mode=0o700, parents=True, exist_ok=True)
        self.file = self.directory / "hamster.json"
        self.items = []
        self.position = {"x": 0.88, "y": 0.84, "screen": ""}
        self.share = None
        self.events = queue.Queue()
        self.error = ""
        self.notice = ""
        self.reaction = ""
        try:
            data = json.loads(self.file.read_text())
            self.items = data["items"][:100]
            self.position.update(data["position"])
        except (OSError, ValueError, KeyError, TypeError):
            pass

    def save(self):
        fd, name = tempfile.mkstemp(dir=self.directory, prefix=".hamster-")
        try:
            with os.fdopen(fd, "w") as stream:
                json.dump({"items": self.items, "position": self.position}, stream)
            os.replace(name, self.file)
        finally:
            if os.path.exists(name):
                os.unlink(name)

    def stop(self):
        if self.share:
            self.share.close()
            self.share = None

    def command(self, data):
        self.error = self.notice = ""
        self.reaction = ""
        action = data["action"]
        if action == "add":
            errors = []
            added = 0
            for value in data["urls"]:
                try:
                    path = local_file(value)
                    if any(item["path"] == str(path) for item in self.items):
                        continue
                    if len(self.items) >= 100:
                        raise ValueError("Policzki są pełne — limit to 100 plików.")
                    self.items.append({"id": secrets.token_hex(8), "path": str(path)})
                    added += 1
                except (OSError, ValueError) as error:
                    errors.append(str(error))
            self.error = "\n".join(dict.fromkeys(errors))
            self.notice = f"W policzkach: +{added}" if added else ""
            if added:
                self.reaction = data.get("reaction") if data.get("reaction") in {"drop", "screenshot"} else "drop"
        elif action == "remove":
            self.stop()
            self.items = [item for item in self.items if item["id"] != data["id"]]
        elif action == "clear":
            self.stop()
            self.items = []
        elif action == "position":
            self.position = {"x": max(0, min(1, float(data["x"]))), "y": max(0, min(1, float(data["y"]))), "screen": str(data["screen"])}
        elif action == "share":
            ids = data.get("ids", [])
            if not ids:
                raise ValueError("Wybierz pliki do udostępnienia.")
            paths = [Path(item["path"]) for item in self.items if item["id"] in ids]
            if len(paths) != len(set(ids)):
                raise ValueError("Nie znaleziono wybranych plików.")
            self.stop()
            self.share = Share(paths, max(1, min(60, int(data.get("minutes", 15)))), self.events)
        elif action == "stop":
            self.stop()
            self.notice = "Link wyłączony."
        elif action != "refresh":
            raise ValueError("Nieznane polecenie.")
        self.save()

    def state(self):
        items = []
        for item in self.items:
            path = Path(item["path"])
            try:
                size = path.stat().st_size
                available = path.is_file()
            except OSError:
                size, available = 0, False
            items.append({**item, "name": path.name, "url": path.as_uri(), "size": size, "available": available})
        share = self.share
        return {"items": items, "position": self.position, "error": self.error, "notice": self.notice,
                "reaction": self.reaction,
                "sharing": share is not None, "url": share.url if share else "",
                "expires": int(share.expires) if share else 0}

    def tick(self):
        changed = False
        while not self.events.empty():
            share, url = self.events.get_nowait()
            if share is self.share:
                share.url = url
                changed = True
        share = self.share
        if share:
            if time.time() >= share.expires:
                self.stop()
                self.notice = "Link wygasł. Pliki zostały w policzkach."
                changed = True
            elif share.process.poll() is not None or (not share.url and time.monotonic() - share.started > 45):
                self.stop()
                self.error = "Nie udało się uruchomić tunelu. Sprawdź połączenie i spróbuj ponownie."
                changed = True
        return changed


def main():
    die_with_parent()
    stash = Stash()
    commands = queue.Queue()
    def read_commands():
        for line in sys.stdin:
            commands.put(line)
        commands.put(None)
    threading.Thread(target=read_commands, daemon=True).start()
    def terminate(*_):
        raise SystemExit(0)
    signal.signal(signal.SIGTERM, terminate)
    def emit():
        print(json.dumps(stash.state(), ensure_ascii=False), flush=True)
    try:
        emit()
        while True:
            try:
                # Sleep indefinitely while idle; only a live share needs expiry checks.
                line = commands.get(timeout=0.5 if stash.share else None)
            except queue.Empty:
                if stash.tick():
                    emit()
                continue
            if line is None:
                break
            try:
                stash.command(json.loads(line))
            except (OSError, ValueError, KeyError, TypeError) as error:
                stash.error = str(error)
            emit()
    finally:
        stash.stop()


if __name__ == "__main__":
    if sys.argv[1:2] == ["--tunnel"]:
        die_with_parent(int(sys.argv[2]))
        os.execvp("cloudflared", ["cloudflared", *sys.argv[3:]])
    else:
        main()

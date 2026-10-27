"""Exercise shelf persistence and real HTTP downloads using a local tunnel fixture."""
import importlib.util
import io
import json
import os
from pathlib import Path
import queue
import signal
import subprocess
import sys
import tempfile
import time
import unittest
from unittest.mock import patch
from urllib.error import HTTPError
from urllib.request import Request, urlopen
import zipfile

SOURCE = Path(__file__).resolve().parents[1] / "ui/hamster.py"
spec = importlib.util.spec_from_file_location("hamster", SOURCE)
hamster = importlib.util.module_from_spec(spec)
spec.loader.exec_module(hamster)


class ShelfTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.directory = Path(self.temp.name)
        tunnel = self.directory / "cloudflared"
        tunnel.write_text(f"#!{sys.executable}\nimport time\nimport sys\nprint('https://hamster-test.trycloudflare.com', file=sys.stderr, flush=True)\ntime.sleep(60)\n")
        tunnel.chmod(0o700)
        self.env = patch.dict(os.environ, {"PATH": str(self.directory) + ":" + os.environ["PATH"]})
        self.env.start()
        self.stash = hamster.Stash(self.directory)
        self.a = self.directory / 'Zażółć # ? " %.txt'
        self.a.write_bytes(b"private file\x00\xff")
        self.b = self.directory / "second.txt"
        self.b.write_text("second")

    def tearDown(self):
        self.stash.stop()
        self.env.stop()
        self.temp.cleanup()

    def add(self, *paths):
        self.stash.command({"action": "add", "urls": [path.as_uri() for path in paths]})

    def share(self, ids=None):
        self.stash.command({"action": "share", "ids": ids or [item["id"] for item in self.stash.items], "minutes": 15})
        share = self.stash.share
        self.stash.events.get(timeout=5)
        return share, f"http://127.0.0.1:{share.server.server_port}"

    def test_references_persistence_and_originals(self):
        self.add(self.a, self.a, self.b)
        self.assertEqual(len(self.stash.items), 2)
        self.stash.command({"action": "position", "x": 0.3, "y": 0.4, "screen": "DP-1"})
        restored = hamster.Stash(self.directory)
        self.assertEqual(restored.items, self.stash.items)
        self.assertEqual(restored.position, {"x": 0.3, "y": 0.4, "screen": "DP-1"})
        self.assertEqual(self.stash.file.stat().st_mode & 0o777, 0o600)
        self.a.unlink()
        self.assertFalse(self.stash.state()["items"][0]["available"])
        self.stash.command({"action": "clear"})
        self.assertTrue(self.b.is_file())

    def test_reject_remote_urls_directories_and_full_shelf(self):
        self.stash.command({"action": "add", "urls": ["https://example.com/a", "file://remote/etc/passwd", self.directory.as_uri(), self.a.as_uri()]})
        self.assertEqual(len(self.stash.items), 1)
        self.assertTrue(self.stash.error)
        for index in range(105):
            path = self.directory / str(index)
            path.touch()
            self.add(path)
        self.assertEqual(len(self.stash.items), 100)
        self.assertIn("100", self.stash.error)

    def test_download_snapshot_secret_route_and_headers(self):
        self.add(self.a, self.b)
        share, base = self.share([self.stash.items[0]["id"]])
        self.a.write_text("changed after sharing")
        with urlopen(base + share.route) as response:
            self.assertEqual(response.read(), b"private file\x00\xff")
            self.assertEqual(response.headers["Cache-Control"], "no-store, private, max-age=0")
            self.assertEqual(response.headers["Content-Type"], "application/octet-stream")
            self.assertIn("filename*=UTF-8''", response.headers["Content-Disposition"])
        with urlopen(Request(base + share.route, method="HEAD")) as response:
            self.assertEqual(response.read(), b"")
        for path in ("/", "/hamster.json", "/../", f"/{share.secret}/../second.txt", share.route + "/extra"):
            with self.assertRaises(HTTPError) as error:
                urlopen(base + path)
            self.assertEqual(error.exception.code, 404)
        share.expires = time.time() - 1
        with self.assertRaises(HTTPError):
            urlopen(base + share.route)
        self.assertTrue(self.stash.tick())
        self.assertIsNone(self.stash.share)
        self.assertFalse(share.snapshot.exists())

    def test_zip_selected_only_duplicate_names_and_revoke(self):
        other_dir = self.directory / "other"
        other_dir.mkdir()
        other = other_dir / self.b.name
        other.write_text("another second")
        self.add(self.a, self.b, other)
        share, base = self.share([item["id"] for item in self.stash.items[1:]])
        with urlopen(base + share.route) as response, zipfile.ZipFile(io.BytesIO(response.read())) as archive:
            self.assertEqual(archive.namelist(), ["1/second.txt", "2/second.txt"])
            self.assertEqual(archive.read("2/second.txt"), b"another second")
        process = share.process
        self.stash.command({"action": "remove", "id": self.stash.items[0]["id"]})
        self.assertIsNotNone(process.poll())
        self.assertIsNone(self.stash.share)
        self.assertTrue(self.b.exists())

    def test_symlink_replacement_cannot_publish_another_file(self):
        self.add(self.a)
        self.a.unlink()
        self.a.symlink_to(self.b)
        with self.assertRaises(OSError):
            self.share()
        self.assertIsNone(self.stash.share)

    def test_tunnel_exit_clears_link(self):
        self.add(self.a)
        share, _ = self.share()
        share.process.terminate()
        share.process.wait(timeout=3)
        self.assertTrue(self.stash.tick())
        self.assertIsNone(self.stash.share)
        self.assertIn("tunelu", self.stash.error)

    def test_json_protocol_and_stdin_eof_cleanup(self):
        env = {**os.environ, "XDG_STATE_HOME": str(self.directory / "protocol")}
        process = subprocess.Popen([sys.executable, "-u", str(SOURCE)], stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True, env=env)
        try:
            self.assertEqual(json.loads(process.stdout.readline())["items"], [])
            process.stdin.write(json.dumps({"action": "add", "urls": [self.b.as_uri()]}) + "\n")
            process.stdin.flush()
            item = json.loads(process.stdout.readline())["items"][0]
            process.stdin.write(json.dumps({"action": "share", "ids": [item["id"]]}) + "\n")
            process.stdin.flush()
            self.assertTrue(json.loads(process.stdout.readline())["sharing"])
            state = json.loads(process.stdout.readline())
            self.assertTrue(state["url"].startswith("https://hamster-test.trycloudflare.com/"))
            process.stdin.close()
            self.assertEqual(process.wait(timeout=5), 0)
        finally:
            if process.poll() is None:
                process.kill()
                process.wait()
            process.stdout.close()


if __name__ == "__main__":
    unittest.main()

#!/usr/bin/env bash
# Isolated Wayland + PAM integration test. Never locks the user's compositor.
set -euo pipefail
source_dir=$(cd -- "$(dirname -- "$0")/../ui" && pwd)
qs_binary=${QS_BINARY:-qs}
sway_binary=${SWAY_BINARY:-sway}
wtype_binary=${WTYPE_BINARY:-wtype}
: "${PAM_MODULE_DIR:?Set PAM_MODULE_DIR to the directory containing pam_exec.so}"
test_dir=$(mktemp -d)
cleanup() {
    kill "${locker_pid:-}" "${compositor_pid:-}" 2>/dev/null || true
    wait "${locker_pid:-}" "${compositor_pid:-}" 2>/dev/null || true
    if [[ ${1:-0} != 0 ]]; then cat "$test_dir/lock.log" 2>/dev/null || true; fi
    find "$test_dir" -depth -delete
}
trap 'cleanup "$?"' EXIT
cp -r "$source_dir" "$test_dir/ui"
mkdir -m 700 "$test_dir/runtime"
mkdir "$test_dir/pam"
# Only this temporary copy exposes read-only test status and uses fixture PAM.
node --input-type=module - "$test_dir" <<'JS'
import fs from 'node:fs';
const dir = process.argv[2];
const file = `${dir}/ui/lock.qml`;
let qml = fs.readFileSync(file, 'utf8');
qml = qml.replace('config: "aero-lock"', `config: "aero-lock"\n        configDirectory: ${JSON.stringify(`${dir}/pam`)}`);
qml = qml.replace('id: root', `id: root\n    IpcHandler { target: "test"; function status(): string { return JSON.stringify({secure: lock.secure, authenticated: root.authenticated, status: root.status}); } }`);
// Do not change the real session's logind LockedHint during isolated tests.
qml = qml.replace(/\["busctl"[^\]]+\]/g, '["true"]');
fs.writeFileSync(file, qml);
JS
printf '#!%s\n' "$(command -v perl)" > "$test_dir/check-password"
cat >> "$test_dir/check-password" <<'PERL'
local $/;
my $response = <STDIN> // "";
$response =~ s/\x00$//;
exit($response eq "test-correct-password" ? 0 : 1);
PERL
chmod +x "$test_dir/check-password"
printf 'auth required %s/pam_exec.so expose_authtok %s/check-password\n' "$PAM_MODULE_DIR" "$test_dir" > "$test_dir/pam/aero-lock"
printf 'output * mode 1440x900\nseat seat0 fallback true\n' > "$test_dir/sway.conf"
unset WAYLAND_DISPLAY SWAYSOCK HYPRLAND_INSTANCE_SIGNATURE
export XDG_RUNTIME_DIR="$test_dir/runtime"
WLR_BACKENDS=headless WLR_RENDERER=pixman WLR_LIBINPUT_NO_DEVICES=1 \
    "$sway_binary" --unsupported-gpu -c "$test_dir/sway.conf" > "$test_dir/sway.log" 2>&1 &
compositor_pid=$!
export WAYLAND_DISPLAY=wayland-1 QT_QUICK_CONTROLS_STYLE=Basic
for attempt in {1..50}; do
    for socket in "$XDG_RUNTIME_DIR"/wayland-*; do
        if [[ -S "$socket" ]]; then export WAYLAND_DISPLAY="${socket##*/}"; break 2; fi
    done
    sleep 0.1
done
[[ -S "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY" ]]
"$qs_binary" -p "$test_dir/ui/lock.qml" --no-color > "$test_dir/lock.log" 2>&1 &
locker_pid=$!
sleep 1
status() { "$qs_binary" -p "$test_dir/ui/lock.qml" ipc call test status; }
status | node -e 'let s=""; for await (const c of process.stdin) s+=c; if (!JSON.parse(s).secure) process.exit(1);'
"$wtype_binary" -s 300 -d 50 test-wrong-password -k Return
sleep 3
status | node -e 'let s=""; for await (const c of process.stdin) s+=c; const r=JSON.parse(s); if (!r.secure || r.authenticated || !r.status.includes("Błąd")) process.exit(1);'
"$wtype_binary" -s 300 -d 50 test-correct-password -k Return
for attempt in {1..50}; do
    kill -0 "$locker_pid" 2>/dev/null || break
    sleep 0.1
done
! kill -0 "$locker_pid" 2>/dev/null
wait "$locker_pid"
if rg 'ReferenceError|TypeError|Binding loop|ERROR' "$test_dir/lock.log"; then exit 1; fi
printf 'PASS: secure lock, rejected password stays locked, accepted password unlocks and exits.\n'

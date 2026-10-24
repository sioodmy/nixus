#!/usr/bin/env bash
set -euo pipefail
test_source_dir=$(cd -- "$(dirname -- "$0")" && pwd)
qs_binary=${QS_BINARY:-qs}
test_config_dir=$(mktemp -d)
trap 'rm -rf -- "$test_config_dir"' EXIT
for file in Notices.qml Desktop.qml Theme.qml palette.json; do
    cp "$test_source_dir/../ui/$file" "$test_config_dir/"
done
printf 'singleton Notices 1.0 Notices.qml\nsingleton Desktop 1.0 Desktop.qml\nsingleton Theme 1.0 Theme.qml\n' > "$test_config_dir/qmldir"
cp "$test_source_dir/notifications.qml" "$test_config_dir/shell.qml"
env AERO_PREVIEW=1 QT_QPA_PLATFORM=wayland QT_QPA_PLATFORMTHEME=generic \
    timeout 10 dbus-run-session -- "$qs_binary" --no-color --path "$test_config_dir"

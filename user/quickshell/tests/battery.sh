#!/usr/bin/env bash
set -euo pipefail
source_dir=$(cd -- "$(dirname -- "$0")" && pwd)
test_dir=$(mktemp -d)
trap 'find "$test_dir" -depth -delete' EXIT
cp "$source_dir/../ui/BatteryInfo.qml" "$test_dir/"
cp "$source_dir/battery.qml" "$test_dir/shell.qml"
printf 'singleton BatteryInfo 1.0 BatteryInfo.qml\n' > "$test_dir/qmldir"
QT_QPA_PLATFORM=offscreen timeout 10 "${QS_BINARY:-qs}" -p "$test_dir" --no-color > "$test_dir/result.log" 2>&1
cat "$test_dir/result.log"
rg -q 'PASS: battery' "$test_dir/result.log"
if rg 'Error:|TypeError|ReferenceError|Binding loop|Unable to assign|ERROR' "$test_dir/result.log"; then exit 1; fi

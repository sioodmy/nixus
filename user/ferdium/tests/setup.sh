#!/usr/bin/env bash
set -euo pipefail
package=${1:?Pass the built Ferdium Aero package}
fixture=$(mktemp -d)
trap 'rm -rf "$fixture"' EXIT
export FERDIUM_AERO_DATA_DIR="$fixture"
mkdir -p "$fixture/config" "$fixture/recipes/whatsapp" "$fixture/recipes/messenger"
printf '%s\n' '{"unrelated":"preserved","darkMode":false,"useSelfSignedCertificates":false}' > "$fixture/config/settings.json"
printf 'original app CSS\n' > "$fixture/config/custom.css"
for service in whatsapp messenger; do
  printf '{"id":"%s","version":"1.0.0","config":{"preserved":true}}\n' "$service" > "$fixture/recipes/$service/package.json"
  printf 'original recipe logic\n' > "$fixture/recipes/$service/webview.js"
  printf 'original service CSS\n' > "$fixture/recipes/$service/user.css"
done
printf 'module.exports = () => {};\n' > "$fixture/recipes/messenger/user.js"
"$package/share/amethyst-aero/setup"
jq -e '.unrelated == "preserved" and .darkMode == true and .universalDarkMode == false and .useSelfSignedCertificates == false' "$fixture/config/settings.json" >/dev/null
for service in whatsapp messenger; do
  jq -e '.version == "999.999.999" and .config.preserved == true' "$fixture/recipes/$service/package.json" >/dev/null
  cmp "$fixture/recipes/$service/user.css" "$package/share/amethyst-aero/$service.css"
  test "$(cat "$fixture/recipes/$service/webview.js")" = 'original recipe logic'
  test "$(cat "$fixture/recipes/$service/user.css.pre-aero.bak")" = 'original service CSS'
done
test "$(cat "$fixture/config/custom.css.pre-aero.bak")" = 'original app CSS'
test "$(cat "$fixture/recipes/messenger/user.pre-aero.js")" = 'module.exports = () => {};'
grep -q 'amethyst-messenger-hook' "$fixture/recipes/messenger/user.js"
test -s "$fixture/recipes/messenger/amethyst-messenger.js"
"$package/share/amethyst-aero/setup"
test "$(cat "$fixture/config/custom.css.pre-aero.bak")" = 'original app CSS'
test "$(cat "$fixture/recipes/messenger/user.css.pre-aero.bak")" = 'original service CSS'
test "$(cat "$fixture/recipes/messenger/user.pre-aero.js")" = 'module.exports = () => {};'
# A running Electron process owns settings.json; setup must leave it alone.
printf '{"runningProfile":true}\n' > "$fixture/config/settings.json"
ln -s "$(hostname)-$$" "$fixture/SingletonLock"
"$package/share/amethyst-aero/setup"
jq -e '.runningProfile == true and (has("darkMode") | not)' "$fixture/config/settings.json" >/dev/null
printf 'Installer: preservation, backups, repeat runs and live-profile handling passed.\n'

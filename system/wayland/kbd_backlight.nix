{ pkgs, ... }:
let
  keylit = pkgs.writeShellScriptBin "keylit" ''
    if command -v aero-kbd-brightness >/dev/null 2>&1; then
      exec aero-kbd-brightness "''${1:-toggle}"
    fi

    dev="/sys/class/leds/kbd_backlight"
    if [ ! -d "$dev" ]; then
      dev=$(ls -d /sys/class/leds/*kbd_backlight* 2>/dev/null | head -n 1 || true)
    fi
    [ -n "$dev" ] && [ -d "$dev" ] || exit 0

    target="''${1:-toggle}"
    case "$target" in
      toggle)
        cur=$(cat "$dev/brightness" 2>/dev/null || echo 0)
        max=$(cat "$dev/max_brightness" 2>/dev/null || echo 255)
        if [ "$cur" -eq 0 ]; then
          new=$(( max / 2 ))
        elif [ "$cur" -ge "$max" ]; then
          new=0
        else
          new=$max
        fi
        if [ -w "$dev/brightness" ]; then
          echo "$new" > "$dev/brightness"
        else
          ${pkgs.brightnessctl}/bin/brightnessctl -d '*kbd_backlight*' set "$new" >/dev/null 2>&1 || true
        fi
        ;;
      *)
        if ! ${pkgs.brightnessctl}/bin/brightnessctl -d '*kbd_backlight*' set "$target" >/dev/null 2>&1; then
          if [ -w "$dev/brightness" ]; then
            echo "$target" > "$dev/brightness"
          fi
        fi
        ;;
    esac
  '';
in
{
  environment.systemPackages = [
    keylit
    pkgs.brightnessctl
  ];

  systemd.tmpfiles.rules = [
    "z /sys/class/leds/*kbd_backlight*/brightness 0666 - - -"
  ];

  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="leds", KERNEL=="*kbd_backlight*", RUN+="${pkgs.coreutils}/bin/chmod a+w /sys/class/leds/%k/brightness"
    ACTION=="change", SUBSYSTEM=="leds", KERNEL=="*kbd_backlight*", RUN+="${pkgs.coreutils}/bin/chmod a+w /sys/class/leds/%k/brightness"
  '';
}

{ pkgs, inputs }:
let
  qs = inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default;
  runtime = with pkgs; [
    coreutils
    systemd
    procps
    util-linux
    xdg-utils
    xdg-user-dirs
    networkmanager
    networkmanagerapplet
    blueman
    bluez
    brightnessctl
    wireplumber
    playerctl
    pwvucontrol
    grim
    slurp
    wl-clipboard
    libnotify
    hyprland
    hyprlock
    nemo
  ];
in
pkgs.stdenvNoCC.mkDerivation {
  pname = "amethyst-aero";
  version = "1.0.0";
  src = ./ui;
  nativeBuildInputs = [ pkgs.makeWrapper ];
  dontBuild = true;
  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/amethyst-aero $out/bin
    cp -r . $out/share/amethyst-aero/
    makeWrapper ${qs}/bin/quickshell $out/bin/aeroshell \
      --add-flags "--no-duplicate --path $out/share/amethyst-aero" \
      --set QT_QUICK_CONTROLS_STYLE Basic \
      --set QT_QPA_PLATFORMTHEME qt6ct \
      --prefix QT_PLUGIN_PATH : "${pkgs.kdePackages.qt6ct}/${pkgs.qt6.qtbase.qtPluginPrefix}:${pkgs.kdePackages.qtstyleplugin-kvantum}/${pkgs.qt6.qtbase.qtPluginPrefix}" \
      --run 'export XDG_DATA_DIRS="$HOME/.local/share:$HOME/.nix-profile/share:/etc/profiles/per-user/$USER/share:/run/current-system/sw/share:${pkgs.kdePackages.oxygen-icons}/share:''${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"' \
      --prefix PATH : ${pkgs.lib.makeBinPath runtime}
    for action in launcher wifi bluetooth audio notifications session close; do
      makeWrapper $out/bin/aeroshell $out/bin/aero-$action \
        --add-flags "ipc call aero $action"
    done
    cat > $out/bin/aero-lock <<'EOF'
    #!${pkgs.runtimeShell}
    if ${pkgs.procps}/bin/pgrep -u "$UID" -x hyprlock >/dev/null; then
      exit 0
    fi
    exec ${pkgs.systemd}/bin/systemd-run --user --scope --quiet --collect \
      --unit=amethyst-lock --slice=session.slice \
      ${pkgs.hyprlock}/bin/hyprlock --grace 0 "$@"
    EOF
    cat > $out/bin/aero-screenshot <<'EOF'
    #!${pkgs.runtimeShell}
    set -eu
    output_dir="$(${pkgs.xdg-user-dirs}/bin/xdg-user-dir PICTURES)/Screenshots"
    mkdir -p "$output_dir"
    screenshot_file="$output_dir/$(date +%Y-%m-%d_%H-%M-%S-%N).png"
    case "''${1:-area}" in
      fullscreen) ${pkgs.grim}/bin/grim "$screenshot_file" ;;
      window)
        geometry=$(${pkgs.hyprland}/bin/hyprctl -j activewindow | ${pkgs.jq}/bin/jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')
        ${pkgs.grim}/bin/grim -g "$geometry" "$screenshot_file" ;;
      area)
        geometry=$(${pkgs.slurp}/bin/slurp) || exit 0
        ${pkgs.grim}/bin/grim -g "$geometry" "$screenshot_file" ;;
      *) exit 2 ;;
    esac
    ${pkgs.wl-clipboard}/bin/wl-copy --type image/png < "$screenshot_file"
    ${pkgs.libnotify}/bin/notify-send -i camera-photo "Zapisano zrzut ekranu" "$screenshot_file"
    EOF
    chmod +x $out/bin/aero-lock $out/bin/aero-screenshot
    cat > $out/bin/aero-directory <<'EOF'
    #!${pkgs.runtimeShell}
    case "''${1:-HOME}" in
      HOME) directory="$HOME" ;;
      DOCUMENTS|DOWNLOAD|PICTURES) directory="$(${pkgs.xdg-user-dirs}/bin/xdg-user-dir "$1")" ;;
      *) exit 2 ;;
    esac
    exec ${pkgs.nemo}/bin/nemo "$directory"
    EOF
    chmod +x $out/bin/aero-directory
    cat > $out/bin/aero-volume <<'EOF'
    #!${pkgs.runtimeShell}
    set -eu
    exec 9>"''${XDG_RUNTIME_DIR:-/run/user/$UID}/amethyst-volume.lock"
    ${pkgs.util-linux}/bin/flock 9
    node=@DEFAULT_AUDIO_SINK@
    kind=volume
    case "''${1:-}" in
      up) ${pkgs.wireplumber}/bin/wpctl set-volume -l 1 "$node" 5%+ ;;
      down) ${pkgs.wireplumber}/bin/wpctl set-volume "$node" 5%- ;;
      mute) ${pkgs.wireplumber}/bin/wpctl set-mute "$node" toggle ;;
      mic-mute)
        node=@DEFAULT_AUDIO_SOURCE@
        kind=microphone
        ${pkgs.wireplumber}/bin/wpctl set-mute "$node" toggle ;;
      *) exit 2 ;;
    esac
    status=$(${pkgs.wireplumber}/bin/wpctl get-volume "$node")
    percent=$(printf '%s\n' "$status" | ${pkgs.gawk}/bin/awk '{printf "%.0f", $2 * 100}')
    case "$status" in *MUTED*) muted=true ;; *) muted=false ;; esac
    shell_dir=$(${pkgs.coreutils}/bin/dirname "$(${pkgs.coreutils}/bin/readlink -f "$0")")
    "$shell_dir/aeroshell" ipc call aero showOsd "$kind" "$percent" "$muted" >/dev/null 2>&1 || true
    EOF
    cat > $out/bin/aero-brightness <<'EOF'
    #!${pkgs.runtimeShell}
    set -eu
    exec 9>"''${XDG_RUNTIME_DIR:-/run/user/$UID}/amethyst-brightness.lock"
    ${pkgs.util-linux}/bin/flock 9
    status=$(${pkgs.brightnessctl}/bin/brightnessctl -m -n 1 set "''${1:-5%+}")
    percent=$(printf '%s\n' "$status" | ${pkgs.gawk}/bin/awk -F, 'NR == 1 {gsub(/%/, "", $4); print $4}')
    case "$percent" in ""|*[!0-9]*) exit 1 ;; esac
    shell_dir=$(${pkgs.coreutils}/bin/dirname "$(${pkgs.coreutils}/bin/readlink -f "$0")")
    "$shell_dir/aeroshell" ipc call aero showOsd brightness "$percent" false >/dev/null 2>&1 || true
    EOF
    chmod +x $out/bin/aero-volume $out/bin/aero-brightness
    runHook postInstall
  '';
  meta = {
    description = "Amethyst Aero: a violet glass desktop for Quickshell";
    platforms = pkgs.lib.platforms.linux;
    mainProgram = "aeroshell";
  };
}

{ pkgs, inputs }:
let
  qs = inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default;
  icons = pkgs.callPackage ../icons { };
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
    grimblast
    slurp
    wl-clipboard
    libnotify
    hyprland
    nemo
    python3
    cloudflared
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
      --prefix QT_PLUGIN_PATH : "${pkgs.kdePackages.qt6ct}/${pkgs.qt6.qtbase.qtPluginPrefix}:${pkgs.kdePackages.qtstyleplugin-kvantum}/${pkgs.qt6.qtbase.qtPluginPrefix}:${pkgs.qt6.qtimageformats}/${pkgs.qt6.qtbase.qtPluginPrefix}" \
      --run 'export XDG_DATA_DIRS="${icons}/share:$HOME/.local/share:$HOME/.nix-profile/share:/etc/profiles/per-user/$USER/share:/run/current-system/sw/share:${pkgs.kdePackages.oxygen-icons}/share:''${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"' \
      --prefix PATH : ${pkgs.lib.makeBinPath runtime}
    for action in launcher wifi bluetooth audio notifications session close hamster; do
      makeWrapper $out/bin/aeroshell $out/bin/aero-$action \
        --add-flags "ipc call aero $action"
    done
    makeWrapper ${qs}/bin/quickshell $out/bin/aero-lock-ui \
      --add-flags "--no-duplicate --path $out/share/amethyst-aero/lock.qml" \
      --set QT_QUICK_CONTROLS_STYLE Basic \
      --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.systemd ]}
    cat > $out/bin/aero-lock <<'EOF'
    #!${pkgs.runtimeShell}
    # Keep the locker outside the desktop service's cgroup. flock also prevents
    # simultaneous idle/key/suspend requests racing to acquire the Wayland lock.
    exec ${pkgs.util-linux}/bin/flock --nonblock "''${XDG_RUNTIME_DIR:-/run/user/$UID}/amethyst-session.lock" \
      ${pkgs.systemd}/bin/systemd-run --user --scope --quiet --collect \
      --unit=amethyst-lock --slice=session.slice \
      @out@/bin/aero-lock-ui "$@"
    EOF
    substituteInPlace $out/bin/aero-lock --replace-fail '@out@' "$out"
    cat > $out/bin/aero-screenshot <<'EOF'
    #!${pkgs.runtimeShell}
    set -eu
    # `xdg-user-dir` falls back to $HOME when no user-dirs.dirs has been
    # generated yet; keep screenshots in the documented Pictures folder then.
    pictures="$(${pkgs.xdg-user-dirs}/bin/xdg-user-dir PICTURES)"
    if [ "$pictures" = "$HOME" ]; then
      pictures="$HOME/Pictures"
    fi
    output_dir="$pictures/Screenshots"
    mkdir -p "$output_dir"
    screenshot_file="$output_dir/$(date +%Y-%m-%d_%H-%M-%S-%N).png"
    # Grimblast (Hyprland contrib) handles region selection with slurp, the
    # active-window geometry and the clipboard copy. Cancelling the selection
    # exits non-zero without producing a file, so capture failures are treated
    # as "no screenshot" instead of tripping `set -e`.
    case "''${1:-area}" in
      fullscreen) target=screen ;;
      window) target=active ;;
      area) target=area ;;
      *) exit 2 ;;
    esac
    ${pkgs.grimblast}/bin/grimblast copysave "$target" "$screenshot_file" || true
    if [ ! -s "$screenshot_file" ]; then
      rm -f "$screenshot_file"
      exit 0
    fi
    # The hamster eats the file into its shelf and plays screenshot.webp.
    @out@/bin/aeroshell ipc call aero screenshot "$screenshot_file" >/dev/null 2>&1 || true
    ${pkgs.libnotify}/bin/notify-send -i camera-photo "Zapisano zrzut ekranu" "$screenshot_file" || true
    EOF
    substituteInPlace $out/bin/aero-screenshot --replace-fail '@out@' "$out"
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
    status=$(${pkgs.brightnessctl}/bin/brightnessctl -m --min-value=1 set "''${1:-5%+}")
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

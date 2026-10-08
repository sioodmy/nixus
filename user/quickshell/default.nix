{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.quickshell;

  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;
in
{
  options.quickshell = {
    enable = mkEnableOption "the Quickshell desktop shell";

    package = mkOption {
      type = types.package;
      default = inputs.backendqs.packages.${pkgs.stdenv.hostPlatform.system}.leninshell;
      defaultText = lib.literalExpression ''
        inputs.backendqs.packages.${pkgs.stdenv.hostPlatform.system}.leninshell
      '';
      description = ''
        The shell to run, i.e. the `leninshell` wrapper built from the
        Quickshell flake in ~/.config/quickshell.

        The wrapper bakes in `--path` for the QML that went into the build, so
        this option picks the configuration along with the binary — a change to
        the QML needs a rebuild (`nix profile install .#…` or a flake switch),
        not just a restart of the unit.
      '';
    };
  };

  config = mkIf cfg.enable {
    systemd.user.services.quickshell = {
      description = "Quickshell desktop shell (dock, launcher, lock screen, OSD)";
      documentation = [ "https://quickshell.outfoxxed.me/" ];

      # Started by Hyprland's autostart block (conf.d/08-autostart.lua) instead
      # of by graphical-session.target: system/wayland pulls that target in
      # *before* Hyprland is exec'd, and quickshell has no display to connect to
      # until the compositor is up, so a target dependency would buy nothing but
      # a crash loop at login. `systemctl --user start` from autostart is
      # idempotent, and `partOf` still takes the shell down with the session.
      partOf = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];

      # The systemd user manager's default PATH is NixOS' minimal one —
      # coreutils, findutils, grep, sed, systemd — and not even bash is on it.
      # The shell shells out constantly, so without a real PATH every one of
      # those Process calls fails to spawn and the feature silently disappears:
      # bash for backendqs and the pinned-apps state file, sh for the udev
      # backlight watcher, hyprctl to seed the focused window at startup,
      # pgrep/pkill to gate the recording indicator, brightnessctl for the OSD,
      # bluetoothctl and nmcli for the dock toggles, and run-as-service for
      # *every app the dock launches*.
      #
      # All of those live in the system profile, and that profile's bin is
      # exactly what the shell used to inherit when Hyprland exec'd it, so
      # naming the directory instead of re-listing the programs keeps this from
      # drifting away from the session as packages come and go.
      # /run/current-system/sw is repointed atomically on a switch, so the unit
      # survives one without being restarted.
      #
      # Service level, not serviceConfig: NixOS turns this into the
      # Environment="PATH=…" line, whereas systemd itself has no `path=` in
      # [Service] and would only warn about an unknown lvalue.
      path = [ "/run/current-system/sw" ];

      serviceConfig = {
        # No sd_notify in quickshell, and Type=simple would report "started" for
        # a process that is still resolving its QML.
        Type = "exec";
        ExecStart = "${cfg.package}/bin/leninshell";
        # The shell owns the lock screen, the screenshot and polkit surfaces: if
        # it dies, the session loses its way back in. Bring it back instead of
        # leaving a session without a dock. The wrapper passes `-n`, so a second
        # instance exits 0 rather than fighting the first — and exiting 0 is not
        # a failure, so it does not restart-loop.
        Restart = "on-failure";
        RestartSec = 2;
        # Give the shell a moment to tear its surfaces down; killing it outright
        # leaves orphaned layer-shell surfaces on screen.
        TimeoutStopSec = 5;
        Slice = "session.slice";
      };
    };
  };
}

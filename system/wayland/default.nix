{
  pkgs,
  lib,
  ...
}:
let
  # Hyprland is not systemd-aware, so nothing ever pulls in
  # `graphical-session.target`. That target is `RefuseManualStart=yes` and every
  # portal unit is `PartOf=`/`Requisite=` it, so `xdg-desktop-portal` fails to
  # start with "Dependency failed" and no portal backend is ever loaded: no file
  # chooser (ctrl+O in a browser), no screen sharing, no screenshot portal.
  #
  # `nixos-fake-graphical-session.target` exists for exactly this case: it
  # `BindsTo=graphical-session.target`, so starting it pulls the real target in
  # as a dependency (which sidesteps RefuseManualStart) while keeping both alive
  # for as long as the session runs.
  #
  # greetd execs this wrapper instead of Hyprland directly so the target is up
  # before the compositor, rather than depending on the config in user/hyprland.
  hyprland-session = pkgs.writeShellScript "hyprland-session" ''
    # greetd sets XDG_RUNTIME_DIR, but fall back to the conventional location so
    # `systemctl --user` can find the session bus either way.
    export XDG_RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

    ${pkgs.systemd}/bin/systemctl --user start nixos-fake-graphical-session.target

    exec ${lib.getExe pkgs.hyprland}
  '';
in
{
  imports = [
    ./kbd_backlight.nix
  ];
  hardware = {
    graphics.enable = true;
  };

  environment = {
    systemPackages =
      let

        run-as-service = pkgs.writeShellScriptBin "run-as-service" ''
          exec ${pkgs.systemd}/bin/systemd-run \
            --slice=app-manual.slice \
            --property=ExitType=cgroup \
            --user \
            --wait \
            bash -lc "exec $@"
        '';
      in
      [
        run-as-service
      ];
    sessionVariables = {
      NIXOS_OZONE_WL = 1;
      XDG_CURRENT_DESKTOP = "Hyprland";
      XDG_SESSION_TYPE = "wayland";
      XDG_SESSION_DESKTOP = "hyprland";

      SDL_VIDEODRIVER = "wayland";

      _JAVA_AWT_WM_NONEREPARENTING = "1";

      CLUTTER_BACKEND = "wayland";

      GDK_BACKEND = "wayland";

      QT_QPA_PLATFORM = "wayland";

      # Platform theme, cursor theme and font are set by user/gtk, which owns
      # both the GTK and the Qt side.
    };
  };

  systemd.services = {
    seatd = {
      enable = true;
      description = "Seat management daemon";
      script = "${pkgs.seatd}/bin/seatd -g wheel";
      serviceConfig = {
        Type = "simple";
        Restart = "always";
        RestartSec = "1";
      };
      wantedBy = [ "multi-user.target" ];
    };
  };

  services = {
    greetd = {
      enable = true;
      settings = rec {
        initial_session = {
          # The wrapper (see `hyprland-session` above) starts the graphical
          # session target and then execs Hyprland. The config itself lives in
          # user/hyprland and is linked into ~/.config/hypr by the homix module.
          command = hyprland-session;
          user = "sioodmy";
        };
        default_session = initial_session;
        terminal.vt = 1;
      };
    };

    gnome.glib-networking.enable = true;
    logind = {
      settings.Login = {
        HandlePowerKey = "suspend";
        HandleLidSwitchExternalPower = "lock";
        # TODO: switch to hibernate once available on asahi
        # prolly not coming soon tho :c
        HandleLidSwitch = "suspend";
      };
    };
  };
  programs.kdeconnect.enable = true;

  # xdg-desktop-portal-gtk stores the last-used directory in dconf; without the
  # dconf service it logs "failed to commit changes to dconf" on every dialog
  # and never remembers anything.
  programs.dconf.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-gnome
      # Hyprland's own portal implements ScreenCast/Screenshot/RemoteDesktop
      # on top of the Hyprland IPC socket. The gtk/gnome backends do not, so
      # screen sharing and the screenshot portal would be broken without it.
      pkgs.xdg-desktop-portal-hyprland
    ];

    # Hyprland ships share/xdg-desktop-portal/hyprland-portals.conf with the
    # same preference list; linking it keeps a session without the homix link
    # (fresh install, rescue) on the right backends too.
    configPackages = [ pkgs.hyprland ];
  };

  # Backend selection lives in ./portals.conf, linked into
  # ~/.config/xdg-desktop-portal/portals.conf. That location outranks
  # $XDG_CONFIG_DIRS and $XDG_DATA_DIRS, so it wins over the generated
  # /etc/xdg/xdg-desktop-portal/portals.conf and over the per-desktop files the
  # portal packages ship -- and it is what stops the gnome backend from
  # claiming ScreenCast, which otherwise leaves screen sharing hanging on
  # mutter, i.e. waiting forever for something that does not run here.
  homix.".config/xdg-desktop-portal/portals.conf".source = ./portals.conf;
}

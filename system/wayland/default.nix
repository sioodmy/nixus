{
  pkgs,
  ...
}:
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
      XDG_CURRENT_DESKTOP = "niri";
      XDG_SESSION_TYPE = "wayland";
      XDG_SESSION_DESKTOP = "niri";

      SDL_VIDEODRIVER = "wayland";

      _JAVA_AWT_WM_NONEREPARENTING = "1";

      CLUTTER_BACKEND = "wayland";

      GDK_BACKEND = "wayland";

      QT_QPA_PLATFORM = "wayland";
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
          command = "${pkgs.niri}/bin/niri-session";
          user = "sioodmy";
        };
        default_session = initial_session;
        terminal.vt = 1;
      };
    };

    gnome.glib-networking.enable = true;
    logind = {
      settings.Login = {
        HandleLidSwitchExternalPower = "lock";
        # TODO: switch to hibernate once available on asahi
        # prolly not coming soon tho :c
        HandleLidSwitch = "suspend";
      };
    };
  };
  programs.kdeconnect.enable = true;

  xdg.portal = {
    enable = true;
    config.common.default = [
      "gtk"
      "gnome"
    ];
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-gnome
    ];
  };
}

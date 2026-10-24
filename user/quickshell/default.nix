{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.quickshell;
  palette = builtins.fromJSON (builtins.readFile ./ui/palette.json);
  render =
    file:
    lib.replaceStrings
      (
        [
          "@wallpaper@"
          "@avatar@"
        ]
        ++ map (name: "@${name}@") (builtins.attrNames palette)
      )
      (
        [
          (toString ./ui/assets/wallpaper.png)
          "${pkgs.kdePackages.oxygen-icons}/share/icons/oxygen/base/128x128/places/user-identity.png"
        ]
        ++ map (name: lib.removePrefix "#" palette.${name}) (builtins.attrNames palette)
      )
      (builtins.readFile file);
in
{
  options.quickshell = {
    enable = lib.mkEnableOption "the Amethyst Aero desktop";
    package = lib.mkOption {
      type = lib.types.package;
      default = import ./package.nix { inherit pkgs inputs; };
      description = "Quickshell and Amethyst Aero, built from these dotfiles.";
    };
    panelSide = lib.mkOption {
      type = lib.types.enum [
        "left"
        "right"
      ];
      default = "left";
      description = "Edge used by the vertical panel and its flyouts.";
    };
    reducedMotion = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Disable optional shell transitions.";
    };
  };
  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      cfg.package
      pkgs.blueman
      pkgs.networkmanagerapplet
      pkgs.nemo
    ];
    programs.hyprlock.enable = true;
    services.blueman.enable = true;
    # Hyprlock enables hypridle in nixpkgs. Start it from Hyprland, after the
    # compositor has exported its environment, just like the shell.
    systemd.user.services.hypridle.wantedBy = lib.mkForce [ ];
    systemd.user.services.hypridle.path = [ cfg.package ];
    systemd.user.services.quickshell = {
      description = "Amethyst Aero desktop shell";
      partOf = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      path = [ "/run/current-system/sw" ];
      environment = {
        AERO_PANEL_SIDE = cfg.panelSide;
        AERO_REDUCED_MOTION = if cfg.reducedMotion then "1" else "0";
      };
      serviceConfig = {
        Type = "exec";
        ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p %h/.local/state/amethyst-aero";
        ExecStart = "${cfg.package}/bin/aeroshell";
        Restart = "on-failure";
        RestartSec = 2;
        TimeoutStopSec = 5;
        Slice = "session.slice";
      };
    };
    systemd.user.services.aero-wallpaper = {
      description = "Amethyst Aero wallpaper";
      partOf = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.swaybg}/bin/swaybg --mode fill --image ${./ui/assets/wallpaper.png}";
        Restart = "on-failure";
        RestartSec = 2;
      };
    };
    # Blueman owns the BlueZ pairing agent (PIN/passkey/authorization dialogs).
    systemd.user.services.aero-bluetooth-agent = {
      description = "Bluetooth pairing agent";
      partOf = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.blueman}/bin/blueman-applet";
        Restart = "on-failure";
        RestartSec = 3;
      };
    };
    homix = {
      ".config/hypr/hyprlock.conf".text = render ./hyprlock.conf;
      ".config/hypr/hypridle.conf".text = ''
        general {
          lock_cmd = aero-lock
          before_sleep_cmd = loginctl lock-session
          after_sleep_cmd = hyprctl dispatch dpms on
          inhibit_sleep = 3
        }
        listener {
          timeout = 300
          on-timeout = loginctl lock-session
        }
        listener {
          timeout = 600
          on-timeout = hyprctl dispatch dpms off
          on-resume = hyprctl dispatch dpms on
        }
      '';
    };
  };
}

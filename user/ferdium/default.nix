{ pkgs, ... }:
let
  theme = import ./theme.nix { inherit pkgs; };
in
{
  system.userActivationScripts.ferdiumAero.text = "${theme.setup}";
  systemd.user.services.ferdium-aero = {
    description = "Apply Amethyst Aero to Ferdium and its services";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${theme.setup}";
    };
  };
  systemd.user.paths.ferdium-aero = {
    description = "Theme newly installed Ferdium recipes";
    wantedBy = [ "default.target" ];
    pathConfig = {
      PathChanged = "%h/.config/Ferdium/recipes";
      Unit = "ferdium-aero.service";
      MakeDirectory = true;
    };
  };
}

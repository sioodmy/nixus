{ pkgs, ... }:
{
  environment.sessionVariables.BROWSER = "zen";
  # Update only browser associations, preserving the user's other MIME choices.
  systemd.user.services.zen-browser-default = {
    description = "Use Amethyst Aero Zen for web links";
    wantedBy = [ "default.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "zen-default-browser" ''
        ${pkgs.xdg-utils}/bin/xdg-mime default zen-aero.desktop \
          text/html application/xhtml+xml x-scheme-handler/http x-scheme-handler/https
      '';
    };
  };
}

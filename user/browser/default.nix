{ pkgs, ... }:
{
  environment.sessionVariables.BROWSER = "helium";

  xdg.mime.defaultApplications = {
    "text/html" = "helium.desktop";
    "application/xhtml+xml" = "helium.desktop";
    "x-scheme-handler/http" = "helium.desktop";
    "x-scheme-handler/https" = "helium.desktop";
    "x-scheme-handler/about" = "helium.desktop";
    "x-scheme-handler/unknown" = "helium.desktop";
  };

  systemd.user.services.helium-browser-default = {
    description = "Use Helium as default browser for web links";
    wantedBy = [ "default.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "helium-default-browser" ''
        ${pkgs.xdg-utils}/bin/xdg-mime default helium.desktop \
          text/html application/xhtml+xml x-scheme-handler/http x-scheme-handler/https
      '';
    };
  };
}

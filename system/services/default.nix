{ pkgs, ... }:
{
  programs.ssh = {
    startAgent = true;
    extraConfig = ''
      AddKeysToAgent yes
    '';
  };

  systemd.user.services.ssh-agent.serviceConfig.ExecStartPost =
    "${pkgs.systemd}/bin/systemctl --user set-environment SSH_AUTH_SOCK=%t/ssh-agent";

  services.syncthing = {
    enable = true;
    user = "sioodmy";
    dataDir = "/home/sioodmy/.config/syncthing";
    configDir = "/home/sioodmy/.config/syncthing";
    guiAddress = "127.0.0.1:8384";

    openDefaultPorts = true;
  };

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql;
    ensureDatabases = [ "dev" ];
    ensureUsers = [
      {
        name = "sioodmy";
        ensureClauses = {
          superuser = true;
          createdb = true;
        };
      }
    ];
    authentication = pkgs.lib.mkOverride 10 ''
      # type database DBuser origin-address auth-method
      local all all trust
      host all all 127.0.0.1/32 trust
      host all all ::1/128 trust
    '';
  };

  environment.systemPackages = with pkgs; [
    postgresql
    killall
  ];

  systemd.services.postgresql.serviceConfig.TimeoutStopSec = "10s";
  systemd.services.syncthing.serviceConfig.TimeoutStopSec = "10s";

  boot.kernel.sysctl."fs.inotify.max_user_watches" = 1048576;
}

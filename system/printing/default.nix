{ pkgs, ... }:
{
  services.printing.enable = true;
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };
  systemd.services.avahi-daemon.serviceConfig.ExecStartPre = [
    "+${pkgs.coreutils}/bin/rm -f /run/avahi-daemon/pid"
  ];
}

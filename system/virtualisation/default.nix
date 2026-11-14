{ pkgs, ... }:
{
  virtualisation.docker.enable = true;

  # docker sam w sobie ma compose jako plugin (`docker compose`); osobny
  # pakiet daje też klasyczne polecenie `docker-compose`.
  environment.systemPackages = [
    pkgs.docker-compose
  ];

  # root jest na tmpfs, więc obrazy i kontenery muszą wylądować na /persist
  staypls.dirs = [ "/var/lib/docker" ];
}

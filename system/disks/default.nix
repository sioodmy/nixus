{ ... }:
{
  # I know that this part will make some people mad

  # My configuraton is designed to be used only on desktops and laptops
  # therefore I use same partition layout for all of my hosts
  # I don't like mixing desktop and server configrations in a single flake

  staypls = {
    enable = true;
    dirs = [
      "/etc/ssh"
      "/etc/NetworkManager"
      "/etc/nix"
      "/var/lib/fprint"
      "/var/lib/pipewire"
      "/var/lib/bluetooth"
      "/var/lib/postgresql"
      "/var/lib/tailscale"
      "/var/cache/tailscale"
    ];
  };

  boot.initrd.luks.devices.luksroot = {
    device = "/dev/disk/by-label/NIXCRYPT";
    preLVM = true;
    allowDiscards = true;
    #    crypttabExtraOpts = ["fido2-device=auto" "token-timeout=10"];
  };

  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
    # if you need more than 1GB for root then
    # you are doing something wrong
    options = [
      "size=1G"
      "mode=755"
    ];
  };

  fileSystems."/nix" = {
    neededForBoot = true;
    device = "/dev/disk/by-label/NIXROOT";
    fsType = "btrfs";
    options = [
      "noatime"
      "discard"
      "subvol=@nix"
      "compress=zstd"
    ];
  };

  fileSystems."/tmp" = {
    device = "/dev/disk/by-label/NIXROOT";
    fsType = "btrfs";
    options = [
      "noatime"
      "discard"
      "subvol=@tmp"
    ];
  };

  fileSystems."/persist" = {
    neededForBoot = true;
    device = "/dev/disk/by-label/NIXROOT";
    fsType = "btrfs";
    options = [
      "noatime"
      "discard"
      "subvol=@persist"
      "compress=zstd"
    ];
  };

  fileSystems."/home" = {
    neededForBoot = true;
    device = "/dev/disk/by-label/NIXROOT";
    fsType = "btrfs";
    options = [
      "noatime"
      "discard"
      "subvol=@home"
      "compress=zstd"
    ];
  };

  #  btrfs filesystem mkswapfile --size 16g --uuid clear /persist/swap
  swapDevices = [
    {
      device = "/persist/swap";
      size = 8 * 1024;
    }
  ];
}

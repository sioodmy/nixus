{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf mkDefault;
  MHz = x: x * 1000;

  cfg = config.hardware.laptop;
  isIntel = config.hardware.cpu.intel.updateMicrocode or false;
  isAmd = config.hardware.cpu.amd.updateMicrocode or false;
in
{
  options = {
    hardware.laptop.enable = mkEnableOption "Enable laptop specific configuration";
  };

  config = mkIf cfg.enable {
    services = {
      thermald.enable = isIntel;
      fprintd.enable = true;
      undervolt = {
        enable = isIntel;
        # TODO: make options for that
        coreOffset = -95;
        gpuOffset = -80;
        tempBat = 65;
      };
      upower = {
        enable = true;
        percentageLow = 15;
        percentageCritical = 5;
        percentageAction = 3;
        criticalPowerAction = "Hibernate";
      };
      auto-cpufreq = {
        enable = true;
        settings = {
          battery = {
            governor = "powersave";
            scaling_min_freq = mkDefault (MHz 1800);
            scaling_max_freq = mkDefault (MHz 3900);
            turbo = "never";
          };
          charger = {
            governor = "performance";
            scaling_min_freq = mkDefault (MHz 2000);
            scaling_max_freq = mkDefault (MHz 4800);
            turbo = "auto";
          };
        };
      };
    };

    # https://github.com/NixOS/nixpkgs/issues/211345#issuecomment-1397825573
    systemd.tmpfiles.rules = lib.mkIf isAmd (
      map (e: "w /sys/bus/${e}/power/control - - - - auto") [
        "pci/devices/0000:00:01.0" # Renoir PCIe Dummy Host Bridge
        "pci/devices/0000:00:02.0" # Renoir PCIe Dummy Host Bridge
        "pci/devices/0000:00:14.0" # FCH SMBus Controller
        "pci/devices/0000:00:14.3" # FCH LPC bridge
        "pci/devices/0000:04:00.0" # FCH SATA Controller [AHCI mode]
        "pci/devices/0000:04:00.1/ata1" # FCH SATA Controller, port 1
        "pci/devices/0000:04:00.1/ata2" # FCH SATA Controller, port 2
        "usb/devices/1-3" # USB camera
      ]
    );
  };
}

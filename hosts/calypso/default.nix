{
  config,
  modulesPath,
  pkgs,
  ...
}:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];
  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        memtest86.enable = true;
        configurationLimit = 10;
        editor = false;
      };
      # spam space to get to boot menu
      timeout = 0;
    };
    loader.efi.canTouchEfiVariables = true;

    kernelPackages = pkgs.linuxPackages_xanmod_latest;
    kernelParams = [
      # fix for suspend issues
      # see: https://www.reddit.com/r/archlinux/comments/e5oe4p/comment/fa8mzft/
      "snd_hda_intel.dmic_detect=0"
      "acpi_osi=linux"
      "nowatchdog"
    ];
    initrd.availableKernelModules = [
      "xhci_pci"
      "ahci"
      "usbhid"
      "sd_mod"
      "dm_mod"
      "dm_crypt"
      "cryptd"
      "input_leds"
    ]
    ++ config.boot.initrd.luks.cryptoModules;
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/NIXBOOT";
    fsType = "vfat";
    options = [
      "noatime"
      "discard"
    ];
  };

  # For some reason my mic light indicator refuses to turn off on its own
  # it may not be a perfect solution, but it works
  # so stay mad I guess
  systemd.services.micmute-led-off = {
    description = "Turn off mic mute LED";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -c 'echo 0 > /sys/class/leds/platform::micmute/brightness'";
      TimeoutSec = 5;
    };
  };

  hardware.cpu.intel.updateMicrocode = true;
  hardware.graphics.extraPackages = builtins.attrValues {
    inherit (pkgs)
      intel-vaapi-driver
      libva
      libvdpau-va-gl
      libva-vdpau-driver
      ocl-icd
      intel-compute-runtime
      ;
  };

  hardware.laptop.enable = true;
}

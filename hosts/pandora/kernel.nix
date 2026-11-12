{
  lib,
  ...
}:
{
  # The linux-asahi attribute comes from hosts/pandora/aurora-kernel.nix.
  # apple-silicon-support's NixOS module feeds config.boot.kernelPatches into
  # it and sets boot.kernelPackages, so the kernel source and its tested
  # ALARM configuration replace the stock Asahi 7.2 tree here.
  #
  # The Aurora kernel keeps the distro configuration from alarm-aurora and
  # only adds NixOS requirements on top. That is why this file no longer
  # carries a trimmed defconfig: the extra drivers are the point of the
  # switch (M3/Neo bring-up, newer display/USB4/ANE code), and the kernel
  # package validates its config against the pinned asahi.config snapshot.

  # Aurora calls nixpkgs' low-level build.nix directly, so the generic
  # kernel defaults that advertise these features to NixOS are not applied.
  # systemd-boot asserts efiBootStub; the firewall uses netfilterRPFilter.
  boot.kernel.features = {
    efiBootStub = true;
    netfilterRPFilter = true;
    ia32Emulation = true;
  };

  # The Apple Silicon initrd set stays explicit. It is the upstream
  # asahi-scripts list plus the filesystem and dm setup modules for the
  # encrypted root.
  boot.initrd.includeDefaultModules = false;
  # Aurora's ALARM configuration builds some of the upstream initrd list
  # into the image (apple-dart, pcie-apple, dm_mod, sd_mod, ...). The names
  # stay in the list for readability; do not fail the build when a pin moves
  # a driver between built-in and module.
  boot.initrd.allowMissingModules = true;
  boot.initrd.systemd.tpm2.enable = false; # no TPM on Apple Silicon
  boot.initrd.availableKernelModules = lib.mkForce [
    "apple-dart"
    "apple-dockchannel"
    "apple-rtkit-helper"
    "apple_nvmem_spmi"
    "dm_crypt"
    "dm_mod"
    "dwc3"
    "dwc3-of-simple"
    "gpio_macsmc"
    "hid_apple"
    "hid_generic"
    "i2c-pasemi-platform"
    "macsmc"
    "macsmc-hwmon"
    "macsmc-input"
    "macsmc-power"
    "macsmc-reboot"
    "nvmem_apple_efuses"
    "nvme_apple"
    "pcie-apple"
    "phy-apple-atc"
    "pinctrl-apple-gpio"
    "rtc-macsmc"
    "sd_mod"
    "sn201202x"
    "spi-apple"
    "spi-hid-apple"
    "spi-hid-apple-of"
    "spmi-apple-controller"
    "tps6598x"
    "usb-storage"
    "usbhid"
    "xhci-pci"
    "xhci-plat-hcd"
  ];
  # Aurora builds the common ciphers and the userspace crypto API into the
  # kernel, so cryptsetup needs no crypto modules in the initrd. The NixOS
  # default list names modules this kernel does not ship separately.
  boot.initrd.luks.cryptoModules = lib.mkForce [ ];

  boot.kernelPatches = [
    {
      # The Aurora tree carries the T8103 ANE device and its DART/power
      # chain, but ships the nodes disabled as untested. The omarchy-ane
      # overlay used before the switch enabled the same nodes; this is the
      # kernel-tree equivalent for the in-tree DRM accel driver.
      name = "ane-t8103-enable";
      patch = ./ane-enable.patch;
    }
    {
      # glibc 2.44 (nixpkgs 26.11) ships asm/sigcontext.h using the __u128
      # type from newer kernel UAPI headers. The stale linux/types.h copy
      # under tools/include/uapi shadows glibc's own on the host-tool
      # include path, so aarch64 builds with BTF fail in resolve_btfids
      # with "unknown type name '__u128'". Aurora's tools/include/linux
      # copy is already fixed; only the uapi copy still needs the typedefs.
      name = "tools-uapi-u128";
      patch = ./tools-u128.patch;
    }
    {
      # Small config additions on top of Aurora's validated ALARM snapshot.
      # Everything else (btrfs, dm-crypt, zram, Tailscale, Bluetooth audio,
      # the Apple drivers and the ANE accel node) is already enabled there.
      name = "pandora-config";
      patch = null;
      structuredExtraConfig = with lib.kernel; {
        # Asahi exposes the m1n1 log and NVRAM as MTD partitions; keep the
        # cmdline parser that the boot chain uses for them.
        MTD_CMDLINE_PARTS = module;
      };
    }
  ];
}

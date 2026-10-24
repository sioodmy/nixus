{
  config,
  lib,
  pkgs,
  ...
}:
let
  # Follow the pinned Asahi kernel's own driver list, including new drivers
  # such as the video decoder. Do not copy the outdated 6.12 documentation.
  asahiKernel = pkgs.linux-asahi.kernel;
  kernelSource = asahiKernel.src;
  defconfigPatch = pkgs.runCommand "pandora-defconfig.patch" { } ''
    # Keep the upstream NixOS-compatible ARM64 baseline, but only Apple SoCs.
    sed '/^CONFIG_ARCH_/d' ${kernelSource}/arch/arm64/configs/defconfig > pandora_defconfig
    cat ${kernelSource}/arch/arm64/configs/asahi.config >> pandora_defconfig
    diff -u --label /dev/null --label b/arch/arm64/configs/pandora_defconfig \
      /dev/null pandora_defconfig > "$out" || test "$?" -eq 1
  '';
in
{
  # The Asahi callPackage wrapper ignores extra kernel arguments. Override
  # its buildLinux dependency so the config actually reaches the builder.
  boot.kernelPackages = lib.mkForce (
    pkgs.linuxPackagesFor (
      asahiKernel.override {
        buildLinux =
          args:
          pkgs.buildLinux (
            args
            // {
              defconfig = "pandora_defconfig";
              # Nixpkgs otherwise answers 'm' to every available driver,
              # regardless of whether it was enabled in defconfig.
              autoModules = false;
              # The distro config assumes all modules are enabled, so its
              # dependent settings may disappear in a hardware-specific build.
              # Retain its defaults, with required host/module settings supplied
              # by kernelPatches. Configuration errors still fail the build.
              enableCommonConfig = false;
              structuredExtraConfig = lib.mapAttrs (
                _: value: lib.mkDefault (value // { optional = true; })
              ) asahiKernel.configfile.structuredConfig;
              kernelPatches = args.kernelPatches ++ config.boot.kernelPatches;
            }
          );
      }
    )
  );

  # The trimmed kernel cannot supply the modules NixOS stage-1 defaults
  # assume (legacy SATA/PATA/USB controllers, vendor HID pins, TPM), so
  # keep the exact upstream Apple Silicon initrd module set instead.
  boot.initrd.includeDefaultModules = false;
  boot.initrd.systemd.tpm2.enable = false; # no TPM on Apple Silicon
  boot.initrd.availableKernelModules = lib.mkForce [
    # Upstream list from asahi-scripts (nixos-apple-silicon), followed by
    # the filesystem and dm setup modules for the encrypted root.
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
  # cryptsetup derives keys through af_alg; the NixOS default adds legacy
  # ciphers (blowfish/serpent/twofish/lrw) and built-ins this kernel does
  # not ship as modules.
  boot.initrd.luks.cryptoModules = lib.mkForce [
    "aes"
    "cbc"
    "xts"
    "af_alg"
    "algif_skcipher"
  ];

  boot.kernelPatches = [
    {
      name = "pandora-m1";
      patch = defconfigPatch;
      structuredExtraConfig = lib.mapAttrs (_: lib.mkForce) (
        with lib.kernel;
        {
          # Fail configuration if essential Asahi support is unavailable.
          ARCH_APPLE = yes;
          ARM64_16K_PAGES = yes;
          ARM64_MEMORY_MODEL_CONTROL = yes;
          RUST = yes;
          GCC_PLUGINS = no;
          DRM = yes;
          DRM_ASAHI = module;
          DRM_APPLE = module;
          PINCTRL = yes;
          PINCTRL_APPLE_GPIO = module;
          NVME_APPLE = module;
          SPI_HID_APPLE_OF = module;
          MFD_MACSMC = module;
          MACSMC_POWER = module;
          # Initrd SMC repair/battery/shutdown helpers. The NixOS initrd
          # module list refers to the .ko files these drivers build.
          INPUT_MACSMC_INPUT = module;
          SENSORS_MACSMC_HWMON = module;
          POWER_RESET_MACSMC = module;
          BRCMFMAC = module;
          BT_HCIBCM4377 = module;
          BT_LE = yes;
          BT_RFCOMM = module;
          BT_BNEP = module;
          BT_HIDP = module;
          VIDEO_APPLE_ISP = module;
          VIDEO_APPLE_AVD = module;
          SND_SOC_APPLE_MACAUDIO = module;
          SND_SOC_APPLE_AOP_AUDIO = module;
          # M1 Air headphone jack; not included in upstream asahi.config.
          SND_SOC_CS42L42 = module;
          SUSPEND = yes;
          HIBERNATION = no;
          NR_CPUS = freeform "8";

          # Boot/storage, encrypted btrfs, swap and ordinary USB peripherals.
          BLK_DEV_DM = module;
          DM_CRYPT = module;
          DM_SNAPSHOT = module;
          BTRFS_FS = module;
          EXT4_FS = module;
          VFAT_FS = module;
          SCSI = module;
          BLK_DEV_SD = module;
          USB_STORAGE = module;
          USB_UAS = module;
          USB_HID = module;
          HID_GENERIC = module;
          USB_XHCI_HCD = module;
          USB_XHCI_PCI = module;
          USB_XHCI_PLATFORM = module;
          USB_DWC3 = module;
          USB_DWC3_APPLE = module;
          USB_DWC3_DUAL_ROLE = yes;
          TYPEC_TPS6598X = module;
          # DB PD controller; part of the upstream initrd module list.
          TYPEC_SN201202X = module;
          USB4 = module;
          FUSE_FS = module;
          TUN = module; # Tailscale
          ZRAM = module;
          ZRAM_BACKEND_ZSTD = yes;
          MTD_PHRAM = module; # Asahi exposes nvram, ADT and m1n1 logs here
          MTD_CMDLINE_PARTS = module;
          ENCRYPTED_KEYS = module;
          BINFMT_MISC = module; # x86_64 emulation
          UHID = module; # Bluetooth HID
          LEDS_CLASS_MULTICOLOR = module;
          HID_LOGITECH = module;
          HID_LOGITECH_HIDPP = module; # attached mouse
          INPUT_UINPUT = module;
          INPUT_JOYDEV = module;
          INPUT_MOUSEDEV = module;
          SND_SEQUENCER = module;
          SND_SEQ_DUMMY = module;
          SND_HRTIMER = module;

          # NixOS firewall/Tailscale and cryptsetup's userspace crypto API.
          NF_TABLES = module;
          NF_CONNTRACK = module; # depends of NFT_CT/NATIVE/MASQ
          NETFILTER_XTABLES = module; # depends of NFT_COMPAT/xt matches
          NF_NAT = module;
          NF_TABLES_INET = yes;
          IP_NF_MATCH_RPFILTER = module;
          IP6_NF_MATCH_RPFILTER = module;
          NETFILTER_XT_TARGET_MASQUERADE = module;
          NETFILTER_XT_CONNMARK = module;
          NETFILTER_XT_MATCH_PKTTYPE = module;
          NFT_COMPAT = module;
          NFT_CT = module;
          NFT_NAT = module;
          NFT_MASQ = module;
          NFT_LOG = module;
          NFT_FIB_IPV4 = module;
          NFT_FIB_IPV6 = module;
          NFT_FIB_INET = module;
          NET_SCH_FQ_CODEL = module;
          UNIX_DIAG = module;
          CRYPTO_USER_API_HASH = module;
          CRYPTO_USER_API_SKCIPHER = module;
          CRYPTO_XTS = module;
          # Upstream arm64 defconfig builds kerberos/fscrypt crypto stacks
          # that select CBC built-in; forcing it back to m fails checkConfig.
          # Built-in CBC is fine for dm-crypt (cryptsetup always finds it).
          CRYPTO_CBC = yes;
          CRYPTO_CTR = module;
          CRYPTO_SHA256 = yes;
          # Built-in module signature verification (MODULE_SIG) selects
          # SHA512, so this cannot be a module.
          CRYPTO_SHA512 = yes;

          # Other GPUs, TV/radio receivers and server storage/fabrics.
          DRM_AMDGPU = no;
          DRM_NOUVEAU = no;
          DRM_RADEON = no;
          DRM_VMWGFX = no;
          DRM_ETNAVIV = no;
          DRM_LIMA = no;
          DRM_PANFROST = no;
          DRM_PANTHOR = no;
          DRM_POWERVR = no;
          MEDIA_ANALOG_TV_SUPPORT = no;
          MEDIA_DIGITAL_TV_SUPPORT = no;
          MEDIA_SDR_SUPPORT = no;
          MEDIA_PCI_SUPPORT = no;
          INFINIBAND = no;
          SCSI_LOWLEVEL = no;
          FUSION = no;
          ATA = no;
          NVME_TARGET = no;
          CEPH_FS = no;
          GFS2_FS = no;
          OCFS2_FS = no;
          STAGING = no;
          XEN = no;
          HYPERV = no;

          # Keep USB audio and the Apple ASoC stack, without hundreds of
          # unrelated codecs or PCI sound cards.
          SND_PCI = no;
          SND_SOC_SOF_TOPLEVEL = no;
          SND_USB_AUDIO = module;

          # Broadcom is the internal Wi-Fi; USB Ethernet remains available.
          WLAN_VENDOR_ATH = no;
          WLAN_VENDOR_INTEL = no;
          WLAN_VENDOR_MARVELL = no;
          WLAN_VENDOR_MEDIATEK = no;
          WLAN_VENDOR_RALINK = no;
          WLAN_VENDOR_REALTEK = no;
          WLAN_VENDOR_RSI = no;
          WLAN_VENDOR_ST = no;
          WLAN_VENDOR_TI = no;
        }
      );
    }
  ];
}

{ lib, ... }:
{
  # Trimmed kernel config for pandora (MacBook Air M1 8GB, t8103) on Asahi.
  #
  # The stock linux-asahi build uses the ARM64 defconfig + NixOS generic
  # options, which compiles a lot of stuff this laptop will never use
  # (datacenter RDMA, ancient framebuffers, non-Apple GPUs, TV cards,
  # Xen guests, ...). On 8GB of RAM that means a very long build.
  #
  # This patch is appended to linux-asahi via boot.kernelPatches
  # (see nixos-apple-silicon's kernel module, which forwards
  # config.boot.kernelPatches into the asahi kernel build).
  #
  # Two groups below:
  #   1. must-keep: required `yes`/`module`, taken from
  #      https://asahilinux.org/docs/sw/kernel-config/ so that
  #      microphone, speakers, keyboard, touchpad, backlight, wifi,
  #      bluetooth, display/GPU, camera, ALS, battery and NVMe keep
  #      working. Required (not optional) on purpose: if Asahi renames
  #      one of these symbols the build fails loudly instead of silently
  #      dropping e.g. keyboard support.
  #   2. trims: `option no`, i.e. best-effort. If a symbol is gone in a
  #      newer kernel or something selects it, you only get a warning,
  #      never a failed build.
  boot.kernelPatches = [
    {
      name = "pandora-m1-air-trim";
      patch = null;
      # Every value is forced: nixpkgs merges kernelPatches at the same
      # priority as its own common-config.nix, so any option that differs
      # from the generic default errors out with "conflicting definition
      # values". Forcing is still safe for the must-keep options:
      # `optional`/`required` is preserved, so a renamed Asahi symbol
      # still fails loudly at config time.
      structuredExtraConfig = lib.mapAttrs (_name: value: lib.mkForce value) (
        with lib.kernel;
        {
          # --- 1. Asahi / M1 Air must-keep (speakers, mic, HID, GPU...) ---
          ARCH_APPLE = yes;
          ARM64_MEMORY_MODEL_CONTROL = yes;
          APPLE_AIC = yes;
          APPLE_WATCHDOG = yes;
          APPLE_DART = yes;
          APPLE_SART = yes;
          APPLE_MAILBOX = yes;
          APPLE_RTKIT = yes;
          APPLE_RTKIT_HELPER = yes;
          MFD_MACSMC = module; # SMC core; all macsmc-* drivers hang off this
          APPLE_PMGR_PWRSTATE = yes;
          APPLE_PMGR_MISC = yes;
          I2C_APPLE = yes;
          # Built as modules, not built-in: `make config` asks these before
          # their Apple dependencies (e.g. APPLE_SART) are resolved, so a
          # forced `yes` is rejected as invalid and kills config generation
          # ("repeated question"). Modules are fine here, both are already
          # in the Asahi initrd module list.
          NVME_APPLE = module;
          PCIE_APPLE = module;
          PINCTRL_APPLE_GPIO = yes;
          PWM_APPLE = yes;
          SPI_APPLE = yes;
          SPMI_APPLE = yes;
          GPIO_MACSMC = module; # asked before MFD_MACSMC resolves, =yes rejected
          SENSORS_MACSMC_HWMON = module; # renamed since the 6.12 docs
          ARM_APPLE_SOC_CPUFREQ = yes;
          APPLE_ADMAC = yes;
          APPLE_M1_CPU_PMU = yes;
          COMMON_CLK_APPLE_NCO = yes;
          ARM_APPLE_CPUIDLE = yes;
          TOUCHSCREEN_APPLE_Z2 = module;
          INPUT_MACSMC_INPUT = module; # lid/buttons; renamed since 6.12 docs
          POWER_RESET_MACSMC = module; # asked before MFD_MACSMC resolves
          MACSMC_POWER = module; # battery/charger; renamed since 6.12 docs
          VIDEO_APPLE_ISP = module; # webcam
          DRM_ASAHI = yes; # GPU
          DRM_ADP = module;
          DRM_APPLE = module; # display / DCP
          DRM_APPLE_AUDIO = yes;
          APPLE_SIO = module;
          APPLE_SEP = yes;
          APPLE_AOP = yes;
          SND_SOC_APPLE_AOP_AUDIO = module; # audio backend
          SND_SOC_APPLE_MACAUDIO = module;
          SND_SOC_APPLE_MCA = module; # speakers + mic
          SND_SOC_CS42L84 = module; # headphone jack / mic codec
          SND_SOC_CS42L83 = module;
          SND_SOC_TAS2764 = module; # speaker amps
          SND_SOC_TAS2770 = module;
          SPI_HID_APPLE_OF = yes; # keyboard + touchpad transport
          HID_DOCKCHANNEL = module;
          HID_APPLE = module;
          HID_MAGICMOUSE = module;
          HID_WACOM = module; # USB/Bluetooth drawing tablets
          MOUSE_APPLETOUCH = module;
          INPUT_LEDS = module; # dep LEDS_CLASS resolves later, =yes rejected
          LEDS_PWM = module; # keyboard backlight
          BT_HCIBCM4377 = module; # bluetooth
          BT_HCIUART_BCM = option yes;
          RTC_DRV_MACSMC = module; # dep MFD_MACSMC is a module
          APPLE_DOCKCHANNEL = yes;
          PHY_APPLE_ATC = module; # USB-C / Thunderbolt PHY
          PHY_APPLE_DPTX = module;
          NVMEM_APPLE_EFUSES = yes;
          MUX_APPLE_DPXBAR = module;
          IIO_AOP_SENSOR_LAS = module; # ambient light sensor
          IIO_AOP_SENSOR_ALS = module;
          UCLAMP_TASK = yes;
          UCLAMP_TASK_GROUP = yes;
          SUSPEND = yes;
          CPU_FREQ_DEFAULT_GOV_SCHEDUTIL = yes;
          ENERGY_MODEL = yes;
          SERIAL_SAMSUNG = yes;
          SERIAL_SAMSUNG_CONSOLE = yes;
          REGULATOR_FIXED_VOLTAGE = yes;
          WATCHDOG_HANDLE_BOOT_ENABLED = yes;
          DRM_SCHED = yes;
          DRM_GEM_SHMEM_HELPER = yes;
          USB_XHCI_HCD = module;
          USB_XHCI_PCI_RENESAS = module; # dep USB_XHCI_PCI stays a module
          USB_XHCI_PCI_ASMEDIA = yes;
          USB_DWC3 = module;
          USB_DWC3_DUAL_ROLE = yes;
          TYPEC_TPS6598X = module; # USB-C PD
          MMC_SDHCI = module;
          MMC_SDHCI_PCI = module;
          # NOTE: no MMC_CQHCI opinion: SDHCI drivers select-force it to y.
          NET_VENDOR_AQUANTIA = yes; # Thunderbolt dock ethernet
          AQTION = module;
          NET_VENDOR_BROADCOM = yes;
          TIGON3 = module;
          BT = module;
          BT_BREDR = yes;
          BT_RFCOMM = module;
          BT_BNEP = module;
          BT_HIDP = module;
          BT_LE = yes;
          CFG80211 = module; # wifi stack (brcmfmac)
          WLAN_VENDOR_BROADCOM = yes;
          BRCMFMAC = module;
          BRCMFMAC_PROTO_BCDC = yes;
          BRCMFMAC_PROTO_MSGBUF = yes;
          BRCMFMAC_USB = option yes;
          BRCMFMAC_PCIE = option yes;
          APPLE_MFI_FASTCHARGE = module;

          # Display/keyboard backlight helpers (best-effort across versions).
          BACKLIGHT_APPLE_DWI = option module;
          DRM_PANEL_SUMMIT = option module;
          NVMEM_APPLE_SPMI = option module;

          # 8 CPU cores on the M1 Air; 16 leaves headroom while shrinking
          # per-cpu arrays vs the generic 384.
          NR_CPUS = option (freeform "16");

          # --- 2. Trims: datacenter / server storage + fabric ---
          INFINIBAND = option no;
          INFINIBAND_IPOIB = option no;
          INFINIBAND_IPOIB_CM = option no;
          RDMA_SIW = option no;
          RDMA_RXE = option no;
          CXL_BUS = option no;
          CXL_MEM = option no;
          CXL_PCI = option no;
          SCSI_LOWLEVEL = option no;
          SCSI_LOWLEVEL_PCMCIA = option no;
          SCSI_SAS_ATA = option no;
          FUSION = option no;
          MEGARAID_NEWGEN = option no;
          NET_FC = option no;
          HIPPI = option no;
          ATA = option no; # no SATA on this laptop (NVMe + USB only)
          ATA_SFF = option no;
          ATA_BMDMA = option no;
          SATA_AHCI = option no;
          NVME_TARGET = option no;
          NVME_TARGET_PASSTHRU = option no;
          NVME_TARGET_AUTH = option no;
          NVME_TARGET_TCP_TLS = option no;
          MLX5_CORE_EN = option no;
          FSL_MC_UAPI_SUPPORT = option no;
          ARM64_PMEM = option no;

          # --- Trims: exotic networking (no CAN/radio/ATM on a laptop) ---
          HAMRADIO = option no;
          AX25 = option no;
          CAN = option no;
          CAN_RAW = option no;
          CAN_BCM = option no;
          CAN_GW = option no;
          ATM = option no;
          DECNET = option no;
          SLIP_COMPRESSED = option no;
          SLIP_SMART = option no;

          # --- Trims: legacy framebuffers (simpledrm covers early boot) ---
          FB_NVIDIA_I2C = option no;
          FB_RIVA_I2C = option no;
          FB_ATY_CT = option no;
          FB_ATY_GX = option no;
          FB_SAVAGE_I2C = option no;
          FB_SAVAGE_ACCEL = option no;
          FB_SIS_300 = option no;
          FB_SIS_315 = option no;
          FB_3DFX_ACCEL = option no;
          AUXDISPLAY = option no;
          # No parallel ports on this laptop; also kills the PANEL driver
          # that select-forces AUXDISPLAY above back to y.
          PARPORT = option no;

          # --- Trims: non-Apple GPUs (only DRM_ASAHI/APPLE matter here) ---
          # No eGPU support on Asahi, so the discrete-GPU cores can go;
          # Thunderbolt USB-C docks are unaffected (no DRM driver there).
          DRM_AMDGPU = option no;
          DRM_NOUVEAU = option no;
          DRM_RADEON = option no;
          DRM_XE = option no;
          DRM_VMWGFX = option no; # VMware guest GPU; pandora is bare metal
          DRM_AMDGPU_SI = option no;
          DRM_AMDGPU_CIK = option no;
          DRM_AMD_DC_SI = option no;
          DRM_AMD_ACP = option no;
          DRM_AMD_ISP = option no;
          DRM_AMDGPU_USERPTR = option no;
          DRM_NOUVEAU_GSP_DEFAULT = option no;
          DRM_NOUVEAU_SVM = option no;
          DRM_I915_GVT = option no;
          DRM_I915_GVT_KVMGT = option no;
          DRM_HYPERV = option no;
          HYPERV = option no;
          FB_HYPERV = option no;
          DRM_VC4_HDMI_CEC = option no;
          ROCKCHIP_DW_HDMI_QP = option no;
          ROCKCHIP_DW_MIPI_DSI2 = option no;
          HSA_AMD = option no;
          HSA_AMD_P2P = option no;

          # --- Trims: TV/media/staging/IR (webcam via APPLE_ISP stays) ---
          MEDIA_DIGITAL_TV_SUPPORT = option no;
          MEDIA_ANALOG_TV_SUPPORT = option no;
          MEDIA_PCI_SUPPORT = option no;
          VIDEO_STK1160_COMMON = option no;
          STAGING = option no;
          STAGING_MEDIA = option no;
          RC_DEVICES = option no;
          RC_DECODERS = option no;
          LIRC = option no;

          # --- Trims: guest VMs / ChromeOS (bare-metal laptop) ---
          XEN = option no;
          XEN_DOM0 = option no;
          PCI_XEN = option no;
          HVC_XEN = option no;
          HVC_XEN_FRONTEND = option no;
          XEN_SYS_HYPERVISOR = option no;
          SWIOTLB_XEN = option no;
          XEN_BACKEND = option no;
          XEN_BALLOON = option no;
          XEN_BALLOON_MEMORY_HOTPLUG = option no;
          XEN_EFI = option no;
          XEN_HAVE_PVMMU = option no;
          XEN_MCE_LOG = option no;
          XEN_PVH = option no;
          XEN_PVHVM = option no;
          XEN_SAVE_RESTORE = option no;
          CHROME_PLATFORMS = option no;
          CHROMEOS_TBMC = option no;
          CROS_EC = option no;
          CROS_EC_I2C = option no;
          CROS_EC_SPI = option no;
          CROS_KBD_LED_BACKLIGHT = option no;
          TCG_TIS_SPI_CR50 = option no;
          GOOGLE_FIRMWARE = option no;

          # --- Trims: non-Broadcom wifi/BT (Apple uses brcmfmac/BCM4377) ---
          ATH9K_PCI = option no;
          ATH9K_AHB = option no;
          ATH9K_DFS_CERTIFIED = option no;
          ATH10K_DFS_CERTIFIED = option no;
          B43_PHY_HT = option no;
          B43 = option no;
          B43LEGACY = option no;
          BCMA_HOST_PCI = option no;
          RTL8XXXU_UNTESTED = option no;
          RTW88 = option no;
          RTW88_8822BE = option no;
          RTW88_8822CE = option no;
          NET_VENDOR_MEDIATEK = option no;
          MT7986_WMAC = option no;
          MT798X_WMAC = option no;
          IPW2100_MONITOR = option no;
          IPW2200_MONITOR = option no;
          HOSTAP_FIRMWARE = option no;
          HOSTAP_FIRMWARE_NVRAM = option no;
          MAC80211_MESH = option no;
          BT_HCIBTUSB_MTK = option no;
          BT_QCA = option no;
          BT_HCIUART_QCA = option no;
          BT_HCIUART_BCSP = option no;
          BT_HCIUART_LL = option no;

          # --- Trims: exotic/cluster filesystems (btrfs/ext4/vfat stay) ---
          CEPH_FS = option no;
          GFS2_FS = option no;
          OCFS2_FS = option no;
          JFS_FS = option no;
          REISERFS_FS = option no;
          NILFS2_FS = option no;
          ROMFS_FS = option no;
          QNX4FS_FS = option no;
          SYSV_FS = option no;
          UFS_FS = option no;
          BEFS_FS = option no;

          # --- Trims: non-Apple sound (Apple MCA/TAS/CS42Lxx stay) ---
          SND_HDA_CODEC_CS8409 = option no;
          SND_OSSEMUL = option no;
          SND_USB_CAIAQ_INPUT = option no;

          # --- Trims: gamepad rumble / non-Apple mice ---
          HID_ACRUX_FF = option no;
          DRAGONRISE_FF = option no;
          GREENASIA_FF = option no;
          HOLTEK_FF = option no;
          JOYSTICK_PSXPAD_SPI_FF = option no;
          LOGITECH_FF = option no;
          LOGIG940_FF = option no;
          LOGIWHEELS_FF = option no;
          NINTENDO_FF = option no;
          NVIDIA_SHIELD_FF = option no;
          PLAYSTATION_FF = option no;
          SONY_FF = option no;
          SMARTJOYPLUS_FF = option no;
          THRUSTMASTER_FF = option no;
          ZEROPLUS_FF = option no;
          LOGIRUMBLEPAD2_FF = option no;
          JOYSTICK_XPAD_FF = option no;
          JOYSTICK_XPAD_LEDS = option no;
          MOUSE_PS2_ELANTECH = option no;
          MOUSE_ELAN_I2C_SMBUS = option no;
          PINCTRL_AMD = option no;

          # Neutralizers: the family gates disabled above orphan some
          # common-config.nix children (they vanish from Kconfig
          # questioning, but common-config declares them as required,
          # which fails the build). Re-declared with identical values
          # but lenient, so a missing symbol is only a warning.
          AIC79XX_DEBUG_ENABLE = option no;
          AIC7XXX_DEBUG_ENABLE = option no;
          AIC94XX_DEBUG = option no;
          CEPH_FSCACHE = option yes;
          CEPH_FS_POSIX_ACL = option yes;
          HMM_MIRROR = option yes;
          MEDIA_ATTACH = option yes;
          DRM_AMD_DC_FP = option yes;
          DRM_AMD_SECURE_DISPLAY = option yes;
          SATA_MOBILE_LPM_POLICY = option (freeform "3");
        }
      );
    }
  ];
}

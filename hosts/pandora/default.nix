{
  config,
  modulesPath,
  lib,
  inputs,
  pkgs,
  ...
}:
let
  # MLX on the Apple GPU through the Honeykrisp Vulkan driver, plus the
  # local MLX Chat / serve CLIs. aarch64-only (cp314 linux_aarch64 wheel),
  # so it stays host-local instead of user/packages.nix.
  mlx-omarchy = pkgs.callPackage ../../user/mlx-omarchy { };
in
{
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/36D6-1718";
    fsType = "vfat";
    options = [
      "noatime"
      "discard"
    ];
  };
  imports = [
    inputs.apple-silicon-support.nixosModules.apple-silicon-support
    (modulesPath + "/installer/scan/not-detected.nix")
    ./kernel.nix
    (import "${inputs.aurora}/modules/firmware.nix")
    (import "${inputs.aurora}/modules/sep.nix")
  ];

  # apple-silicon-support registers its overlay just before this list, so
  # linux-asahi, mesa and the Touch ID userspace resolve to Aurora's; m1n1
  # and U-Boot stay Asahi's.
  nixpkgs.overlays = [ (import ./aurora.nix { inherit inputs; }) ];

  # Aurora's SEP module turns nixpkgs' "fingerprint on every PAM service"
  # default off and enables it for sudo/polkit. The shell's locker asks for
  # Touch ID first and falls back to the password; the password-only service
  # is used when the user starts typing while the sensor is still waiting.
  security.pam.services =
    let
      # A successful password on the lock screen also re-arms Touch ID after
      # the first boot/unlock, exactly as Aurora's sudo and polkit stacks do.
      rearm =
        service:
        let
          unix = config.security.pam.services.${service}.rules.auth.unix;
        in
        {
          unix.control = lib.mkForce "[success=ok new_authtok_reqd=ok default=2]";
          aurora-touchid-rearm = {
            inherit (unix) enable;
            order = unix.order + 1;
            control = "optional";
            modulePath = "${pkgs.aurora-touchid-rearm}/lib/security/pam_aurora_touchid.so";
          };
          aurora-touchid-rearm-done = {
            inherit (unix) enable;
            order = unix.order + 2;
            control = "sufficient";
            modulePath = "${pkgs.pam}/lib/security/pam_permit.so";
          };
        };
    in
    {
      sudo.fprintAuth = lib.mkForce true;
      polkit-1.fprintAuth = lib.mkForce true;
      aero-lock = {
        fprintAuth = lib.mkForce true;
        # Try Touch ID before the U2F key, then the password.
        rules.auth = rearm "aero-lock" // {
          u2f.order = lib.mkForce 11500;
        };
      };
      aero-lock-password = {
        fprintAuth = lib.mkForce false;
        # Typing means "password now"; do not wait for the security key.
        rules.auth = rearm "aero-lock-password" // {
          u2f.enable = lib.mkForce false;
        };
      };
    };

  hardware.asahi = {
    enable = true;
    # Aurora's firmware module extracts this Mac's vendor firmware from the
    # ESP into /run/aurora-firmware/vendorfw. Touch ID adds its calibration
    # links there; a read-only Nix store firmware path cannot take them.
    setupAsahiSound = true;
  };

  # The /var/lib keybag and refkey live on the tmpfs root until the staypls
  # bind mounts are active on the next boot. Seed /persist once from the
  # running system before that reboot.
  system.activationScripts.aurora-sep-persist = {
    text = ''
      install -d -m 700 /persist/var/lib/aurora-sep
      for f in aurora-sep-keybag.bin aurora-sep-refkey.bin; do
        if [ -s "/var/lib/$f" ] && [ ! -s "/persist/var/lib/$f" ]; then
          install -Dm600 "/var/lib/$f" "/persist/var/lib/$f"
        fi
      done
      if [ -d /var/lib/aurora-sep ]; then
        cp -an /var/lib/aurora-sep/. /persist/var/lib/aurora-sep/
      fi
    '';
  };

  # The M1 boot chain does not forward /chosen/apfs-preboot-uuid, so the SEP
  # driver has no OS identity and refuses enrolment ("no Linux SEP OS identity
  # is selected"). Pin a stable, Linux-only xART lane in modprobe.d, which is
  # the one place aurora-sep-load reads options from. Do not also put the same
  # parameters on the kernel command line: the Rust module parameters are
  # write-once, and the duplicate makes apple_sep fail to load with the
  # misleading "invalid for parameter". Both halves stay below 2^63 and use
  # decimal digits, and this is not macOS's APFS preboot UUID.
  boot.extraModprobeConfig = ''
    options apple_sep os_uuid_hi=5124095576030430 os_uuid_lo=4483583629026627
  '';

  # Touch ID from the first unlock after boot. With this off, the SEP driver
  # accepts the fingerprint immediately instead of waiting for one password.
  aurora.sep.requirePasswordAfterBoot = false;

  services.upower.enable = true;
  services.fwupd.enable = lib.mkForce false;
  services.pipewire.extraConfig.pipewire = {
    # https://www.reddit.com/r/linux_gaming/comments/1gy347h/comment/lylqijj/
    "10-clock-min-quantum" = {
      "context.properties" = {
        "default.clock.min-quantum" = "1024";
      };
    };
  };

  environment = {
    systemPackages =
      lib.attrValues {
        inherit (pkgs)
          asahi-bless
          asahi-fwextract
          ;

      }
      ++ [ mlx-omarchy ];
  };
  # /dev/cpu_dma_latency access for the backend's PM-QoS deep-idle hold.
  services.udev.packages = [ mlx-omarchy ];
  # Apple Neural Engine: the Aurora kernel carries the in-tree DRM accel
  # driver (M1 family, t8103). kernel.nix enables the device-tree nodes the
  # upstream tree ships disabled; systemd's default rule modes
  # /dev/accel/accel0 0666.
  boot.kernelModules = [ "ane" ];
  # mlx-omarchy's ANE worker ownership (install.sh --ane equivalent): the
  # worker seals against these root-owned files and refuses the device
  # without them.
  systemd.tmpfiles.rules = [
    "d /run/lock/mlx-omarchy-ane 01777 root root -"
    "f /run/lock/mlx-omarchy-ane/device.lock 0666 root root -"
    "f /run/lock/mlx-omarchy-ane/quarantine 0666 root root -"
  ];
  # Resident MLX Chat pair: reloads the saved model pair at login so the
  # first message does not pay the load time. Staged but not enabled, like
  # the upstream package; opt in per user with
  #   systemctl --user enable --now mlx-omarchy-chat.service
  systemd.user.units."mlx-omarchy-chat.service" = {
    text = ''
      [Unit]
      Description=MLX Chat resident pair
      After=default.target

      [Service]
      ExecStart=${mlx-omarchy}/bin/mlx-omarchy-chat --resume --no-browser
      Restart=on-failure
      RestartSec=15

      [Install]
      WantedBy=default.target
    '';
  };
  hardware.graphics.enable32Bit = lib.mkForce false;
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    # This refers to the uncompressed size, actual memory usage will be lower.
    memoryPercent = 50;
  };

  boot = {
    binfmt.emulatedSystems = [ "x86_64-linux" ];
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = lib.mkForce false;
    };

    initrd.availableKernelModules = [
      "usbhid"
      "usb_storage"
      "sd_mod"
    ];
    initrd.kernelModules = [
      "usbhid"
      "dm-snapshot"
    ];
  };
}

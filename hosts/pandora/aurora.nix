# Aurora Silicon's Apple Silicon kernel, cherry-picked from
# aurora-silicon/nixos-aurora.
#
# nixos-apple-silicon exposes linux-asahi as an overridable function and its
# NixOS module already feeds boot.kernelPatches into it. The kernel, Mesa and
# the Touch ID libfprint/fprintd userspace are replaced: the kernel names the
# AGX DRM driver "aurora" (stock Mesa rejects it) and exposes the Secure
# Enclave through /dev/sep-bio (stock libfprint has no Apple SEP driver).
# m1n1 and U-Boot stay as they are; vendor firmware comes from Aurora's
# runtime ESP handoff. The full Aurora overlay would swap those too.
{ inputs }:
final: prev:
let
  aurora = inputs.aurora;
  pins = builtins.fromJSON (builtins.readFile "${aurora}/sources.json");
  pin = pins.kernel-aurora;
  src =
    prev.fetchurl {
      name = "kernel-aurora-${pin.commit}.tar.gz";
      url = pin.source_url;
      hash = pin.nix_hash;
    }
    // {
      # The kernel package records this in its provenance output and rejects
      # source overrides without it.
      rev = pin.commit;
    };
  mesaPin = pins.mesa-aurora;
  mesaSrc = prev.fetchurl {
    name = "mesa-aurora-${mesaPin.commit}.tar.gz";
    url = mesaPin.source_url;
    hash = mesaPin.nix_hash;
  };
  stableFile = path: prev.writeText (builtins.baseNameOf path) (builtins.readFile path);
  source =
    name:
    prev.fetchurl {
      name = "${name}-${pins.${name}.commit}.tar.gz";
      url = pins.${name}.source_url;
      hash = pins.${name}.nix_hash;
    };
  kernelDtbAbi = prev.lib.toInt (prev.lib.fileContents "${aurora}/kernel/dtb-abi");
in
{
  aurora-bindgen = prev.callPackage "${aurora}/bindgen" {
    llvmPackages = prev.llvmPackages_22;
  };

  # The kernel names the AGX DRM driver "aurora"; stock Mesa only accepts
  # "asahi" in agx_open_device(), so EGL falls back to zink/llvmpipe and
  # Hyprland aborts in initEGL. Aurora's Mesa accepts both names and installs
  # the aurora_dri.so alias through Mesa's dril target.
  mesa = prev.callPackage "${aurora}/mesa.nix" {
    inherit (prev) mesa;
    src = mesaSrc;
    inherit (mesaPin) version commit;
  };

  # Touch ID / Secure Enclave userspace and the matching libfprint/fprintd.
  # The kernel exposes /dev/sep-bio; these helpers load apple_sep after /var
  # is available, rebuild per-machine calibration, restore the keybag and
  # teach fprintd the Aurora biometric interface.
  aurora-sep = prev.callPackage "${aurora}/sep/package.nix" { };

  libfprint = prev.libfprint.overrideAttrs (old: {
    src = source "libfprint";
    version = pins.libfprint.version;
    # The egis_etu905 umockdev replay is timing-sensitive and fails here
    # (stuck URB) even though the driver itself compiles. Keep the upstream
    # test suite buildable but do not gate the Touch ID package on it. The
    # tests run from installCheckPhase, not checkPhase.
    doCheck = false;
    doInstallCheck = false;
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
      prev.umockdev
      prev.python3
    ];
    nativeInstallCheckInputs = [
      prev.umockdev
      (prev.python3.withPackages (p: [
        p.pygobject3
        p.pycairo
      ]))
    ];
    patches =
      (old.patches or [ ])
      ++ map stableFile [
        "${aurora}/sep/libfprint-1.94.100-apple-sep.patch"
        "${aurora}/sep/0002-aurora-report-unusable-captures-as-retries.patch"
        "${aurora}/sep/0003-hide-lid-covered-readers-while-the-lid-is-closed.patch"
        "${aurora}/sep/0004-aurora-refuse-unbound-enrollment.patch"
        "${aurora}/sep/0005-aurora-support-v4-and-v5.patch"
        "${aurora}/sep/0006-aurora-report-finger-lift-and-lockout.patch"
        "${aurora}/sep/0007-aurora-name-retry-causes-and-keep-waiting.patch"
        "${aurora}/sep/0008-aurora-report-the-touch-id-lockout-as-locked-out.patch"
        "${aurora}/sep/0009-aurora-say-why-touch-id-needs-the-password.patch"
        "${aurora}/sep/0010-let-a-front-end-ask-whether-the-reader-needs-the-password.patch"
      ];
    postPatch = (old.postPatch or "") + ''
      install -Dm644 ${stableFile "${aurora}/sep/apple-sep.h"} aurora-uapi/linux/apple-sep.h
      ${prev.python3.interpreter} ${stableFile "${aurora}/sep/test_interface.py"} \
        libfprint/drivers/aurora/aurora.c aurora-uapi/linux/apple-sep.h
      ${prev.python3.interpreter} ${stableFile "${aurora}/sep/test_lockout_reason.py"} \
        libfprint/drivers/aurora/aurora.c
    '';
    preConfigure = (old.preConfigure or "") + ''
      export CFLAGS="''${CFLAGS:-} -I$PWD/aurora-uapi"
    '';
  });

  fprintd = prev.fprintd.overrideAttrs (old: {
    patches =
      (old.patches or [ ])
      ++ map stableFile [
        "${aurora}/sep/0001-preserve-print-on-device-delete-failure.patch"
        "${aurora}/sep/0002-report-lockout-and-fall-back-to-the-password.patch"
        "${aurora}/sep/0003-say-why-the-reader-needs-the-password.patch"
        "${aurora}/sep/0004-dont-ask-for-a-finger-the-reader-will-not-take.patch"
      ];
    postPatch = (old.postPatch or "") + ''
      ${prev.python3.interpreter} ${stableFile "${aurora}/sep/test_account_gate.py"} src/device.c
    '';
  });

  aurora-touchid-rearm = prev.stdenv.mkDerivation {
    pname = "aurora-touchid-rearm";
    version = pins.aurora-touchid-rearm.version;
    src = source "aurora-touchid-rearm";
    buildInputs = [ prev.pam ];
    nativeCheckInputs = [ prev.python3 ];
    makeFlags = [
      "-C"
      "touchid-rearm"
      "WARN=-Wall"
      "LIBEXECDIR=${placeholder "out"}/libexec"
      "PAMDIR=${placeholder "out"}/lib/security"
      "PAMCONFDIR=${placeholder "out"}/lib/pam.d"
      "UNITDIR=${placeholder "out"}/lib/systemd/system"
      "DOCDIR=${placeholder "out"}/share/doc/aurora-touchid-rearm"
      "SYSCONFDIR=${placeholder "out"}/etc"
    ];
    doCheck = true;
    checkTarget = "check";
    AURORA_TEST_PAM_DIR = "${prev.pam}/lib/security";
    passthru.commit = pins.aurora-touchid-rearm.commit;
    meta = {
      description = "Re-arm Touch ID with the password after a lockout";
      homepage = "https://github.com/aurora-silicon/aurora-sep-userspace";
      license = prev.lib.licenses.gpl2Only;
      platforms = prev.lib.platforms.linux;
    };
  };

  aurora-sep-sk = prev.stdenv.mkDerivation {
    pname = "aurora-sep-sk";
    version = pins.aurora-sep-sk.version;
    src = source "aurora-sep-sk";
    sourceRoot = "${pins.aurora-sep-sk.archive_root}/sk";
    nativeBuildInputs = [ prev.pkg-config ];
    buildInputs = [ prev.openssl ];
    nativeCheckInputs = [
      (prev.runCommand "openssh-client-tools" { } ''
        mkdir -p $out/bin
        for t in ssh ssh-keygen ssh-agent ssh-add; do
          ln -s ${prev.openssh}/bin/$t $out/bin/$t
        done
      '')
      prev.gitMinimal
    ];
    makeFlags = [
      "PREFIX=${placeholder "out"}"
      "LIBDIR=${placeholder "out"}/lib"
      "UDEVRULESDIR=${placeholder "out"}/lib/udev/rules.d"
      "SYSUSERSDIR=${placeholder "out"}/lib/sysusers.d"
    ];
    doCheck = true;
    checkTarget = "check";
    postInstall = ''
      install -Dm644 ../docs/ssh-sk.md $out/share/doc/aurora-sep-sk/ssh-sk.md
    '';
    passthru.commit = pins.aurora-sep-sk.commit;
    meta = {
      description = "OpenSSH security-key provider for Secure Enclave keys";
      homepage = "https://github.com/aurora-silicon/aurora-sep-userspace";
      license = prev.lib.licenses.mit;
      platforms = [ "aarch64-linux" ];
    };
  };

  aurora-xart = prev.stdenvNoCC.mkDerivation {
    pname = "aurora-xart";
    version = pins.aurora-xart.version;
    src = source "aurora-xart";
    nativeBuildInputs = [ prev.python3 ];
    dontBuild = true;
    doCheck = true;
    checkPhase = ''
      runHook preCheck
      make check PYTHON=${prev.python3.interpreter}
      runHook postCheck
    '';
    installPhase = ''
      runHook preInstall
      make install DESTDIR=$out PREFIX=
      substituteInPlace $out/bin/aurora-xart \
        --replace-fail "#!/usr/bin/python3 -I" "#!${prev.python3.interpreter} -I"
      runHook postInstall
    '';
    passthru.commit = pins.aurora-xart.commit;
    meta = {
      description = "Inspect and manage the Linux side of the Secure Enclave and xART state";
      homepage = "https://github.com/aurora-silicon/aurora-xart";
      license = prev.lib.licenses.mit;
      mainProgram = "aurora-xart";
      platforms = [ "aarch64-linux" ];
    };
  };

  linux-asahi = prev.lib.makeOverridable (
    {
      # apple-silicon-support passes config.boot.kernelPatches here, but
      # NixOS' boot.kernelPackages wrapper appends the same option to the
      # kernel derivation again. Ignore this copy and let the wrapper add
      # every patch exactly once.
      _kernelPatches ? [ ],
    }:
    prev.lib.recurseIntoAttrs (
      prev.linuxPackagesFor (
        # import, not callPackage: callPackage would overwrite the inner
        # makeOverridable buildKernel's .override with one for this file,
        # and NixOS' kernel module overrides features/randstructSeed.
        import "${aurora}/pkgs/kernel.nix" {
          inherit (prev)
            lib
            callPackage
            path
            writeText
            openssl
            kmod
            binutils
            ;
          aurora-bindgen = final.aurora-bindgen;
          inherit src pin kernelDtbAbi;
          # Aurora builds the kernel and its Rust bindings with a pinned
          # LLVM; the host tools keep the native wrapped compiler.
          llvmPackages = prev.llvmPackages_22;
          # The pinned configuration resolves CONFIG_ARM64_CTXR_EXECMEM=y,
          # which the kernel package verifies during configure.
          kernelCtxrExecmem = true;
          kernelPatches = [ ];
        }
      )
    )
  ) { };
}

{
  pkgs,
  inputs,
  lib,
  appimageTools,
  fetchurl,
}:

let
  pname = "smath";
  version = "1.5.0.9678";

  src = fetchurl {
    url = "https://smath.com/en-US/files/Download/64XCg/SMathStudioDesktop.${
      lib.replaceStrings [ "." ] [ "_" ] version
    }.x86_64.ubuntu-24_04.glibc2.39.AppImage";
    hash = "sha256-LTpIV9rcEtqCFRVCEeQ9Mit3QomFqIv0yodvtEm3AhM=";
  };

  # Ekstrakcja squashfs jest niezależna od architektury, więc robimy ją
  # natywnie niezależnie od tego, czy budujemy dla x86_64, czy dla aarch64.
  appimageContents = appimageTools.extract { inherit pname version src; };

  meta = {
    description = "Tiny, powerful, free mathematical program with WYSIWYG editor and complete units of measurements support";
    homepage = "https://smath.com";
    license = lib.licenses.unfree;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    mainProgram = "smath";
  };

  installShare = ''
    install -m 444 -D ${appimageContents}/com.smath.smathstudio.desktop \
      $out/share/applications/com.smath.smathstudio.desktop
    substituteInPlace $out/share/applications/com.smath.smathstudio.desktop \
      --replace-fail 'Exec=smath_launcher' 'Exec=smath'
    cp -r ${appimageContents}/usr/share/icons $out/share
    install -m 444 -D ${appimageContents}/usr/share/mime/packages/smathstudio.xml \
      $out/share/mime/packages/smathstudio.xml
  '';
in
if pkgs.stdenv.hostPlatform.isx86_64 then

  # Natywnie: opakowany AppImage (FHS z bibliotekami x86_64).
  appimageTools.wrapType2 {
    inherit pname version src;
    extraInstallCommands = installShare;
    meta = meta // {
      platforms = [ "x86_64-linux" ];
    };
  }

else

  let
    # x86_64 nixpkgs niezależnie od architektury hościa (wzorzec z t3code).
    pkgsX64 = inputs.nixpkgs.legacyPackages.x86_64-linux;

    # Biblioteki, których AppImage NIE wozi, a których mono/libgdiplus/
    # WinForms potrzebują za naszym LD_LIBRARY_PATH. Suma NEEDED z
    # libgdiplus + to, co WinForms dlopenuje + zależności mono.
    x64Libs =
      with pkgsX64;
      [
        glibc
        zlib
        krb5
        stdenv.cc.cc.lib
        expat
        fontconfig
        freetype
        cairo
        pango
        harfbuzz
        glib
        libpng
        libtiff
        giflib
        libjpeg_turbo
        libexif
        libuuid
        pixman
        libxml2
        cups
      ]
      ++ (with pkgsX64; [
        libX11
        libXext
        libXrender
        libXi
        libXrandr
        libXcursor
        libXfixes
        libXinerama
        libXcomposite
        libXdamage
        libSM
        libICE
        libXau
        libXdmcp
        libxcb
      ]);

    x64LibPath = lib.makeLibraryPath x64Libs;

    # glibc x86_64 w układzie, którego oczekuje qemu-user: loader pod
    # lib64/ld-linux-x86-64.so.2 (stąd QEMU_LD_PREFIX).
    sysroot = pkgs.runCommand "smath-x86_64-sysroot" { } ''
      mkdir -p $out/lib64 $out/lib
      ln -s ${pkgsX64.glibc}/lib/* $out/lib64/
      ln -s ${pkgsX64.glibc}/lib/* $out/lib/
    '';
  in
  pkgs.stdenvNoCC.mkDerivation {
    inherit pname version src;

    dontUnpack = true;
    # Obcoarchitekturowe bloby (mono, libgdiplus) zostają bajt w bajt --
    # żadnego patchelf/strip, które i tak nie ruszy architektury.
    dontFixup = true;

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin $out/share
      cp -r ${appimageContents} $out/share/smath
      chmod -R u+w $out/share/smath

      substitute ${./qemu-wrapper.sh} $out/bin/smath \
        --replace-fail @SYSROOT@ "${sysroot}" \
        --replace-fail @X64LIBS@ "${x64LibPath}" \
        --replace-fail @SMATHDIR@ "$out/share/smath"
      chmod 755 $out/bin/smath

      ${installShare}

      runHook postInstall
    '';

    meta = meta // {
      platforms = [ "aarch64-linux" ];
    };
  }

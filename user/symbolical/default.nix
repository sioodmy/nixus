{
  pkgs,
  lib,
  ...
}:
# Symbolical (https://gitlab.com/symbolical/symbolical) — "math documents with
# style" (PyQt6). Nie ma w nixpkgs, pakujemy sami prosto z repo, przez meson
# tak jak pisze README ("install from source").
#
# Uwaga na wheel'e codac: runtime Pythona z nixpkgs (3.14) jest utopiony w
# URL-ach i hashach poniżej — przy podbiciu CPythona w flake.lock trzeba
# odświeżyć te ścieżki (hash =  nix store prefetch-file --json <url>).
let
  pname = "symbolical";
  version = "0.9.0.1";

  py = pkgs.python3Packages;
  cpTag = "cp" + lib.replaceStrings [ "." ] [ "" ] (lib.versions.majorMinor py.python.version); # 3.14 -> cp314

  # codac nie ma w nixpkgs — sięgamy po prebuilt manylinux wheel z PyPI.
  # Wheel linkuje biblioteki systemowe (m.in. libstdc++), które autoPatchelfHook
  # przepina w fixupie na te z nixpkgs, więc działa i na aarch64, i na x86_64.
  codacWheelUrls = {
    aarch64-linux = "https://files.pythonhosted.org/packages/cc/1a/ac682e88f0eafbceb043bbb236beab2df4ed0299cf95c7ba9f46158674d8/codac-2.1.2-${cpTag}-${cpTag}-manylinux_2_26_aarch64.manylinux_2_28_aarch64.whl";
    x86_64-linux = "https://files.pythonhosted.org/packages/c4/7c/533c33540e6b989de97d8a47bd93e9931310cfac1e20b56a317e3dadd216/codac-2.1.2-${cpTag}-${cpTag}-manylinux_2_27_x86_64.manylinux_2_28_x86_64.whl";
  };
  codacWheelHashes = {
    aarch64-linux = "sha256-HSG/RScp/RwWpN9FjziAbPM6NVT61kz36O4Ra5Nl+ms=";
    x86_64-linux = "sha256-0xzoB8J16yGS2y4dBK+c0KdH+hrsYtGcgYVu43g0KRo=";
  };

  vibes = py.buildPythonPackage rec {
    pname = "vibes";
    version = "0.2.2";
    format = "setuptools";
    src = py.fetchPypi {
      inherit pname version;
      hash = "sha256-T9qBoUSb9Rjh0j5c8HjXsT5KJBqVS9A6ZwlUP81YtR4=";
    };
    doCheck = false;
    pythonImportsCheck = [ "vibes" ];
  };

  codac = py.buildPythonPackage rec {
    pname = "codac";
    version = "2.1.2";
    format = "wheel";
    src = pkgs.fetchurl {
      url = codacWheelUrls.${pkgs.stdenv.system};
      hash = codacWheelHashes.${pkgs.stdenv.system};
    };
    buildInputs = [
      pkgs.stdenv.cc.cc.lib
      pkgs.gomp
    ];
    nativeBuildInputs = [ pkgs.autoPatchelfHook ];
    # Wheel wymienia w metadanych także `pip` — bez tego
    # pythonRuntimeDepsCheckHook odrzuci instalację; pip i tak siedzi w env.
    dependencies = [
      py.pip
      vibes
    ];
    pythonImportsCheck = [ "codac" ];
    meta = {
      description = "Constraint programming over reals (interval arithmetic), prebuilt manylinux wheel";
      license = lib.licenses.lgpl3Only;
    };
  };

  pythonEnv = py.python.withPackages (
    ps: with ps; [
      pyqt6
      python-dateutil
      openpyxl
      fonttools
      numpy
      scipy
      sympy
      pint
      codac
    ]
  );
in
pkgs.stdenv.mkDerivation {
  inherit pname version;

  src = pkgs.fetchFromGitLab {
    domain = "gitlab.com";
    owner = "symbolical";
    repo = "symbolical";
    rev = "v${version}";
    hash = "sha256-G4Lit7L6jzwv9mS4cvZ6gcgbTqoYUv8AkCsWgTEdigc=";
  };

  nativeBuildInputs = [
    pkgs.meson
    pkgs.ninja
  ];

  passthru = {
    inherit (pythonEnv) python;
  };

  postInstall = ''
    # Meson instaluje index.theme dla ikony hicolor; w NixOS profil dopuszcza
    # tylko jedną wersję tego pliku (kolizja z hicolor-icon-theme), więc
    # wyrzucamy go — ikony same i tak się wyrenderują.
    rm -f $out/share/icons/hicolor/index.theme

    # Launcher (configure_file z flatpak/symbolical.in): exec python3 APP/main.py
    substituteInPlace $out/bin/symbolical \
      --replace-fail 'python3' "${pythonEnv}/bin/python"
  '';

  doCheck = false;

  meta = {
    description = "Mathematical worksheet application with 2D notation";
    homepage = "https://symbolical.pracedru.dk";
    license = lib.licenses.gpl3Plus;
    mainProgram = "symbolical";
  };
}

{
  lib,
  stdenvNoCC,
  python3,
  kdePackages,
  adwaita-icon-theme,
  hicolor-icon-theme,
}:
stdenvNoCC.mkDerivation {
  pname = "amethyst-aero-icons";
  version = "1.0.0";
  src = ./.;
  nativeBuildInputs = [ python3 ];
  dontBuild = true;
  installPhase = ''
    runHook preInstall
    python3 build.py --output "$out/share/icons/Amethyst-Aero" \
      --oxygen ${kdePackages.oxygen-icons}/share/icons/oxygen \
      --palette ${../quickshell/ui/palette.json}
    mkdir -p "$out/share/amethyst-aero-icons"
    cp manifest.json "$out/share/amethyst-aero-icons/manifest.json"
    runHook postInstall
  '';
  propagatedBuildInputs = [
    kdePackages.oxygen-icons
    adwaita-icon-theme
    hicolor-icon-theme
  ];
  meta = {
    description = "Amethyst Aero glass icons for the desktop and installed applications";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}

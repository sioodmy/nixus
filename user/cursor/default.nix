{ pkgs }:
pkgs.runCommand "amethyst-aero-cursors"
  {
    nativeBuildInputs = [
      pkgs.python3
      pkgs.librsvg
      pkgs.xcursorgen
    ];
    meta = {
      description = "Pearlescent lilac Aero cursors with an animated glass busy ring";
      platforms = pkgs.lib.platforms.linux;
      license = [
        pkgs.lib.licenses.mit
        pkgs.lib.licenses.gpl3Plus
      ];
    };
  }
  ''
    cursor_dir="$out/share/icons/Amethyst-Aero-Cursors"
    mkdir -p "$cursor_dir/cursors" "$out/share/licenses/amethyst-aero-cursors"
    cp -as ${pkgs.bibata-cursors}/share/icons/Bibata-Modern-Ice/cursors/. "$cursor_dir/cursors/"
    chmod u+w "$cursor_dir/cursors"
    python3 ${./build.py} "$cursor_dir" ${../quickshell/ui/palette.json}
    cp ${./LICENSE} "$out/share/licenses/amethyst-aero-cursors/LICENSE"
    cp ${./Bibata-LICENSE} "$out/share/licenses/amethyst-aero-cursors/Bibata-LICENSE"
    cat > "$cursor_dir/index.theme" <<'EOF'
    [Icon Theme]
    Name=Amethyst Aero
    Comment=Pearlescent lilac glass pointers and animated Aero busy rings
    Inherits=Bibata-Modern-Ice
    EOF
  ''

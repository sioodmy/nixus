{
  pkgs,
  ...
}:
let
  lib = pkgs.lib;
  config = pkgs.writeTextDir "zathurarc" (import ./config.nix { inherit lib; });
in
pkgs.symlinkJoin {
  name = "zathura-wrapped";
  paths = [ pkgs.zathura ];
  nativeBuildInputs = [ pkgs.makeWrapper ];
  postBuild = ''
    wrapProgram $out/bin/zathura --add-flags "--config-dir=${config}"
  '';
}

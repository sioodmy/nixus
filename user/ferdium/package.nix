{ pkgs }:
let
  theme = import ./theme.nix { inherit pkgs; };
in
pkgs.symlinkJoin {
  name = "ferdium-amethyst-aero-${pkgs.ferdium.version}";
  paths = [ pkgs.ferdium ];
  nativeBuildInputs = [ pkgs.makeWrapper ];
  postBuild = ''
    wrapProgram "$out/bin/ferdium" --run ${theme.setup}
    mkdir -p "$out/share/amethyst-aero"
    ln -s ${theme.setup} "$out/share/amethyst-aero/setup"
    ln -s ${theme.appCss} "$out/share/amethyst-aero/app.css"
    ln -s ${theme.discordDarkmodeCss} "$out/share/amethyst-aero/discord.css"
    ln -s ${theme.messengerCss} "$out/share/amethyst-aero/messenger.css"
    ln -s ${theme.whatsappCss} "$out/share/amethyst-aero/whatsapp.css"
  '';
  meta = pkgs.ferdium.meta // {
    mainProgram = "ferdium";
  };
}

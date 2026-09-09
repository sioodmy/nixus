{ pkgs, ... }:
let
  inherit (builtins) attrValues;
in
{
  environment.sessionVariables.FREETYPE_PROPERTIES = "cff:no-stem-darkening=0 autofitter:no-stem-darkening=0";
  fonts = {
    packages =
      attrValues {
        inherit (pkgs)
          material-icons
          material-design-icons
          material-symbols
          roboto
          roboto-mono
          roboto-slab
          vista-fonts
          corefonts
          roboto-serif
          work-sans
          comic-neue
          source-sans
          twemoji-color-font
          comfortaa
          inter
          lato
          lexend
          jost
          dejavu_fonts
          noto-fonts
          noto-fonts-cjk-sans
          noto-fonts-color-emoji
          ;
      }
      ++ [
        pkgs.nerd-fonts.jetbrains-mono
        pkgs.nerd-fonts.iosevka
        pkgs.lexend
        pkgs.maple-mono.NF
      ];

    enableDefaultPackages = false;

    # this fixes emoji stuff
    fontconfig = {
      defaultFonts = {
        monospace = [
          "Iosevka Nerd Font"
          "Noto Color Emoji"
        ];
        sansSerif = [
          # "Lexend Nerd Font"
          "Lexend"
          "Noto Color Emoji"
        ];
        serif = [
          "Noto Serif"
          "Noto Color Emoji"
        ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };
}

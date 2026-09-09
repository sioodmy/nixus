rec {
  packages =
    { pkgs, inputs }:
    let
      inherit (pkgs) callPackage;
    in
    {
      zsh = callPackage ./wrapped/zsh { };
      tmux = callPackage ./wrapped/tmux { };
      kitty = callPackage ./wrapped/kitty { inherit inputs;};
      tofi = callPackage ./wrapped/tofi { };
      bat = pkgs.bat;
      zathura = callPackage ./wrapped/zathura { };
    };

  shell =
    { pkgs, inputs }:
    let
      userPackages = packages { inherit pkgs inputs; };
    in
    pkgs.mkShell {
      name = "sioodmy-devshell";
      shellHook = ''
        zsh
      '';
      buildInputs = [
        userPackages.zsh
      ];
    };
  module =
    { pkgs, inputs, ... }:
    {
      config = {
        environment.systemPackages = builtins.attrValues (packages {
          inherit pkgs inputs;
        });
        programs.direnv = {
          enable = true;
          enableFishIntegration = false;
        };
      };
      imports = [
        ./packages.nix
        ./git
        ./gtk
      ];
    };
}

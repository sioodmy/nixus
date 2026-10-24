rec {
  packages =
    { pkgs, inputs }:
    let
      inherit (pkgs) callPackage;
    in
    {
      zsh = callPackage ./wrapped/zsh { };
      tmux = callPackage ./wrapped/tmux { };
      kitty = callPackage ./wrapped/kitty { inherit inputs; };
      aeroshell = import ./quickshell/package.nix { inherit pkgs inputs; };
      zen-aero = import ./zen-browser/package.nix { inherit pkgs inputs; };
      ferdium = import ./ferdium/package.nix { inherit pkgs; };
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
        # Installs the compositor and links ~/.config/hypr. The greetd session
        # itself is configured in system/wayland.
        hyprland.enable = true;
        # The shell runs as a systemd user unit, started from Hyprland's
        # autostart block once the compositor is up.
        quickshell.enable = true;
      };
      imports = [
        ./packages.nix
        ./t3code
        ./git
        ./gtk
        ./hyprland
        ./ferdium
        ./quickshell
        ./zen-browser
      ];
    };
}

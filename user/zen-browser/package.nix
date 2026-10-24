{ pkgs, inputs }:
let
  inherit (pkgs) lib;
  palette = builtins.fromJSON (builtins.readFile ../quickshell/ui/palette.json);
  colors = lib.filterAttrs (name: _: name != "name") palette;
  render =
    file:
    lib.replaceStrings (map (name: "@${lib.toUpper name}@") (
      builtins.attrNames colors
    )) (builtins.attrValues colors) (builtins.readFile file);
  chrome = pkgs.writeText "amethyst-userChrome.css" (render ./userChrome.css);
  content = pkgs.writeText "amethyst-userContent.css" (
    lib.replaceStrings [ "@WALLPAPER@" ] [ "${../quickshell/ui/assets/wallpaper.png}" ] (
      render ./userContent.css
    )
  );
  settings = import ./settings.nix { inherit palette; };
  prefs = pkgs.writeText "amethyst-user.js" (
    lib.concatStringsSep "\n" (
      lib.mapAttrsToList (
        name: value: "user_pref(${builtins.toJSON name}, ${builtins.toJSON value});"
      ) settings
    )
  );
  ublock = pkgs.fetchurl {
    url = "https://addons.mozilla.org/firefox/downloads/file/5034826/ublock_origin-1.75.0.xpi";
    sha256 = "5b74415860456370644bd80f16125e865b0e6c356bb5dfcfb84069967eaa5287";
  };
  unwrapped = inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.beta-unwrapped.override {
    policies = {
      OverrideFirstRunPage = "";
      OverridePostUpdatePage = "";
      ExtensionSettings."uBlock0@raymondhill.net" = {
        installation_mode = "normal_installed";
        install_url = "file://${ublock}";
        default_area = "navbar";
      };
    };
  };
  # Match upstream's wrap-zen.nix: select media libraries by Gecko version.
  browser = pkgs.wrapFirefox (unwrapped // { version = unwrapped.firefoxVersion or "9999"; }) {
    version = unwrapped.version;
    icon = "zen-browser";
  };
  launcher = pkgs.writeShellApplication {
    name = "zen";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.util-linux
    ];
    text = ''
      profile="''${XDG_CONFIG_HOME:-$HOME/.config}/zen/amethyst-aero"
      mkdir -p "$profile/chrome"
      # Serialize preparation when several links are opened simultaneously.
      exec 9>"$profile/.aero-setup.lock"
      flock 9
      ln -sfn ${chrome} "$profile/chrome/userChrome.css"
      ln -sfn ${content} "$profile/chrome/userContent.css"
      ln -sfn ${prefs} "$profile/user.js"
      flock -u 9
      exec 9>&-
      export MOZ_ENABLE_WAYLAND=1
      exec ${browser}/bin/zen-beta --class zen-aero --name zen-aero -profile "$profile" "$@"
    '';
  };
  desktop = pkgs.makeDesktopItem {
    name = "zen-aero";
    desktopName = "Zen Browser";
    genericName = "Web Browser";
    comment = "Amethyst Aero — fioletowe szkło, pionowe karty";
    exec = "zen %U";
    icon = "zen-browser";
    startupWMClass = "zen-aero";
    categories = [
      "Network"
      "WebBrowser"
    ];
    mimeTypes = [
      "text/html"
      "application/xhtml+xml"
      "x-scheme-handler/http"
      "x-scheme-handler/https"
    ];
    actions.private = {
      name = "Nowe okno prywatne";
      exec = "zen --private-window %U";
    };
  };
in
pkgs.symlinkJoin {
  name = "zen-amethyst-aero-${browser.version}";
  paths = [
    launcher
    desktop
  ];
  postBuild = ''
    ln -s zen "$out/bin/zen-browser"
    if [ -d ${browser}/share/icons ]; then
      ln -s ${browser}/share/icons "$out/share/icons"
    fi
    mkdir -p "$out/share/amethyst-aero"
    ln -s ${chrome} "$out/share/amethyst-aero/userChrome.css"
    ln -s ${content} "$out/share/amethyst-aero/userContent.css"
    ln -s ${prefs} "$out/share/amethyst-aero/user.js"
  '';
  meta = browser.meta // {
    mainProgram = "zen";
  };
}

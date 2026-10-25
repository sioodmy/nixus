{ pkgs }:
let
  qt = pkgs.libsForQt5;
  setup = pkgs.writeShellScript "keepassxc-aero-setup" ''
    # Change only the appearance key; leave databases and security settings alone.
    config_dir="''${XDG_CONFIG_HOME:-$HOME/.config}/keepassxc"
    ${pkgs.coreutils}/bin/mkdir -p "$config_dir"
    ${pkgs.crudini}/bin/crudini --set "$config_dir/keepassxc.ini" GUI ApplicationTheme classic
  '';
in
pkgs.symlinkJoin {
  name = "keepassxc-amethyst-aero-${pkgs.keepassxc.version}";
  paths = [ pkgs.keepassxc ];
  nativeBuildInputs = [ pkgs.makeWrapper ];
  postBuild = ''
    wrapProgram "$out/bin/keepassxc" \
      --run ${setup} \
      --set QT_QPA_PLATFORMTHEME qt5ct \
      --set QT_STYLE_OVERRIDE kvantum \
      --prefix QT_PLUGIN_PATH : "${qt.qt5ct}/${qt.qtbase.qtPluginPrefix}:${qt.qtstyleplugin-kvantum}/${qt.qtbase.qtPluginPrefix}"
  '';
  meta = pkgs.keepassxc.meta // {
    mainProgram = "keepassxc";
  };
}

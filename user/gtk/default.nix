{ pkgs, lib, ... }:
let
  palette = builtins.fromJSON (builtins.readFile ../quickshell/ui/palette.json);
  colors = lib.filterAttrs (name: _: name != "name") palette;
  css = lib.replaceStrings (map (name: "@${lib.toUpper name}@") (
    builtins.attrNames colors
  )) (builtins.attrValues colors) (builtins.readFile ./gtk.css);
  themeName = "Amethyst-Aero";
  iconTheme = "Amethyst-Aero";
  cursorTheme = "Amethyst-Aero-Cursors";
  iconPackage = pkgs.callPackage ../icons { };
  cursorPackage = pkgs.callPackage ../cursor { };
  colorScheme = pkgs.writeText "Amethyst-Aero.conf" (
    let
      roles = with palette; [
        text
        raised
        highlight
        edge
        background
        edge
        text
        text
        text
        background
        surface
        background
        accent
        background
        blue
        accent
        raised
        background
        surface
        text
        muted
        accent
      ];
      line = lib.concatMapStringsSep ", " (color: "#ff${lib.removePrefix "#" color}") roles;
    in
    ''
      [ColorScheme]
      active_colors=${line}
      inactive_colors=${line}
      disabled_colors=${line}
    ''
  );
  theme = pkgs.runCommand "amethyst-aero-theme" { nativeBuildInputs = [ pkgs.python3 ]; } ''
    gtk="$out/share/themes/${themeName}"
    mkdir -p "$gtk/gtk-3.0" "$gtk/gtk-4.0" "$out/share/Kvantum/${themeName}"
    printf '%s\n' '@import url("resource:///org/gtk/libgtk/theme/Adwaita/gtk-contained-dark.css");' > "$gtk/gtk-3.0/gtk.css"
    cat ${pkgs.writeText "amethyst-gtk.css" css} >> "$gtk/gtk-3.0/gtk.css"
    cp "$gtk/gtk-3.0/gtk.css" "$gtk/gtk-3.0/gtk-dark.css"
    cp ${pkgs.writeText "amethyst-gtk4.css" css} "$gtk/gtk-4.0/gtk.css"
    cp "$gtk/gtk-4.0/gtk.css" "$gtk/gtk-4.0/gtk-dark.css"
    python3 ${./kvantum.py} \
      ${pkgs.kdePackages.qtstyleplugin-kvantum}/share/Kvantum/KvDark \
      "$out/share/Kvantum/${themeName}" ${../quickshell/ui/palette.json}
  '';
  gtkSettings = lib.generators.toINI { } {
    Settings = {
      gtk-theme-name = themeName;
      gtk-application-prefer-dark-theme = 1;
      gtk-font-name = "Segoe UI 10";
      gtk-icon-theme-name = iconTheme;
      gtk-cursor-theme-name = cursorTheme;
      gtk-cursor-theme-size = 24;
      gtk-xft-antialias = 1;
      gtk-xft-hinting = 1;
      gtk-xft-hintstyle = "hintslight";
      gtk-xft-rgba = "rgb";
      gtk-decoration-layout = "menu:minimize,maximize,close";
    };
  };
  qtSettings = ''
    [Appearance]
    style=kvantum
    custom_palette=true
    color_scheme_path=${colorScheme}
    icon_theme=${iconTheme}
    standard_dialogs=default
    [Fonts]
    general="Segoe UI,10,-1,5,50,0,0,0,0,0"
    fixed="JetBrains Mono,10,-1,5,50,0,0,0,0,0"
    [Interface]
    activate_item_on_single_click=0
    buttonbox_layout=0
    dialog_buttons_have_icons=1
    menus_have_icons=true
    toolbutton_style=4
    underline_shortcut=1
  '';
in
{
  imports = [ ./apps.nix ];
  system.userActivationScripts.amethystAeroCursor.text = ''
    mkdir -p "$HOME/.local/share/icons"
    ln -sfnT ${cursorPackage}/share/icons/${cursorTheme} "$HOME/.local/share/icons/${cursorTheme}"
  '';
  homix = {
    ".config/gtk-3.0/settings.ini".text = gtkSettings;
    ".config/gtk-4.0/settings.ini".text = gtkSettings;
    ".config/gtk-3.0/gtk.css".text = css;
    ".config/gtk-4.0/gtk.css".text = css;
    ".config/Kvantum/kvantum.kvconfig".text = "[General]\ntheme=${themeName}\n";
    ".config/Kvantum/${themeName}/${themeName}.kvconfig".source =
      "${theme}/share/Kvantum/${themeName}/${themeName}.kvconfig";
    ".config/Kvantum/${themeName}/${themeName}.svg".source =
      "${theme}/share/Kvantum/${themeName}/${themeName}.svg";
    ".config/qt5ct/qt5ct.conf".text = qtSettings;
    ".config/qt6ct/qt6ct.conf".text = qtSettings;
    ".config/qtquickcontrols2.conf".text = ''
      [Controls]
      Style=Fusion
    '';
    ".config/kdeglobals".text = ''
      [General]
      ColorScheme=Amethyst-Aero
      font=Segoe UI,10,-1,5,50,0,0,0,0,0
      fixed=JetBrains Mono,10,-1,5,50,0,0,0,0,0
      [Icons]
      Theme=${iconTheme}
      [KDE]
      widgetStyle=kvantum
      SingleClick=false
    '';
    ".icons/default/index.theme".text = "[Icon Theme]\nInherits=${cursorTheme}\n";
    ".gtkrc-2.0".text = ''
      gtk-theme-name="Adwaita-dark"
      gtk-font-name="Segoe UI 10"
      gtk-icon-theme-name="${iconTheme}"
      gtk-cursor-theme-name="${cursorTheme}"
      style "amethyst" {
        bg[NORMAL]="${palette.surface}"
        fg[NORMAL]="${palette.text}"
        base[NORMAL]="${palette.background}"
        text[NORMAL]="${palette.text}"
        bg[SELECTED]="${palette.accent}"
        fg[SELECTED]="${palette.background}"
      }
      class "*" style "amethyst"
    '';
  };
  environment = {
    systemPackages = [
      theme
      iconPackage
      pkgs.kdePackages.oxygen-icons
      pkgs.adwaita-icon-theme
      pkgs.gnome-themes-extra
      pkgs.libsForQt5.qt5ct
      pkgs.kdePackages.qt6ct
      pkgs.libsForQt5.qtstyleplugin-kvantum
      pkgs.kdePackages.qtstyleplugin-kvantum
      cursorPackage
    ];
    variables = {
      GSK_RENDERER = "gl";
      QT_AUTO_SCREEN_SCALE_FACTOR = "1";
      QT_QPA_PLATFORMTHEME = "qt6ct:qt5ct";
      QT_STYLE_OVERRIDE = "kvantum";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
      QT_QUICK_CONTROLS_CONF = "$HOME/.config/qtquickcontrols2.conf";
      GTK_THEME = themeName;
      XCURSOR_THEME = cursorTheme;
      XCURSOR_SIZE = "24";
    };
  };
  programs.dconf.profiles.user.databases = [
    {
      settings."org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
        gtk-theme = themeName;
        icon-theme = iconTheme;
        cursor-theme = cursorTheme;
        cursor-size = lib.gvariant.mkInt32 24;
        font-name = "Segoe UI 10";
        monospace-font-name = "JetBrains Mono 10";
      };
    }
  ];
}

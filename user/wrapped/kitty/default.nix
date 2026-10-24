{
  pkgs,
  inputs,
  ...
}:
let
  palette = builtins.fromJSON (builtins.readFile ../../quickshell/ui/palette.json);
  inherit (pkgs.lib.meta) getExe getExe';

  xdg-open = getExe' pkgs.xdg-utils "xdg-open";

  config = pkgs.writeText "kitty.conf" ''
    # Fonts
    font_family      JetBrains Mono
    bold_font        auto
    italic_font      auto
    bold_italic_font auto
    font_size        10
    modify_font      cell_height 140%

    # Window layout
    remember_window_size  no
    initial_window_width  104c
    initial_window_height 36c
    window_padding_width  12
    hide_window_decorations yes
    confirm_os_window_close 0
    enabled_layouts       splits,stack,fat,tall,grid

    # Text & Selection
    bold_is_bright no
    select_by_word_characters ,│`|:"'()[]{}<>

    # Bell
    enable_audio_bell no
    visual_bell_duration 0.0
    window_alert_on_bell no
    command_on_bell none
    bell_on_tab "no"

    wheel_scroll_multiplier 10.0
    touch_scroll_multiplier 10.0

    open_url_with ${xdg-open}
    detect_urls yes
    underline_hyperlinks always

    shell_integration no-cursor
    cursor_shape underline
    cursor_blink_interval 0.5
    cursor_trail 1
    cursor_trail_start_threshold 15

    mouse_hide_wait -1.0

    tab_bar_edge top
    tab_bar_style powerline
    tab_powerline_style round
    tab_bar_align left
    tab_bar_min_tabs 1
    tab_activity_symbol "󰅐 "
    tab_title_template " {index}: {title} ({num_windows}) "
    active_tab_title_template " {index}: {title} ({num_windows}) "

    active_tab_foreground   ${palette.background}
    active_tab_background   ${palette.accent}
    active_tab_font_style   bold
    inactive_tab_foreground ${palette.text}
    inactive_tab_background ${palette.raised}
    inactive_tab_font_style normal
    tab_bar_background      ${palette.surface}
    tab_bar_margin_color    ${palette.surface}

    draw_minimal_borders yes
    window_border_width 1.5pt
    active_border_color ${palette.accent}
    inactive_border_color ${palette.edge}
    bell_border_color ${palette.yellow}
    inactive_text_alpha 0.85

    map ctrl+k scroll_half_page_up
    map ctrl+shift+k scroll_page_up
    map ctrl+j scroll_half_page_down
    map ctrl+shift+j scroll_page_down
    map ctrl+shift+c copy_to_clipboard
    map ctrl+shift+v paste_from_clipboard
    map shift+insert paste_from_selection
    map ctrl+equal change_font_size all +2.0
    map ctrl+plus change_font_size all +2.0
    map ctrl+minus change_font_size all -2.0
    # --- Vim-like Split (Window) Keybindings (Ctrl+Alt modifier to avoid Vim conflicts) ---
    # Create splits
    map ctrl+alt+s launch --location=hsplit --cwd=current
    map ctrl+alt+v launch --location=vsplit --cwd=current
    map ctrl+shift+minus launch --location=hsplit --cwd=current
    map ctrl+shift+backslash launch --location=vsplit --cwd=current

    # Focus split window (Vim hjkl navigation)
    map ctrl+alt+h neighboring_window left
    map ctrl+alt+j neighboring_window down
    map ctrl+alt+k neighboring_window up
    map ctrl+alt+l neighboring_window right
    map ctrl+alt+w neighboring_window next

    # Move split window
    map ctrl+alt+shift+h move_window left
    map ctrl+alt+shift+j move_window down
    map ctrl+alt+shift+k move_window up
    map ctrl+alt+shift+l move_window right

    # Resize split window
    map ctrl+alt+left resize_window narrower 3
    map ctrl+alt+right resize_window wider 3
    map ctrl+alt+up resize_window taller 3
    map ctrl+alt+down resize_window shorter 3
    map ctrl+alt+equal resize_window reset

    # Close & Zoom split window
    map ctrl+alt+q close_window
    map ctrl+alt+c close_window
    map ctrl+alt+z toggle_layout stack
    map ctrl+alt+o toggle_layout stack

    # --- Vim-like Tab Keybindings ---
    # Create tab
    map ctrl+alt+t new_tab_with_cwd
    map ctrl+shift+t new_tab_with_cwd

    # Tab navigation
    map ctrl+alt+n next_tab
    map ctrl+alt+p previous_tab
    map ctrl+tab next_tab
    map ctrl+shift+tab previous_tab
    map ctrl+alt+1 goto_tab 1
    map ctrl+alt+2 goto_tab 2
    map ctrl+alt+3 goto_tab 3
    map ctrl+alt+4 goto_tab 4
    map ctrl+alt+5 goto_tab 5
    map ctrl+alt+6 goto_tab 6
    map ctrl+alt+7 goto_tab 7
    map ctrl+alt+8 goto_tab 8
    map ctrl+alt+9 goto_tab 9

    # Tab reorder & title
    map ctrl+alt+shift+n move_tab_forward
    map ctrl+alt+shift+p move_tab_backward
    map ctrl+alt+r set_tab_title
    map ctrl+alt+shift+w close_tab

    # Amethyst Aero (shared palette)
    background ${palette.background}
    foreground ${palette.text}
    background_opacity 0.90

    selection_background ${palette.highlight}
    selection_foreground ${palette.background}

    cursor ${palette.highlight}
    cursor_text_color ${palette.background}

    url_color ${palette.highlight}

    # standard colors
    color0 ${palette.edge}
    color1 ${palette.red}
    color2 ${palette.green}
    color3 ${palette.yellow}
    color4 ${palette.blue}
    color5 ${palette.accent}
    color6 ${palette.cyan}
    color7 ${palette.muted}

    # bright colors
    color8 ${palette.edge}
    color9 ${palette.red}
    color10 ${palette.green}
    color11 ${palette.yellow}
    color12 ${palette.blue}
    color13 ${palette.accent}
    color14 ${palette.cyan}
    color15 ${palette.text}

    # 16-color extension
    color16 ${palette.yellow}
    color17 ${palette.highlight}
  '';
in
pkgs.symlinkJoin {
  name = "kitty-wrapped";
  paths = [ pkgs.kitty ];
  buildInputs = [ pkgs.makeWrapper ];
  postBuild = ''
    wrapProgram $out/bin/kitty --add-flags "--config=${config}"
  '';
}

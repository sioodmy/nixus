{
  pkgs,
  inputs,
  ...
}:
let
  inherit (pkgs.lib.meta) getExe getExe';

  xdg-open = getExe' pkgs.xdg-utils "xdg-open";

  config = pkgs.writeText "kitty.conf" ''
    # Fonts
    font_family      monospace
    bold_font        auto
    italic_font      auto
    bold_italic_font auto
    font_size        10
    modify_font      cell_height 140%

    # Window layout
    remember_window_size  no
    initial_window_width  104c
    initial_window_height 36c
    window_padding_width  8
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

    active_tab_foreground   #181926
    active_tab_background   #b7bdf8
    active_tab_font_style   bold
    inactive_tab_foreground #cad3f5
    inactive_tab_background #363a4f
    inactive_tab_font_style normal
    tab_bar_background      #1e2030
    tab_bar_margin_color    #1e2030

    draw_minimal_borders yes
    window_border_width 1.5pt
    active_border_color #b7bdf8
    inactive_border_color #494d64
    bell_border_color #eed49f
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

    # Colors (Catppuccin Macchiato)
    background #24273a
    foreground #cad3f5
    background_opacity 0.91

    selection_background #f4dbd6
    selection_foreground #24273a

    cursor #f4dbd6
    cursor_text_color #181926

    url_color #f4dbd6

    # standard colors
    color0 #494d64
    color1 #ed8796
    color2 #a6da95
    color3 #eed49f
    color4 #8aadf4
    color5 #f5bde6
    color6 #8bd5ca
    color7 #b8c0e0

    # bright colors
    color8 #5b6078
    color9 #ed8796
    color10 #a6da95
    color11 #eed49f
    color12 #8aadf4
    color13 #f5bde6
    color14 #8bd5ca
    color15 #a5adcb

    # 16-color extension
    color16 #f5a97f
    color17 #f4dbd6
  '';
in
pkgs.symlinkJoin {
  name = "kitty-wrapped";
  paths = [pkgs.kitty];
  buildInputs = [ pkgs.makeWrapper ];
  postBuild = ''
    wrapProgram $out/bin/kitty --add-flags "--config=${config}"
  '';
}

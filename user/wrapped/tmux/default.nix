{
  pkgs,
  ...
}:
let
  palette = builtins.fromJSON (builtins.readFile ../../quickshell/ui/palette.json);
  accent = pkgs.lib.removePrefix "#" palette.accent;
  text = pkgs.lib.removePrefix "#" palette.text;
  black = pkgs.lib.removePrefix "#" palette.raised;
  background = pkgs.lib.removePrefix "#" palette.background;
  plugins = [
    "vim-tmux-navigator"
    "sensible"
    "yank"
  ];
  tmuxconf = pkgs.writeText "tmux.conf" ''
    set -g mouse on

    unbind C-b
    set -g prefix C-Space
    bind C-Space send-prefix

    bind h select-pane -L
    bind j select-pane -D
    bind k select-pane -U
    bind l select-pane -R

    # Start windows and panes at 1, not 0
    set -g base-index 1
    set -g pane-base-index 1
    set-window-option -g pane-base-index 1
    set-option -g renumber-windows on

    ${builtins.concatStringsSep "\n" (
      map (x: "run-shell ${pkgs.tmuxPlugins.${x}}/share/tmux-plugins/${x}.tmux") plugins
    )}

    # set vi-mode
    set-window-option -g mode-keys vi
    # keybindings
    bind-key -T copy-mode-vi v send-keys -X begin-selection
    bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle
    bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel

    bind '"' split-window -v -c "#{pane_current_path}"
    bind % split-window -h -c "#{pane_current_path}"

    set -g pane-border-style fg='#${black}'
    set -g pane-active-border-style fg='#${accent}'

    set -g status-style bg='#${background}',fg='#${text}'
    set -g status-interval 1
    set -g status-right-length 60
    set-window-option -g window-status-separator ""
    set -g status-left "#[bg=#${black}]#[fg=#${text}]"
    set -g status-left '#[bg=#${black}]#[fg=#${text}]#{?client_prefix,#[fg=#${accent}],} 󱄅 '
    set -ga status-left '#[bg=#${black}]#[fg=#${accent}]#{?window_zoomed_flag,   , }'
    set -g window-status-current-format "#[bold]#[fg=#${text}]#[bg=#${accent}] #I#[nobold] #W "
    set -g window-status-format "#[bold]#[fg=#${text}]#[bg=#${black}] #I#[nobold] #W "
    set -g status-right '#[fg=#${text},bg=#${background}] #(${pkgs.tmux-mem-cpu-load}/bin/tmux-mem-cpu-load -g 0 -a 0 --interval 2) '
    set -ga status-right '#[fg=#${text},bg=#${black}] %a %H:%M:%S #[fg=#${text},bg=#${accent}] %Y-%m-%d '
  '';
in
pkgs.symlinkJoin {
  name = "tmux-wrapped";
  paths = [ pkgs.tmux ];
  buildInputs = [ pkgs.makeWrapper ];
  postBuild = ''
    wrapProgram $out/bin/tmux --add-flags "-f ${tmuxconf}"
  '';
}

{ ... }:
let
  c = builtins.fromJSON (builtins.readFile ../quickshell/ui/palette.json);
  hex = value: builtins.substring 1 6 value;
in
{
  homix = {
    ".config/foot/foot.ini".text = ''
      [main]
      font=JetBrains Mono:size=10
      pad=12x12
      [colors]
      alpha=0.90
      background=${hex c.background}
      foreground=${hex c.text}
      selection-background=${hex c.edge}
      selection-foreground=${hex c.text}
      regular0=${hex c.surface}
      regular1=${hex c.red}
      regular2=${hex c.green}
      regular3=${hex c.yellow}
      regular4=${hex c.blue}
      regular5=${hex c.accent}
      regular6=${hex c.cyan}
      regular7=${hex c.muted}
      bright0=${hex c.edge}
      bright1=${hex c.red}
      bright2=${hex c.green}
      bright3=${hex c.yellow}
      bright4=${hex c.blue}
      bright5=${hex c.highlight}
      bright6=${hex c.cyan}
      bright7=${hex c.text}
    '';
    ".config/alacritty/alacritty.toml".text = ''
      [window]
      opacity = 0.90
      padding = { x = 12, y = 12 }
      [font]
      normal = { family = "JetBrains Mono" }
      size = 10
      [colors.primary]
      background = "${c.background}"
      foreground = "${c.text}"
      [colors.selection]
      background = "${c.edge}"
      text = "${c.text}"
      [colors.normal]
      black = "${c.surface}"
      red = "${c.red}"
      green = "${c.green}"
      yellow = "${c.yellow}"
      blue = "${c.blue}"
      magenta = "${c.accent}"
      cyan = "${c.cyan}"
      white = "${c.muted}"
      [colors.bright]
      black = "${c.edge}"
      red = "${c.red}"
      green = "${c.green}"
      yellow = "${c.yellow}"
      blue = "${c.blue}"
      magenta = "${c.highlight}"
      cyan = "${c.cyan}"
      white = "${c.text}"
    '';
    ".config/btop/themes/Amethyst.theme".text = ''
      theme[main_bg]="${c.background}"
      theme[main_fg]="${c.text}"
      theme[title]="${c.highlight}"
      theme[hi_fg]="${c.accent}"
      theme[selected_bg]="${c.raised}"
      theme[selected_fg]="${c.text}"
      theme[inactive_fg]="${c.muted}"
      theme[graph_text]="${c.text}"
      theme[meter_bg]="${c.edge}"
      theme[proc_misc]="${c.accent}"
      theme[cpu_box]="${c.edge}"
      theme[mem_box]="${c.edge}"
      theme[net_box]="${c.edge}"
      theme[proc_box]="${c.edge}"
      theme[div_line]="${c.edge}"
      theme[cpu_start]="${c.edge}"
      theme[cpu_mid]="${c.accent}"
      theme[cpu_end]="${c.highlight}"
      theme[free_start]="${c.edge}"
      theme[free_mid]="${c.green}"
      theme[free_end]="${c.green}"
      theme[used_start]="${c.edge}"
      theme[used_mid]="${c.accent}"
      theme[used_end]="${c.highlight}"
      theme[download_start]="${c.edge}"
      theme[download_mid]="${c.cyan}"
      theme[download_end]="${c.cyan}"
      theme[upload_start]="${c.edge}"
      theme[upload_mid]="${c.accent}"
      theme[upload_end]="${c.highlight}"
    '';
    ".config/btop/btop.conf".text = ''
      color_theme = "Amethyst"
      theme_background = False
      truecolor = True
      rounded_corners = True
    '';
  };
  environment.variables.FZF_DEFAULT_OPTS = "--color=bg+:${c.raised},bg:${c.background},fg:${c.text},fg+:${c.text},hl:${c.accent},hl+:${c.highlight},border:${c.edge},info:${c.muted},prompt:${c.accent},pointer:${c.accent},marker:${c.green},spinner:${c.accent},header:${c.highlight}";
}

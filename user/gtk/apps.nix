{ ... }:
let
  c = builtins.fromJSON (builtins.readFile ../quickshell/ui/palette.json);
in
{
  homix = {
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

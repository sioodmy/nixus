{
  lib,
}:
let
  inherit (lib) isBool concatStringsSep mapAttrsToList;

  palette = builtins.fromJSON (builtins.readFile ../../quickshell/ui/palette.json);
  options = {
    recolor = true;
    adjust-open = "best-fit";
    pages-per-row = 1;
    scroll-page-aware = true;
    selection-clipboard = "clipboard";
    guioptions = "";
    zoom-min = 10;
    render-loading = true;
    scroll-full-overlap = "0.01";
    scroll-step = 100;

    notification-error-bg = palette.background;
    notification-error-fg = palette.red;
    notification-warning-bg = palette.background;
    notification-warning-fg = palette.yellow;
    notification-bg = palette.background;
    notification-fg = palette.text;

    completion-bg = palette.background;
    completion-fg = palette.text;
    completion-group-bg = palette.raised;
    completion-group-fg = palette.text;
    completion-highlight-bg = palette.accent;
    completion-highlight-fg = palette.raised;

    index-bg = palette.background;
    index-fg = palette.highlight;
    index-active-bg = palette.highlight;
    index-active-fg = palette.background;

    inputbar-bg = palette.background;
    inputbar-fg = palette.text;

    statusbar-bg = palette.background;
    statusbar-fg = palette.text;

    highlight-color = palette.yellow;
    highlight-active-color = palette.red;

    default-bg = palette.background;
    default-fg = palette.text;
    render-loading-bg = palette.background;
    render-loading-fg = palette.edge;

    recolor-lightcolor = palette.background;
    recolor-darkcolor = palette.text;
  };

  formatLine =
    n: v:
    let
      formatValue = v: if isBool v then (if v then "true" else "false") else toString v;
    in
    ''set ${n}	"${formatValue v}"'';
in
concatStringsSep "\n" (mapAttrsToList formatLine options) + "\n"

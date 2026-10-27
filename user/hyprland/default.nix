{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.hyprland;
  palette = builtins.fromJSON (builtins.readFile ../quickshell/ui/palette.json);

  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types
    ;
  inherit (builtins) map;

  # The config lives as real .lua files in ./config so it stays readable and
  # lintable in-tree; `homix` symlinks them into ~/.config/hypr rather than
  # generating them, so there is exactly one copy on disk.
  #
  # Each file is linked individually instead of linking the whole directory:
  # that leaves room for 07-apps-to-workspaces.lua, which is rendered from
  # `hyprland.workspaceBindings` below.
  #
  # Hyprland 0.55+ prefers `hyprland.lua` over `hyprland.conf`, so dropping
  # the Lua file in is enough — no session or module flag to flip.
  staticFiles = [
    "hyprland.lua"
    "conf.d/02-input.lua"
    "conf.d/03-decoration.lua"
    "conf.d/04-animations.lua"
    "conf.d/05-binds.lua"
    "conf.d/06-rules.lua"
    "conf.d/08-autostart.lua"
    "conf.d/09-plugins.lua"
  ];

  pluginPkgs = import ./plugins.nix { inherit pkgs; };

  # Sorted so the generated file has a stable order; the plugins themselves are
  # order-independent, but a stable file keeps the symlinked target from
  # churning between activations.
  plugins = lib.sort (n: m: n < m) (lib.attrNames cfg.plugins);

  # RE2 needs the dots escaped: Hyprland matches rules with a full match, so
  # both anchors are load-bearing.
  windowRule = class: workspace: ''
    hl.window_rule({
        name  = "pin-${class}-to-ws${toString workspace}",
        match = { class = "^${lib.escapeRegex class}$" },
        workspace = "${toString workspace}",
    })
  '';

  # Group the class -> workspace map by workspace so the generated file reads
  # like the hand-written one.
  workspaces = lib.listToAttrs (
    map (workspace: {
      name = "${toString workspace}";
      value = lib.filterAttrs (_: ws: ws == workspace) cfg.workspaceBindings;
    }) (lib.unique (lib.attrValues cfg.workspaceBindings))
  );

  workspaceRules = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (
      workspace: classes:
      let
        names = lib.attrNames classes;
      in
      ''
        -- workspace ${workspace}: ${lib.concatStringsSep ", " names}
        ${lib.concatStringsSep "\n" (map (class: windowRule class workspace) names)}
      ''
    ) workspaces
  );
in
{
  options.hyprland = {
    enable = mkEnableOption "the Hyprland session";

    workspaceBindings = mkOption {
      type = types.attrsOf types.int;
      default = {
        # Terminals.
        kitty = 1;
        foot = 1;
        # Browsers.
        helium = 2;
        Helium = 2;
        firefox = 2;
        # Messengers.
        ferdium = 4;
        signal = 4;
      };
      description = ''
        Window classes pinned to a workspace by a window rule, as a
        class-to-workspace attribute set. Rendered into
        ~/.config/hypr/conf.d/07-apps-to-workspaces.lua, which the static
        config pulls in alongside everything else.

        SUPER+<n> still just switches workspace; these rules decide where a
        window lands when it is opened.
      '';
    };

    plugins = mkOption {
      type = types.attrsOf types.package;
      # ./plugins.nix already leaves out plugins that cannot work on the build
      # architecture, so this is the attrset as-is.
      default = pluginPkgs;
      defaultText = lib.literalExpression ''
        import ./plugins.nix { inherit pkgs; }
      '';
      description = ''
        Hyprland plugins to build and load, as a name-to-derivation set.

        Defaults to every plugin in ./plugins.nix. Drop an entry here to stop
        building and loading it; the generated 00-plugins.lua drops its
        `hl.plugin.load` line and its configuration goes with it (each block in
        09-plugins.lua is guarded by an `if hl.plugin.<name>` check).

        Plugin *settings* live in 09-plugins.lua, not here -- this option only
        decides what gets built and loaded.
      '';
    };
  };

  config = mkIf cfg.enable {
    # The compositor itself. nixpkgs' `programs.hyprland` is deliberately not
    # used: its generated config would fight with the homix links.
    environment.systemPackages = [ pkgs.hyprland ];

    homix =
      lib.foldl' (acc: file: acc // { ".config/hypr/${file}".source = ./config/${file}; }) { } staticFiles
      // {
        ".config/hypr/conf.d/01-general.lua".text =
          lib.replaceStrings [ "@accent@" "@highlight@" "@edge@" ]
            (map (name: lib.removePrefix "#" palette.${name}) [
              "accent"
              "highlight"
              "edge"
            ])
            (builtins.readFile ./config/conf.d/01-general.lua);
        # 00-plugins.lua has to be generated, not hand-written: the store paths
        # of the .so files only exist after a build. Everything the plugins are
        # *configured* with stays in the hand-written 09-plugins.lua.
        ".config/hypr/conf.d/00-plugins.lua".text = ''
          -- ---------------------------------------------------------------------------
          -- 00-plugins.lua -- GENERATED, do not edit.
          --
          -- Rendered from `hyprland.plugins` in user/hyprland/default.nix, which
          -- in turn comes from user/hyprland/plugins.nix. Change the Nix option
          -- instead; this file is overwritten on every activation.
          -- ---------------------------------------------------------------------------
          --
          -- Plugin loading happens at the end of config parsing, and each plugin
          -- then triggers one more reload so its `hl.plugin.<name>` namespace and
          -- config values exist. That second pass is what makes the guarded
          -- blocks in 09-plugins.lua apply.
          --
          -- Loading a plugin needs `ecosystem:enforce_permissions` (set in
          -- 01-general.lua) to have a rule for it -- see the plugin allow-list in
          -- 06-rules.lua.

          ${lib.concatMapStringsSep "\n" (name: ''
            hl.plugin.load("${cfg.plugins.${name}.passthru.pluginPath}")
          '') plugins}
        '';

        ".config/hypr/conf.d/07-apps-to-workspaces.lua".text = ''
          -- ---------------------------------------------------------------------------
          -- 07-apps-to-workspaces.lua -- GENERATED, do not edit.
          --
          -- Rendered from `hyprland.workspaceBindings` in user/hyprland/default.nix.
          -- Change the Nix option instead; this file is overwritten on every
          -- activation.
          -- ---------------------------------------------------------------------------
          --
          -- Each window below is moved to its workspace as it opens, and focus
          -- follows it there.

          ${workspaceRules}
        '';
      };
  };
}

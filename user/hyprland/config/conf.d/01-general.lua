-- ---------------------------------------------------------------------------
-- 01-general.lua
--
-- Ported from the niri `layout` block.
--
-- Colours are Catppuccin Macchiato with a mauve accent, matching the
-- GTK/Qt/kitty/tmux themes in user/gtk and user/wrapped.
-- ---------------------------------------------------------------------------

hl.config({
    general = {
        -- Niri is scrollable-tiling; Hyprland's built-in scrolling layout is
        -- the closest match. Focus semantics line up too: left/right crosses
        -- columns, up/down moves within a column.
        layout = "scrolling",

        -- niri: gaps 5 between windows. Hyprland needs a separate value for
        -- the screen edge; 5 keeps the tape from touching the bezel.
        gaps_in         = 5,
        gaps_out        = 5,
        gaps_workspaces = 0,

        -- niri drew no borders; its geometry-corner-radius rule became the
        -- global `decoration` block in 03-decoration.lua.
        border_size = 0,
        col = {
            active_border         = "rgba(c6a0f6ff)",
            inactive_border       = "rgba(363a4f00)",
            nogroup_border        = "rgba(89b4facc)",
            nogroup_border_active = "rgba(89b4faff)",
        },

        resize_on_border = true,
        no_focus_fallback = false,
        resize_corner = 0,
        allow_tearing = false,

        snap = {
            enabled = false,
        },
    },

    scrolling = {
        -- niri's preset-column-widths: 0.33333 / 0.5 / 0.66667
        explicit_column_widths = "0.333, 0.5, 0.667",
        column_width           = 0.5,
        direction              = "right",
        fullscreen_on_one_column = true,
        follow_focus           = true,
        follow_min_visible     = 0.4,
        focus_fit_method       = 1,
        wrap_focus             = true,
        wrap_swapcol           = true,
    },

    master = {
        allow_small_split = false,
        new_status        = "slave",
        mfact             = 0.55,
    },

    group = {
        auto_group      = false,
        drag_into_group = 0,
        groupbar = {
            enabled = false,
        },
    },

    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        disable_hyprland_guiutils_check = true,
        disable_watchdog_warning = true,

        -- niri's `layout { background-color "transparent" }`
        background_color = "00000000",

        vrr                   = 0,
        force_default_wallpaper = -1,
        key_press_enables_dpms = true,
        mouse_move_enables_dpms = true,

        -- MUST stay false. When true, any layer surface with Exclusive
        -- keyboard focus (dock calendar/polkit island, stuck launcher,
        -- fullscreen media) swallows ALL keyboard input and mouse clicks no
        -- longer refocus normal windows: quickshell stays clickable, workspace
        -- binds keep working, but terminal/browser are dead. That is exactly
        -- the "freeze" from 2026-10-03. Modal pinning is already handled by
        -- HyprlandFocusGrab on the shell side, so the global hog only adds a
        -- way to brick the session when a layer gets stuck open.
        layers_hog_keyboard_focus = false,

        focus_on_activate = true,
        middle_click_paste = true,
        enable_swallow = false,

        -- niri's `prefer-no-csd` plus clients that draw their own chrome.
        initial_workspace_tracking = 1,
    },

    xwayland = {
        enabled = true,
        force_zero_scaling = true,
        use_nearest_neighbor = true,
    },

    cursor = {
        hotspot_padding    = 2,
        no_hardware_cursors = 2,
        inactive_timeout   = 5,
        hide_on_key_press  = true,
        hide_on_touch      = false,
        zoom_rigid         = true,
        sync_gsettings_theme = true,
    },

    ecosystem = {
        no_update_news = true,
        no_donation_nag = true,

        -- Required for the `hl.permission` rules in 06-rules.lua to apply.
        -- Everything allowed to grab the screen must be listed there or it
        -- gets asked about — and with no permission agent running, that means
        -- denied.
        enforce_permissions = true,
    },
})

-- ---------------------------------------------------------------------------
-- 03-decoration.lua
--
-- niri's `window-rule { geometry-corner-radius 15; clip-to-geometry true }`
-- becomes the global `decoration` block here. Window blur is enabled
-- globally and opted out per-app in 06-rules.lua, which mirrors niri's
-- `window-rule { match app-id=kitty; blur true }`.
-- ---------------------------------------------------------------------------

hl.config({
    decoration = {
        rounding       = 10,
        rounding_power = 2.0,

        active_opacity     = 1.0,
        inactive_opacity   = 1.0,
        fullscreen_opacity = 1.0,

        shadow = {
            enabled      = true,
            range        = 30,
            render_power = 3,
            sharp        = false,
            color            = "rgba(0000007b)",
            color_inactive   = "rgba(0000005a)",
            offset           = { 0, 5 },
            scale            = 1.0,
        },

        -- `size` and `passes` are what the compositor samples *past* a window's
        -- edge: the fringe of content visible behind a translucent surface.
        blur = {
            enabled            = true,
            size               = 8,
            passes             = 2,
            ignore_opacity     = true,
            new_optimizations  = true,
            noise              = 0.02,
            contrast           = 0.9,
            brightness         = 1.0,
            vibrancy           = 0.15,
            vibrancy_darkness  = 0.15,
            xray               = false,
            popups             = true,
            popups_ignorealpha = 0.2,
            special            = false,
            input_methods      = false,
        },
    },
})

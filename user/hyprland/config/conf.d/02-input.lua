-- ---------------------------------------------------------------------------
-- 02-input.lua
--
-- Ported from the niri `input` block. niri's flat touchpad profile maps onto
-- Hyprland's `accel_profile` plus a single scroll_factor.
--
-- Touchpad gestures: 3-finger horizontal swipe switches workspaces.
-- ---------------------------------------------------------------------------

hl.config({
    input = {
        kb_layout  = "pl",
        kb_options = "caps:escape",

        -- niri's `focus-follows-mouse max-scroll-amount="25%"`: always follow,
        -- but only once the cursor has actually travelled.
        follow_mouse           = 1,
        follow_mouse_threshold = 0,
        mouse_refocus          = true,
        -- Refocus the window under cursor on close (prevents activewindow Invalid freeze)
        focus_on_close         = 1,

        repeat_rate  = 50,
        repeat_delay = 250,

        sensitivity    = -0.2,
        accel_profile = "flat",
        scroll_factor = 0.8,
        scroll_method = "2fg",
        natural_scroll = false,

        touchpad = {
            tap_button_map          = "lrm",
            natural_scroll          = true,
            scroll_factor           = 0.2,
            disable_while_typing    = true,
            middle_button_emulation = true,
            clickfinger_behavior    = true,
        },
    },

    gestures = {
        workspace_swipe_distance = 300,
        workspace_swipe_cancel_ratio = 0.5,
    },
})

hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace",
})


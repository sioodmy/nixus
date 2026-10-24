-- ---------------------------------------------------------------------------
-- 09-plugins.lua
--
-- Configuration for the Hyprland plugins built by ./plugins.nix and loaded by
-- the generated 00-plugins.lua.
--
-- Every block is wrapped in `if hl.plugin.<name> then`. A plugin's namespace
-- and config values are only registered *after* it is dlopen'd, which happens
-- at the end of config parsing and triggers one more reload -- so on the first
-- pass through this file the namespaces do not exist yet, and touching them
-- unguarded is a hard config error. The guard is what makes the second pass
-- apply these settings.
--
-- The names below are the config keys with `-` turned into `_`; that is
-- Hyprland's own mangling of `plugin:<name>:<key>`.
--
-- Plugins that cannot run on the host architecture never appear in the set at
-- all -- plugins.nix drops them before 00-plugins.lua is rendered, so the
-- guard alone is the whole architecture story here.
-- ---------------------------------------------------------------------------

-- --- hypr-dynamic-cursors: tilt + shake to find ------------------------------
--
-- Tilt mode leans the cursor into the direction of travel, like an object
-- dragged through air. Shake to find magnifies it when you shake the mouse,
-- which is the only feature here worth having on its own.
--
-- Costs a little GPU: the shape changes every frame while the mouse moves, so
-- with hardware cursors this is roughly an animated cursor per frame, and
-- magnification forces software cursors for the duration of the shake.
--
-- The block is unreachable in practice on this host: the plugin is built
-- entirely on function hooks, so plugins.nix leaves it out of the set on
-- anything but x86_64 rather than have it throw on load. Keep the config here
-- anyway -- it is what runs the moment the machine is on x86_64, and it is the
-- record of what was asked for.

if hl.plugin.dynamic_cursors then
    local dc = hl.plugin.dynamic_cursors

    hl.config({
        plugin = {
            dynamic_cursors = {
                enabled = true,
                mode    = "tilt",

                -- Below this angle change the shape is left alone. Higher is
                -- cheaper with hardware cursors, lower is smoother.
                threshold = 2,

                tilt = {
                    -- Speed (px/s) at which full tilt is reached. Higher = the
                    -- cursor stays upright longer.
                    limit      = 5000,
                    -- How speed maps to angle. `negative_quadratic` feels the
                    -- most like air drag of the three.
                    activation = "negative_quadratic",
                    -- Averaging window (ms). Higher smooths slow motion but
                    -- adds lag.
                    window = 100,
                    -- Maximum lean either way (degrees).
                    full  = 55,
                },

                shake = {
                    enabled = true,
                    -- How fast the pointer has to reverse for a shake to
                    -- register. Lower fires sooner and more easily.
                    threshold = 6.0,
                    -- Zoom right at the start, then per second while shaking.
                    base  = 4.0,
                    speed = 4.0,
                    -- Cap on the magnification. Upstream leaves this at 0,
                    -- meaning no limit -- a long shake grows the cursor until it
                    -- fills the screen.
                    limit   = 4.0,
                    -- How long it stays magnified after the shake ends.
                    timeout = 2000,
                    -- Keep the cursor upright while magnifying: tilting the
                    -- thing you are trying to find just makes it harder to
                    -- track.
                    effects = false,
                },

                hyprcursor = {
                    enabled = true,
                    -- Without an SVG hyprcursor theme there is no high-res
                    -- image to fall back on, so magnify from the normal cursor
                    -- texture and keep its edges crisp instead of blurring them.
                    nearest   = 1,
                    resolution = -1,
                },
            },
        },
    })

    -- The default cursors for the left/right resize and move arrows are
    -- side-facing, so tilting them into the direction of travel reads as
    -- skew rather than lean. Straighten those.
    dc.shape_rule({ shape = "e-resize", mode = "none" })
    dc.shape_rule({ shape = "w-resize", mode = "none" })
    dc.shape_rule({ shape = "n-resize", mode = "none" })
    dc.shape_rule({ shape = "s-resize", mode = "none" })
end

-- --- hypr-kinetic-scroll: inertial touchpad scrolling -----------------------
--
-- Momentum starts when the fingers leave the pad, so it works in every app,
-- not just the ones that implement inertia themselves.
--
-- Synthetic deltas are scaled by `input:touchpad:scroll_factor` from
-- 02-input.lua, which is set low (0.2) for a niri-like feel; `delta_multiplier`
-- below is what compensates so momentum still lands at a usable speed.

if hl.plugin.kinetic_scroll then
    hl.config({
        plugin = {
            kinetic_scroll = {
                enabled = true,

                -- Per-frame velocity decay. Lower stops sooner.
                decel  = 0.92,
                -- Velocity below which inertia is considered finished.
                min_velocity = 0.5,
                -- Decay step in ms. Lower is smoother.
                interval_ms = 16,
                -- Impulse gain per swipe. Higher builds speed faster, and
                -- offsets the low touchpad scroll_factor.
                delta_multiplier = 2.0,

                -- Browsers (and anything else that scrolls itself) already have
                -- good inertia; adding a second one on top overshoots.
                disable_in_browser = 1,

                -- Kill momentum when the window under the pointer changes,
                -- otherwise a flick that lands on another window keeps
                -- scrolling it.
                stop_on_target_change = 1,

                -- Touching the pad stops momentum, so a scroll can be caught
                -- mid-flight. Clicking or focusing something else does not --
                -- that made momentum feel like it randomly gave up.
                stop_on_click = 0,
                stop_on_focus = 0,
            },
        },
    })

    -- Chat clients scroll their message lists with their own animation and
    -- fight the compositor over the same events.
    hl.plugin.kinetic_scroll.disable("org.telegram.desktop")
    hl.plugin.kinetic_scroll.disable("signal-desktop")
end

-- --- hypr-edgehover: pointer motion in the gaps -----------------------------
--
-- The 5px outer gap in 01-general.lua is dead zone: the pointer has to cross
-- it before the window under it reacts. This forwards motion from the gap, and
-- from the shell's edge-anchored bars, into the adjacent window as if the
-- cursor were clamped just inside its edge -- so a window can be resized by
-- dragging against the screen edge, and scrolled by wheeling over the gap.

if hl.plugin.hypr_edgehover then
    hl.config({
        plugin = {
            hypr_edgehover = {
                enabled = true,
                -- Forward motion in the outer window gaps on every edge.
                edges = "lrtb",
                -- How far inside the target edge the synthetic pointer sits.
                -- 1px is enough to register as "inside" and not enough to be
                -- visible.
                inset = 1,
                -- How far from the monitor edge gap forwarding still applies.
                -- 0 = the whole gap band, which is what `gaps_out = 5` leaves.
                max_distance = 0,

                -- -1 follows input:follow_mouse, which is 1 in 02-input.lua, so
                -- hovering the edge also focuses the window it forwards to.
                keyboard_focus = -1,

                -- The gap is real empty space, so everything passes through:
                -- hover for tooltips, clicks, and the wheel.
                gap_pass = "hover,click,scroll,keyboard",
                -- Bars are not gaps -- the pointer is visibly over them -- so
                -- only hover and focus move, and only within steal_edge_width
                -- of the physical edge. Elsewhere the bar behaves normally,
                -- which keeps its own hover styling working.
                layer_pass = "hover,keyboard",
                -- Only the shell's own panels, not every layer that happens to
                -- touch the edge (notifications, lock screen, OSDs).
                layer_namespaces = "amethyst-bar",
                steal_edge_width = 2,

                -- A thin strip of window poking past another one is treated as
                -- an overhang: motion over it goes to the window it covers
                -- instead. Without this, a window dragged half off-screen
                -- becomes a dead zone along its own sliver.
                overhang_pass      = "hover,scroll,keyboard",
                overhang_threshold = 8,

                -- Every edge, the whole way along. Restricting these to zones
                -- would only matter if the shell had edge-anchored panels that
                -- should stay dead.
                zones_top    = "0-100",
                zones_bottom = "0-100",
                zones_left   = "0-100",
                zones_right  = "0-100",
            },
        },
    })
end

-- --- binds ------------------------------------------------------------------
--
-- Manual shake-to-find, for when the mouse is under a book or the shake did
-- not register. Bound here rather than in 05-binds.lua because the dispatcher
-- only exists once the plugin has been loaded, same as everything above.

if hl.plugin.dynamic_cursors then
    hl.bind("SUPER + SHIFT + mouse_down", hl.plugin.dynamic_cursors.dsp_magnify({ duration = 2000, size = 4.0 }))
end

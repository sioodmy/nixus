-- ---------------------------------------------------------------------------
-- 04-animations.lua
--
-- Ported from niri's `animations` block. Hyprland has no hook for GLSL
-- shaders, so niri's custom fall-from-top shader is replaced by a popin.
--
-- `speed` is a duration, not a velocity: it is the number of deciseconds the
-- animation runs for, so speed = 2 is 200 ms and *lower* is faster. The niri
-- durations it was ported from were read as "higher is faster", which left
-- every animation at 300-800 ms -- slow enough that workspace switches and
-- window closes visibly lag behind the input.
--
-- The values below are shorter than niri's own defaults (window open ~150 ms,
-- close 400 ms). Hyprland animations are global, so the close animation is
-- paid on every focus change, scratchpad toggle and window hand-off; anything
-- above ~200 ms reads as latency rather than motion.
-- ---------------------------------------------------------------------------

-- niri: workspace-switch { spring damping-ratio=0.80 stiffness=1500 }
hl.curve("niriSpring", { type = "bezier", points = { { 0.22, 0.61 }, { 0.16, 1.0 } } })
-- niri: window-open { curve "ease-out-expo" }
hl.curve("easeOutExpo", { type = "bezier", points = { { 0.16, 1.0 }, { 0.3, 1.0 } } })
hl.curve("linear",     { type = "bezier", points = { { 0.0, 0.0 },  { 1.0, 1.0 } } })

-- Root of the tree: everything inherits from here unless overridden, including
-- the leaves not listed below (fadeSwitch, fadeDim, fadePopups, border,
-- monitorAdded, zoomFactor). 200 ms is the baseline for the whole session.
hl.animation({ leaf = "global", enabled = true, speed = 2.0, bezier = "default" })

-- Workspace switches slide the full screen width, so they get the longest of
-- the "feels instant" durations; the ease-out front-loads the movement and the
-- tail is barely readable.
hl.animation({ leaf = "workspaces",    enabled = true, speed = 2.0, bezier = "niriSpring", style = "slide" })
hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 2.0, bezier = "niriSpring", style = "slide" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.6, bezier = "niriSpring", style = "slide" })

-- niri's window-open shader (fall from top with a slight random tilt) -> popin.
-- Close is shorter than open: there is no new content to read, so waiting on it
-- only makes the desktop feel unresponsive.
hl.animation({ leaf = "windows",    enabled = true, speed = 1.8, bezier = "easeOutExpo", style = "popin 12%" })
hl.animation({ leaf = "windowsIn",  enabled = true, speed = 1.8, bezier = "easeOutExpo", style = "popin 12%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.3, bezier = "linear",     style = "slide -25%" })
-- Move/resize has to track the pointer, not chase it.
hl.animation({ leaf = "windowsMove", enabled = true, speed = 1.4, bezier = "easeOutExpo", style = "slide" })

-- Layer surfaces are the shell's bars, launcher and notifications, hit far more
-- often than windows, so they get the shortest fades.
hl.animation({ leaf = "layers",    enabled = true, speed = 1.4, bezier = "easeOutExpo", style = "fade" })
hl.animation({ leaf = "layersIn",  enabled = true, speed = 1.4, bezier = "easeOutExpo", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.0, bezier = "linear",     style = "fade" })

hl.animation({ leaf = "fade", enabled = true, speed = 1.4, bezier = "linear" })

-- Angles only run once per window/decoration, so 300 ms reads as a transition
-- instead of a flash. Do not set a `loop` style here: that redraws at the
-- monitor's refresh rate forever, even with no window on screen.
hl.animation({ leaf = "borderangle",  enabled = true, speed = 3.0, bezier = "default" })
hl.animation({ leaf = "shadowangle",  enabled = true, speed = 3.0, bezier = "default" })
hl.animation({ leaf = "glowangle",    enabled = true, speed = 3.0, bezier = "default" })

hl.animation({ leaf = "specialWorkspace",    enabled = true, speed = 1.8, bezier = "easeOutExpo", style = "slide" })
hl.animation({ leaf = "specialWorkspaceIn",  enabled = true, speed = 1.8, bezier = "easeOutExpo", style = "slide" })
hl.animation({ leaf = "specialWorkspaceOut", enabled = true, speed = 1.4, bezier = "easeOutExpo", style = "fade" })

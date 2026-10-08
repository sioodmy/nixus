-- ---------------------------------------------------------------------------
-- 04-animations.lua
--
-- Ported from niri's `animations` block. Hyprland has no hook for GLSL
-- shaders, so niri's custom fall-from-top shader is replaced by a popin.
-- ---------------------------------------------------------------------------

-- niri: workspace-switch { spring damping-ratio=0.80 stiffness=1500 }
hl.curve("niriSpring", { type = "bezier", points = { { 0.22, 0.61 }, { 0.16, 1.0 } } })
-- niri: window-open { curve "ease-out-expo" }
hl.curve("easeOutExpo", { type = "bezier", points = { { 0.16, 1.0 }, { 0.3, 1.0 } } })
hl.curve("linear",     { type = "bezier", points = { { 0.0, 0.0 },  { 1.0, 1.0 } } })

-- Root of the tree: everything inherits from here unless overridden.
hl.animation({ leaf = "global", enabled = true, speed = 8, bezier = "default" })

hl.animation({ leaf = "workspaces",   enabled = true, speed = 3.2, bezier = "niriSpring", style = "slide" })
hl.animation({ leaf = "workspacesIn", enabled = true, speed = 3.2, bezier = "niriSpring", style = "slide" })
hl.animation({ leaf = "workspacesOut",enabled = true, speed = 3.0, bezier = "niriSpring", style = "slide" })

-- niri's window-open shader (fall from top with a slight random tilt) -> popin.
hl.animation({ leaf = "windows",    enabled = true, speed = 4.0, bezier = "easeOutExpo", style = "popin 12%" })
hl.animation({ leaf = "windowsIn",  enabled = true, speed = 4.0, bezier = "easeOutExpo", style = "popin 12%" })
-- niri: window-close { duration-ms 400; curve "linear" }
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2.6, bezier = "linear",     style = "slide -25%" })
hl.animation({ leaf = "windowsMove",enabled = true, speed = 4.0, bezier = "easeOutExpo", style = "slide" })

hl.animation({ leaf = "layers",    enabled = true, speed = 4.0, bezier = "easeOutExpo", style = "fade" })
hl.animation({ leaf = "layersIn",  enabled = true, speed = 4.0, bezier = "easeOutExpo", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 4.0, bezier = "linear",     style = "fade" })

hl.animation({ leaf = "fade", enabled = true, speed = 4.0, bezier = "linear" })

hl.animation({ leaf = "borderangle",  enabled = true, speed = 8, bezier = "default" })
hl.animation({ leaf = "shadowangle",  enabled = true, speed = 8, bezier = "default" })
hl.animation({ leaf = "glowangle",    enabled = true, speed = 8, bezier = "default" })

hl.animation({ leaf = "specialWorkspace",    enabled = true, speed = 3.0, bezier = "easeOutExpo", style = "slide" })
hl.animation({ leaf = "specialWorkspaceIn",  enabled = true, speed = 3.0, bezier = "easeOutExpo", style = "slide" })
hl.animation({ leaf = "specialWorkspaceOut", enabled = true, speed = 3.0, bezier = "easeOutExpo", style = "fade" })

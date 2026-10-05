-- ---------------------------------------------------------------------------
-- 05-binds.lua
--
-- Ported from the niri `binds` block, key for key where Hyprland has an
-- equivalent. Because the scrolling layout maps left/right to "next/previous
-- column" and up/down to "previous/next window in column", the arrow and vim
-- bindings behave exactly like niri's.
--
-- Where Hyprland genuinely has no equivalent, the closest thing is bound and
-- marked with a NOTE. Modifier lists are ` + `-separated, e.g. "SUPER + SHIFT".
-- ---------------------------------------------------------------------------

local MOD    = "SUPER"
local TERM   = "kitty"
local LAUNCH = "lenin-launcher"

-- --- launcher / terminal / session -----------------------------------------

hl.bind(MOD .. " + Return", hl.dsp.exec_cmd(TERM))
hl.bind(MOD .. " + P", hl.dsp.exec_cmd(LAUNCH))
hl.bind(MOD .. " + ALT + L", hl.dsp.exec_cmd("lenin-lock"))
hl.bind(MOD .. " + ALT + K", hl.dsp.exec_cmd("lenin-keepass"))
hl.bind(MOD .. " + SHIFT + O", hl.dsp.exec_cmd("lenin-rsvp"))
hl.bind(MOD .. " + SHIFT + E", hl.dsp.exit())
hl.bind("CTRL + ALT + DELETE", hl.dsp.exit())
hl.bind("XF86Search", hl.dsp.exec_cmd(LAUNCH))

-- --- media / hardware keys --------------------------------------------------

hl.bind("XF86AudioRaiseVolume",
    hl.dsp.exec_cmd("sh -c 'flock -x /tmp/vol.lock wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.05+'"),
    { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",
    hl.dsp.exec_cmd("sh -c 'flock -x /tmp/vol.lock wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.05-'"),
    { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true, repeating = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true, repeating = true })

hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl pause"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"), { locked = true, repeating = true })

-- niri's keylit (keyboard backlight toggle) was orphaned in the niri config;
-- bound here so it is reachable.
hl.bind(MOD .. " + F1", hl.dsp.exec_cmd("keylit"))

-- --- window focus / movement -----------------------------------------------
--
-- Matches GrajAP's hyprland binds:
-- - Focus: MOD + H/J/K/L (repeating)
-- - Move window: MOD + SHIFT + H/L
-- - Move window across workspaces: MOD + SHIFT + J (+1) / MOD + SHIFT + K (-1)
-- - Resize active window: MOD + CTRL + H/J/K/L (repeating)

-- Focus (repeating = true, like GrajAP's binde)
hl.bind(MOD .. " + H", hl.dsp.focus({ direction = "left" }),  { repeating = true })
hl.bind(MOD .. " + J", hl.dsp.focus({ direction = "down" }),  { repeating = true })
hl.bind(MOD .. " + K", hl.dsp.focus({ direction = "up" }),    { repeating = true })
hl.bind(MOD .. " + L", hl.dsp.focus({ direction = "right" }), { repeating = true })

hl.bind(MOD .. " + Left",  hl.dsp.focus({ direction = "left" }),  { repeating = true })
hl.bind(MOD .. " + Down",  hl.dsp.focus({ direction = "down" }),  { repeating = true })
hl.bind(MOD .. " + Up",    hl.dsp.focus({ direction = "up" }),    { repeating = true })
hl.bind(MOD .. " + Right", hl.dsp.focus({ direction = "right" }), { repeating = true })

-- Move window left / right
hl.bind(MOD .. " + SHIFT + H", hl.dsp.window.move({ direction = "left" }))
hl.bind(MOD .. " + SHIFT + L", hl.dsp.window.move({ direction = "right" }))
hl.bind(MOD .. " + SHIFT + Left",  hl.dsp.window.move({ direction = "left" }))
hl.bind(MOD .. " + SHIFT + Right", hl.dsp.window.move({ direction = "right" }))

-- Move active window to next / previous workspace (+1 / -1)
hl.bind(MOD .. " + SHIFT + J", hl.dsp.window.move({ workspace = "+1" }))
hl.bind(MOD .. " + SHIFT + K", hl.dsp.window.move({ workspace = "-1" }))
hl.bind(MOD .. " + SHIFT + Down", hl.dsp.window.move({ workspace = "+1" }))
hl.bind(MOD .. " + SHIFT + Up",   hl.dsp.window.move({ workspace = "-1" }))

-- Resize active window (-80 / 80 px like GrajAP's resizeactive)
hl.bind(MOD .. " + CTRL + H", hl.dsp.window.resize({ x = -80, y = 0, relative = true }), { repeating = true })
hl.bind(MOD .. " + CTRL + J", hl.dsp.window.resize({ x = 0, y = 80, relative = true }),  { repeating = true })
hl.bind(MOD .. " + CTRL + K", hl.dsp.window.resize({ x = 0, y = -80, relative = true }), { repeating = true })
hl.bind(MOD .. " + CTRL + L", hl.dsp.window.resize({ x = 80, y = 0, relative = true }),  { repeating = true })
hl.bind(MOD .. " + CTRL + Left",  hl.dsp.window.resize({ x = -80, y = 0, relative = true }), { repeating = true })
hl.bind(MOD .. " + CTRL + Down",  hl.dsp.window.resize({ x = 0, y = 80, relative = true }),  { repeating = true })
hl.bind(MOD .. " + CTRL + Up",    hl.dsp.window.resize({ x = 0, y = -80, relative = true }), { repeating = true })
hl.bind(MOD .. " + CTRL + Right", hl.dsp.window.resize({ x = 80, y = 0, relative = true }),  { repeating = true })

-- First / last column in scrolling layout
hl.bind(MOD .. " + Home", hl.dsp.focus({ direction = "left" }))
hl.bind(MOD .. " + End",  hl.dsp.focus({ direction = "right" }))

hl.bind(MOD .. " + Q", hl.dsp.window.kill())
hl.bind(MOD .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(MOD .. " + W", hl.dsp.group.toggle())

-- NOTE: niri's "switch focus between floating and tiling" has no direct
-- equivalent; cycling through every window (tiled and floating) is the closest
-- thing Hyprland offers.
hl.bind(MOD .. " + SHIFT + V", hl.dsp.window.cycle_next({ next = true }))

-- --- column sizing (niri's set-column-width) -------------------------------
--
-- NOTE: niri's set-column-width percentages were relative to the *current*
-- column width. Hyprland's colresize takes points of the *monitor* width, so
-- ±10 is a proportionally bigger step on a narrow column. `±conf` cycles
-- `scrolling:explicit_column_widths` instead, which is the direct equivalent of
-- niri's preset-column-widths.

hl.bind(MOD .. " + minus", hl.dsp.layout("colresize -0.1"), { repeating = true })
hl.bind(MOD .. " + equal", hl.dsp.layout("colresize +0.1"), { repeating = true })
hl.bind(MOD .. " + CTRL + minus", hl.dsp.layout("colresize -conf"))
hl.bind(MOD .. " + CTRL + equal", hl.dsp.layout("colresize +conf"))

-- niri's switch-preset-column-width / reset-window-height
hl.bind(MOD .. " + R", hl.dsp.layout("colresize +conf"))
hl.bind(MOD .. " + CTRL + R", hl.dsp.layout("colresize 0.5"))
-- NOTE: niri's switch-preset-window-height has no scrolling-layout analogue;
-- bringing the focused column fully into view is the useful equivalent.
hl.bind(MOD .. " + SHIFT + R", hl.dsp.layout("fit_into_view"))

-- niri's maximize-column / expand-column-to-available-width
hl.bind(MOD .. " + F", hl.dsp.window.fullscreen({ mode = "maximized" }))
hl.bind(MOD .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
hl.bind(MOD .. " + CTRL + F", hl.dsp.layout("colresize 1.0"))

-- niri's center-column / center-visible-columns
hl.bind(MOD .. " + C", hl.dsp.layout("center"))
hl.bind(MOD .. " + CTRL + C", hl.dsp.layout("fit"))

-- niri's consume-or-expel-window-*
hl.bind(MOD .. " + bracketleft", hl.dsp.layout("expel"))
hl.bind(MOD .. " + bracketright", hl.dsp.layout("promote"))
hl.bind(MOD .. " + comma", hl.dsp.layout("consume"))
hl.bind(MOD .. " + period", hl.dsp.layout("expel"))

-- NOTE: niri's set-window-height has no scrolling-layout equivalent because
-- columns are sized by column, not by window.
hl.bind(MOD .. " + SHIFT + minus", hl.dsp.window.resize({ x = 0, y = -40, relative = true }))
hl.bind(MOD .. " + SHIFT + equal", hl.dsp.window.resize({ x = 0, y = 40, relative = true }))

-- --- monitors --------------------------------------------------------------

for _, dir in ipairs({ "left", "right", "up", "down" }) do
    hl.bind(MOD .. " + ALT + " .. dir, hl.dsp.focus({ monitor = dir }))
    hl.bind(MOD .. " + SHIFT + CTRL + " .. dir, hl.dsp.window.move({ monitor = dir }))
end

-- --- workspaces ------------------------------------------------------------
--
-- Workspaces 1-10 (matching GrajAP):
-- MOD + 1..9, 0 switches to workspace 1..10.
-- MOD + SHIFT + 1..9, 0 moves active window to workspace 1..10.

for i = 1, 10 do
    local key = (i == 10) and "0" or tostring(i)
    hl.bind(MOD .. " + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind(MOD .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Relative workspace switching
hl.bind(MOD .. " + Page_Down", hl.dsp.focus({ workspace = "+1" }))
hl.bind(MOD .. " + Page_Up",   hl.dsp.focus({ workspace = "-1" }))
hl.bind(MOD .. " + SHIFT + Page_Down", hl.dsp.window.move({ workspace = "+1" }))
hl.bind(MOD .. " + SHIFT + Page_Up",   hl.dsp.window.move({ workspace = "-1" }))

-- --- mouse -----------------------------------------------------------------
--
-- Mouse drag and resize windows (like GrajAP: mouse:272 drag, mouse:273 resize)
hl.bind(MOD .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(MOD .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.bind(MOD .. " + mouse_down", hl.dsp.focus({ workspace = "+1" }))
hl.bind(MOD .. " + mouse_up",   hl.dsp.focus({ workspace = "-1" }))
hl.bind(MOD .. " + CTRL + mouse_down", hl.dsp.window.move({ workspace = "+1" }))
hl.bind(MOD .. " + CTRL + mouse_up",   hl.dsp.window.move({ workspace = "-1" }))

hl.bind(MOD .. " + mouse_right", hl.dsp.focus({ direction = "right" }))
hl.bind(MOD .. " + mouse_left",  hl.dsp.focus({ direction = "left" }))
hl.bind(MOD .. " + CTRL + mouse_right", hl.dsp.window.move({ direction = "right" }))
hl.bind(MOD .. " + CTRL + mouse_left",  hl.dsp.window.move({ direction = "left" }))
hl.bind(MOD .. " + SHIFT + mouse_right", hl.dsp.layout("focus r"))
hl.bind(MOD .. " + SHIFT + mouse_left",  hl.dsp.layout("focus l"))

-- --- screenshots -----------------------------------------------------------
--
-- Print and SHIFT+S both open the toolkit island (Full / Area / Window /
-- Close) rather than jumping straight into a picker — going direct to `area`
-- silently shows nothing when the area picker cannot start, which reads as a
-- dead key.

hl.bind("Print", hl.dsp.exec_cmd("lenin-screenshot"))
hl.bind(MOD .. " + SHIFT + S", hl.dsp.exec_cmd("lenin-screenshot"))
hl.bind(MOD .. " + SHIFT + W", hl.dsp.exec_cmd("lenin-screenshot fullscreen"))
hl.bind(MOD .. " + SHIFT + A", hl.dsp.exec_cmd("lenin-screenshot window"))

-- --- misc ------------------------------------------------------------------

-- niri's toggle-overview has no Hyprland equivalent; the scratchpad (special
-- workspace) is the closest "park a window out of the way" primitive.
hl.bind(MOD .. " + O", hl.dsp.workspace.toggle_special())
hl.bind(MOD .. " + TAB", hl.dsp.workspace.toggle_special("float"))

hl.bind(MOD .. " + SHIFT + P", hl.dsp.dpms({ action = "toggle" }))

-- Emergency recovery for a stuck layer surface (quickshell island holding
-- Exclusive focus): kills the shell so all grabs die with it, releases any
-- input capture, refocuses windows, and restarts leninshell.
hl.bind(MOD .. " + CTRL + SHIFT + R", hl.dsp.exec_cmd("sh -c 'pkill -9 -f leninshell; pkill -9 -f quickshell; hyprctl dispatch release_input_capture; hyprctl dispatch cyclenext; uwsm app -- leninshell &'"))

-- niri's Mod+Escape toggled the keyboard-shortcuts inhibitor. Hyprland manages
-- that automatically, so the binding is deliberately absent and ESC is left to
-- the focused client.

-- hyprlock is not used: the leninshell lock screen (WlSessionLock + PAM) is
-- bound to SUPER+ALT+L above and is also driven by the backend's idle manager.

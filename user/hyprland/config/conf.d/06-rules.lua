-- ---------------------------------------------------------------------------
-- 06-rules.lua
--
-- Ported from the niri `window-rule` / `layer-rule` blocks.
--
-- The workspace pinning rules live in 07-apps-to-workspaces.lua, which is
-- generated from the `hyprland.workspaceBindings` Nix option.
-- ---------------------------------------------------------------------------

-- --- window rules -----------------------------------------------------------

-- niri: window-rule { match app-id="com.github.flxzt.rnote"; open-maximized true }
hl.window_rule({
    name  = "rnote-maximized",
    match = { class = "^com%.github%.flxzt%.rnote$" },
    maximize = true,
})

-- Hyprland's rule API can only *remove* effects, never add them, so niri's
-- "blur kitty only" rule becomes "blur everything, then opt out". Keeping the
-- deny list short matters: every blurred window costs a backdrop pass.
hl.window_rule({
    name  = "rnote-no-blur",
    match = { class = "^com%.github%.flxzt%.rnote$" },
    no_blur = true,
})

-- Portal dialogs (file chooser, screen-share picker) are short-lived modals.
-- Tiled, each one holds a workspace slot for as long as it is open, which is
-- backwards: they should float over whatever was focused before.
--
-- The gtk backend sets a class, but xdg-desktop-portal-hyprland's own chooser
-- sets none at all, so the screencast picker has to be matched on its title.
--
-- NOTE: unlike the permission rules further down, window-rule matching does not
-- accept the `%-` escape -- a rule using it silently never matches. Keep the
-- regexes here plain.
local function floating_dialog(name, match, size)
    hl.window_rule({
        name   = name,
        match  = match,
        float  = true,
        center = true,
        size   = size,
    })
end

-- The file chooser asks for a size that overflows the panel once it is floating
-- and centred, so it gets capped explicitly. The screencast picker sizes itself
-- sensibly and is left alone.
floating_dialog("portal-file-chooser", { class = "^xdg-desktop-portal-gtk$" }, "900 620")
floating_dialog("portal-screencast-picker", { title = "^Select what to share$" })

-- --- layer rules ------------------------------------------------------------
--
-- niri's `background-effect` blur is a compositor feature that Hyprland does
-- not implement for layer-shell surfaces, but Hyprland *does* blur layers. The
-- leninshell surfaces are fullscreen transparent windows with an opaque glass
-- panel in the middle, so `ignore_alpha` reproduces niri's blurRegion closely
-- enough: only the pixels the shell actually draws get frosted.

-- NOTE: the lock screen is a WlSessionLockSurface, not a layer-shell surface,
-- so it has no namespace to match on and cannot be styled by a layer rule.
-- The shell draws its own wallpaper behind it, so there is nothing to do.

local function glass_layer(name, namespace)
    hl.layer_rule({
        name        = name,
        match       = { namespace = namespace },
        blur        = true,
        ignore_alpha = 0.01,
        xray        = false,
        no_anim     = true,
    })
end

glass_layer("dock-blur",            "^quickshell%-dock$")
glass_layer("launcher-blur",        "^quickshell%-launcher$")
glass_layer("keepass-blur",         "^quickshell%-keepass$")
glass_layer("screenshot-editor-blur", "^quickshell%-screenshot%-editor$")
glass_layer("fullscreen-media",     "^fullscreen_media$")
glass_layer("rsvp-reader",          "^rsvp_reader$")

-- Lyrics are drawn straight onto the wallpaper; blurring them would blur the
-- text itself, and they must not leak into screen shares.
hl.layer_rule({
    name            = "lyrics-desktop",
    match           = { namespace = "^lyrics_desktop$" },
    no_anim         = true,
    no_screen_share = true,
})

-- --- screenshot permissions -------------------------------------------------
--
-- Hyprland gates screencopy behind `ecosystem:enforce_permissions`, and
-- anything without an explicit rule gets asked about — which, with no
-- permission agent running, means silently denied. So the capture tools this
-- setup actually uses are allowed explicitly, and the password vaults are
-- denied outright: the same intent as niri's `block-out-from "screen-capture"`.
--
-- NOTE: unlike most of this file, permission rules need a Hyprland restart and
-- are matched against the client's binary path.
--
-- Extend the allow list when adding a new screen recorder or capture tool.

local ALLOW_SCREENCOPY = {
    "grim",
    "wf%-recorder",
    "wl%-screenrec",
    "hyprshot",
    "ffmpeg",
    "obs",
    "wayvnc",
    "xdg%-desktop%-portal%-hyprland",
    "xdg%-desktop%-portal%-gnome",
    "gnome%-screenshot",
    "flameshot",
    "spectacle",
    "kooha",
}

for _, bin in ipairs(ALLOW_SCREENCOPY) do
    hl.permission("/.*/" .. bin .. "$", "screencopy", "allow")
end

for _, bin in ipairs({ "keepassxc", "seahorse", "gnome%-passwords" }) do
    hl.permission("/.*/" .. bin .. "$", "screencopy", "deny")
end

-- Input capture / virtual input devices: the backends of these tools.
for _, bin in ipairs({ "ydotool", "wtype", "wob", "dotool", "freerdp", "Remmina" }) do
    hl.permission("/.*/" .. bin .. "$", "input-capture", "allow")
end
for _, bin in ipairs({ "ydotool", "wtype", "dotool" }) do
    hl.permission("/.*/" .. bin .. "$", "keyboard", "allow")
end

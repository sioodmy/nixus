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
    match = { class = "^com\\.github\\.flxzt\\.rnote$" },
    maximize = true,
})

-- Hyprland's rule API can only *remove* effects, never add them, so niri's
-- "blur kitty only" rule becomes "blur everything, then opt out". Keeping the
-- deny list short matters: every blurred window costs a backdrop pass.
hl.window_rule({
    name  = "rnote-no-blur",
    match = { class = "^com\\.github\\.flxzt\\.rnote$" },
    no_blur = true,
})

-- Portal dialogs (file chooser, screen-share picker) are short-lived modals.
-- Tiled, each one holds a workspace slot for as long as it is open, which is
-- backwards: they should float over whatever was focused before.
--
-- The gtk backend sets a class, but xdg-desktop-portal-hyprland's own chooser
-- sets none at all, so the screencast picker has to be matched on its title.
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
-- Aero glass is blurred only where the layer actually draws pixels.
local function glass_layer(name, namespace)
    hl.layer_rule({
        name = name,
        match = { namespace = namespace },
        blur = true,
        ignore_alpha = 0.01,
        xray = false,
        no_anim = true,
    })
end

glass_layer("amethyst-panel", "^amethyst-bar$")
glass_layer("amethyst-flyout", "^amethyst-flyout$")
glass_layer("amethyst-notifications", "^amethyst-notifications$")
glass_layer("amethyst-osd", "^amethyst-osd$")

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
    "wf-recorder",
    "wl-screenrec",
    "hyprshot",
    "ffmpeg",
    "obs",
    "wayvnc",
    "xdg-desktop-portal-hyprland",
    "xdg-desktop-portal-gnome",
    "gnome-screenshot",
    "flameshot",
    "spectacle",
    "kooha",
}

for _, bin in ipairs(ALLOW_SCREENCOPY) do
    hl.permission("/.*/" .. bin .. "$", "screencopy", "allow")
end

for _, bin in ipairs({ "keepassxc", "seahorse", "gnome-passwords" }) do
    hl.permission("/.*/" .. bin .. "$", "screencopy", "deny")
end

-- Input capture / virtual input devices: the backends of these tools.
for _, bin in ipairs({ "ydotool", "wtype", "wob", "dotool", "freerdp", "Remmina" }) do
    hl.permission("/.*/" .. bin .. "$", "input-capture", "allow")
end
for _, bin in ipairs({ "ydotool", "wtype", "dotool" }) do
    hl.permission("/.*/" .. bin .. "$", "keyboard", "allow")
end

-- Plugins. `ecosystem:enforce_permissions` gates dlopen too, and a
-- config-loaded plugin is matched against its *path* or the caller binary
-- ("config"). The store paths change on every version bump, so allow the shape:
-- anything under /nix/store ending in .so, as well as config-loaded plugins.
--
-- Needs a Hyprland restart when added, same as the rules above.
hl.permission("/nix/store/.*\\.so", "plugin", "allow")
hl.permission("config", "plugin", "allow")

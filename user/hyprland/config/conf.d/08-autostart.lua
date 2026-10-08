-- ---------------------------------------------------------------------------
-- 08-autostart.lua
--
-- Ported from niri's `spawn-at-startup` block.
-- ---------------------------------------------------------------------------

hl.on("hyprland.start", function()
    -- Clipboard history — the launcher and org-mode agenda read from cliphist.
    hl.exec_cmd("wl-paste --watch cliphist store")

    -- Wallpaper. swaybg works on any layer-shell compositor; hyprpaper is not
    -- used so the wallpaper survives compositor swaps.
    hl.exec_cmd("swaybg -i /home/sioodmy/dev/wallpapers/misc/totoro1.jpeg")

    -- The shell: dock, dynamic island, launcher, lock screen, notifications,
    -- clipboard UI, screenshots, polkit agent, KeePass, music remote.
    --
    -- It is a systemd user unit (user/quickshell) rather than a bare exec, so
    -- `systemctl --user restart quickshell` picks up a new build without
    -- touching the session, and so a crash brings it back instead of leaving
    -- the session without a lock screen. Started from here rather than from
    -- graphical-session.target because that target is up before Hyprland is,
    -- and quickshell needs the display to already exist. `start` is idempotent,
    -- so running it again after a `systemctl --user enable --now` is a no-op.
    hl.exec_cmd("systemctl --user start quickshell.service")
end)

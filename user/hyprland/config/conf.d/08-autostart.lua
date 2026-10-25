-- Export the actual display before starting any user service. The graphical
-- session target exists before Hyprland does, so it cannot supply these.
hl.on("hyprland.start", function()
    hl.exec_cmd("hyprctl setcursor Amethyst-Aero-Cursors 24")
    hl.exec_cmd("wl-paste --watch cliphist store")
    hl.exec_cmd("sh -c 'systemctl --user import-environment WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE XDG_CURRENT_DESKTOP XDG_SESSION_TYPE DISPLAY; dbus-update-activation-environment --systemd WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE XDG_CURRENT_DESKTOP XDG_SESSION_TYPE DISPLAY; systemctl --user start quickshell.service aero-wallpaper.service aero-bluetooth-agent.service hypridle.service'")
end)

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland

Singleton {
    property string page: ""
    property string screenName: ""
    property bool doNotDisturb: false
    readonly property bool preview: Quickshell.env("AERO_PREVIEW") === "1"
    function open(name, screen) {
        screenName = screen || Hyprland.focusedMonitor?.name || Quickshell.screens[0]?.name || "";
        page = name;
    }
    function toggle(name, screen) {
        if (page === name && (!screen || screenName === screen))
            close();
        else
            open(name, screen);
    }
    function close() {
        page = "";
    }
    function spawn(args, workingDirectory) {
        // Apps get their own cgroups, so restarting the shell leaves them alive.
        var command = preview ? args : ["systemd-run", "--user", "--scope", "--quiet", "--collect", "--slice=app.slice", "--"].concat(args);
        Quickshell.execDetached({
            command: command,
            workingDirectory: workingDirectory || Quickshell.env("HOME")
        });
    }
    function run(args) {
        spawn(args);
        close();
    }
    function lock() {
        if (!preview) {
            Quickshell.execDetached(["aero-lock"]);
            close();
        }
    }
}

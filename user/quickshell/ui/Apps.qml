pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "Search.js" as Search

Singleton {
    id: root
    // DesktopEntries indexes and watches .desktop files in native C++ once.
    readonly property var indexed: Search.index(DesktopEntries.applications.values)
    property var usage: ({})
    readonly property var pins: [
        {
            id: "kitty",
            fallback: "utilities-terminal",
            label: "Terminal",
            command: ["kitty"]
        },
        {
            id: "zen-aero",
            fallback: "internet-web-browser",
            label: "Internet",
            command: ["zen"]
        },
        {
            id: "nemo",
            fallback: "folder-violet",
            label: "Pliki",
            command: ["nemo"]
        },
        {
            id: "signal",
            fallback: "kopete",
            label: "Wiadomości",
            command: ["signal-desktop"]
        }
    ]
    FileView {
        id: history
        printErrors: false
        path: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/amethyst-aero/usage.json"
        onLoaded: {
            try {
                root.usage = JSON.parse(text());
            } catch (_) {
                root.usage = ({});
            }
        }
        onLoadFailed: root.usage = ({})
    }
    Timer {
        id: save
        interval: 750
        onTriggered: history.setText(JSON.stringify(root.usage))
    }
    function search(query) {
        return Search.search(query, indexed, usage, 60);
    }
    function launch(entry) {
        var next = Object.assign({}, usage);
        next[entry.id] = (next[entry.id] || 0) + 1;
        usage = next;
        save.restart();
        Desktop.spawn(entry.runInTerminal ? ["kitty"].concat(entry.command) : entry.command, entry.workingDirectory);
        Desktop.close();
    }
    function pinned(pin) {
        return DesktopEntries.heuristicLookup(pin.id);
    }
    function pinMatches(pin, window) {
        var appId = window.appId.toLowerCase();
        if (!appId)
            return false;
        var entry = pinned(pin);
        return appId === (entry?.startupClass || "").toLowerCase() || appId.includes(pin.id.toLowerCase());
    }
    function launchPin(pin) {
        var entry = pinned(pin);
        if (entry)
            launch(entry);
        else
            Desktop.run(pin.command);
    }
}

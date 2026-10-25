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
    function iconName(entry, appId) {
        // Prefer a themed basename even if a desktop file supplies an absolute
        // store path. Entries without Icon= can still resolve by desktop ID/name.
        const candidates = [entry?.icon, entry?.id, appId, entry?.startupClass, entry?.name?.toLowerCase()];
        for (let candidate of candidates) {
            if (!candidate)
                continue;
            candidate = candidate.split("/").pop().replace(/\.(desktop|svg|png|xpm)$/i, "");
            if (Quickshell.hasThemeIcon(candidate))
                return candidate;
        }
        return "application-x-executable";
    }
}

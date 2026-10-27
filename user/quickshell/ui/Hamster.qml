pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

Singleton {
    id: root
    property var items: []
    property var position: ({x: 0.88, y: 0.84, screen: ""})
    property string error: ""
    property string notice: ""
    property bool ready: false
    property bool busy: false
    property bool sharing: false
    property string url: ""
    property double expires: 0
    property bool panelOpen: false
    property bool hidden: false
    property var selected: []
    readonly property bool enabled: Quickshell.env("AERO_HAMSTER") !== "0"
    readonly property var output: Quickshell.screens.find(s => s.name === position.screen) || Quickshell.screens[0] || null
    signal fed(string reaction)
    signal musicStarted()
    readonly property bool musicIsPlaying: Mpris.players.values.some(player => player.isPlaying)

    function send(data) {
        if (!ready) {
            error = "Chomik jeszcze się budzi. Spróbuj za chwilę.";
            return;
        }
        backend.write(JSON.stringify(data) + "\n");
    }
    function add(urls) {
        send({action: "add", urls: urls.map(url => url.toString()), reaction: "drop"});
    }
    function screenshot(path) {
        send({action: "add", urls: [path], reaction: "screenshot"});
    }
    function toggleSelected(id) {
        selected = selected.indexOf(id) === -1 ? selected.concat([id]) : selected.filter(value => value !== id);
    }
    function share() {
        if (!ready || busy) return;
        busy = true;
        send({action: "share", ids: selected.length ? selected : items.filter(item => item.available).map(item => item.id), minutes: 15});
    }
    function move(x, y, screen) {
        position = {x: x, y: y, screen: screen};
        send({action: "position", x: x, y: y, screen: screen});
    }
    function nextScreen() {
        const index = Quickshell.screens.indexOf(output);
        move(position.x, position.y, Quickshell.screens[(index + 1) % Quickshell.screens.length].name);
    }
    function toggle() {
        hidden = false;
        panelOpen = !panelOpen;
        if (panelOpen) send({action: "refresh"});
    }
    function sizeLabel(bytes) {
        if (bytes < 1024) return bytes + " B";
        if (bytes < 1048576) return (bytes / 1024).toFixed(1) + " KB";
        if (bytes < 1073741824) return (bytes / 1048576).toFixed(1) + " MB";
        return (bytes / 1073741824).toFixed(1) + " GB";
    }
    Process {
        id: backend
        command: ["python3", "-u", decodeURIComponent(Qt.resolvedUrl("hamster.py").toString().replace(/^file:\/\//, ""))]
        running: root.enabled
        stdinEnabled: true
        stdout: SplitParser {
            onRead: data => {
                try {
                    const state = JSON.parse(data);
                    root.items = state.items;
                    root.position = state.position;
                    root.error = state.error;
                    root.notice = state.notice;
                    root.sharing = state.sharing;
                    root.url = state.url;
                    root.expires = state.expires;
                    root.ready = true;
                    root.busy = false;
                    root.selected = root.selected.filter(id => state.items.some(item => item.id === id));
                    if (state.reaction) root.fed(state.reaction);
                } catch (error) {
                    console.warn("Hamster state:", error);
                }
            }
        }
        stderr: SplitParser { onRead: data => console.warn("Hamster:", data) }
        onExited: {
            root.ready = false;
            root.busy = false;
            root.sharing = false;
            root.url = "";
            root.error = "Chomik zasnął. Kliknij Obudź, żeby spróbować ponownie.";
        }
    }
    Connections {
        target: root
        function onMusicIsPlayingChanged() {
            if (root.musicIsPlaying) root.musicStarted();
        }
    }
    function wake() { if (!backend.running) backend.running = true; }
}

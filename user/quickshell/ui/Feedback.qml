pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Pipewire

Singleton {
    id: root
    property bool active: false
    property string kind: "volume"
    property int percent: 0
    property bool muted: false
    property string outputName: ""
    property bool ready: false
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property string label: kind === "brightness" ? "Jasność ekranu" : kind === "microphone" ? "Mikrofon" : "Głośność"
    readonly property string icon: kind === "brightness" ? "weather-clear" : kind === "microphone" ? "audio-input-microphone" : muted || percent === 0 ? "audio-volume-muted" : percent < 35 ? "audio-volume-low" : percent < 70 ? "audio-volume-medium" : "audio-volume-high"
    function show(type, value, isMuted) {
        if (["volume", "brightness", "microphone"].indexOf(type) === -1)
            return;
        kind = type;
        percent = Math.max(0, Math.min(150, Math.round(value)));
        muted = isMuted;
        outputName = Hyprland.focusedMonitor?.name || Quickshell.screens[0]?.name || "";
        active = true;
        dismiss.restart();
    }
    function audioChanged(node, type) {
        if (ready && node?.audio)
            show(type, node.audio.volume * 100, node.audio.muted);
    }
    PwObjectTracker {
        objects: [root.sink, root.source].filter(node => !!node)
    }
    Connections {
        target: root.sink?.audio ?? null
        function onVolumeChanged() {
            root.audioChanged(root.sink, "volume");
        }
        function onMutedChanged() {
            root.audioChanged(root.sink, "volume");
        }
    }
    Connections {
        target: root.source?.audio ?? null
        function onMutedChanged() {
            root.audioChanged(root.source, "microphone");
        }
    }
    Timer {
        interval: 1500
        running: true
        onTriggered: root.ready = true
    }
    Timer {
        id: dismiss
        interval: 1700
        onTriggered: root.active = false
    }
}

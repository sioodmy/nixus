import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris

ColumnLayout {
    id: root
    spacing: 12
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property var player: Mpris.players.values[0] || null
    PwObjectTracker {
        objects: [root.sink, root.source].filter(n => !!n)
    }
    AeroText {
        text: "Głośność"
        font.pixelSize: 15
    }
    AeroText {
        Layout.fillWidth: true
        text: root.sink?.description || "Brak wyjścia audio"
        color: Theme.muted
    }
    RowLayout {
        Layout.fillWidth: true
        AeroButton {
            iconName: root.sink?.audio?.muted ? "audio-volume-muted" : "audio-volume-high"
            hint: "Wycisz / włącz dźwięk"
            enabled: !!root.sink?.audio
            selected: !!root.sink?.audio?.muted
            onClicked: root.sink.audio.muted = !root.sink.audio.muted
        }
        AeroSlider {
            Layout.fillWidth: true
            from: 0
            to: 1
            value: root.sink?.audio?.volume || 0
            enabled: !!root.sink?.audio
            onMoved: root.sink.audio.volume = value
        }
        AeroText {
            text: Math.round((root.sink?.audio?.volume || 0) * 100) + "%"
            Layout.preferredWidth: 40
        }
    }
    AeroButton {
        Layout.fillWidth: true
        text: root.source?.audio?.muted ? "Mikrofon wyciszony" : "Wycisz mikrofon"
        iconName: "audio-input-microphone"
        selected: !!root.source?.audio?.muted
        enabled: !!root.source?.audio
        onClicked: root.source.audio.muted = !root.source.audio.muted
    }
    AeroButton {
        Layout.fillWidth: true
        text: "Urządzenia i głośność aplikacji"
        iconName: "multimedia-volume-control"
        onClicked: Desktop.run(["pwvucontrol"])
    }
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 1
        color: Theme.alpha(Theme.highlight, 0.2)
    }
    AeroText {
        text: "Jasność ekranu"
        font.pixelSize: 15
    }
    RowLayout {
        Layout.fillWidth: true
        AeroButton {
            text: "−"
            hint: "Zmniejsz jasność"
            onClicked: Quickshell.execDetached(["aero-brightness", "5%-"])
        }
        AeroButton {
            Layout.fillWidth: true
            text: "50%"
            onClicked: Quickshell.execDetached(["aero-brightness", "50%"])
        }
        AeroButton {
            text: "+"
            hint: "Zwiększ jasność"
            onClicked: Quickshell.execDetached(["aero-brightness", "5%+"])
        }
    }
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 1
        color: Theme.alpha(Theme.highlight, 0.2)
    }
    ColumnLayout {
        visible: !!root.player
        Layout.fillWidth: true
        spacing: 10
        AeroText {
            Layout.fillWidth: true
            text: root.player?.trackTitle || "Odtwarzacz"
            font.pixelSize: 16
        }
        AeroText {
            Layout.fillWidth: true
            text: root.player?.trackArtist || root.player?.identity || ""
            color: Theme.muted
        }
        RowLayout {
            AeroButton {
                iconName: "media-skip-backward"
                hint: "Poprzedni utwór"
                enabled: !!root.player?.canGoPrevious
                onClicked: root.player.previous()
            }
            AeroButton {
                text: "Odtwórz / pauza"
                iconName: "media-playback-start"
                enabled: !!root.player?.canTogglePlaying
                onClicked: root.player.togglePlaying()
            }
            AeroButton {
                iconName: "media-skip-forward"
                hint: "Następny utwór"
                enabled: !!root.player?.canGoNext
                onClicked: root.player.next()
            }
        }
    }
    Item {
        Layout.fillHeight: true
    }
}

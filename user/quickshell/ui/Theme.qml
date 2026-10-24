pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    FileView {
        id: file
        path: Qt.resolvedUrl("palette.json")
        blockLoading: true
    }
    readonly property var palette: JSON.parse(file.text())
    readonly property color background: palette.background
    readonly property color surface: palette.surface
    readonly property color raised: palette.raised
    readonly property color edge: palette.edge
    readonly property color accent: palette.accent
    readonly property color highlight: palette.highlight
    readonly property color text: palette.text
    readonly property color muted: palette.muted
    readonly property color green: palette.green
    readonly property color red: palette.red
    readonly property string font: "Segoe UI"
    readonly property bool reducedMotion: Quickshell.env("AERO_REDUCED_MOTION") === "1"
    readonly property bool rightPanel: Quickshell.env("AERO_PANEL_SIDE") === "right"
    readonly property url wallpaper: Qt.resolvedUrl("assets/wallpaper.png")
    readonly property int duration: reducedMotion ? 0 : 110
    function alpha(color, opacity) {
        return Qt.rgba(color.r, color.g, color.b, opacity);
    }
}

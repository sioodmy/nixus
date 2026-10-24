import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets

PanelWindow {
    id: root
    required property string outputName
    visible: Feedback.active && Feedback.outputName === outputName
    anchors.top: true
    margins.top: 38
    implicitWidth: 340
    implicitHeight: 88
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    mask: Region {}
    WlrLayershell.namespace: "amethyst-osd"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    Glass {
        anchors.fill: parent
        raised: true
        RowLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 14
            Rectangle {
                Layout.preferredWidth: 48
                Layout.preferredHeight: 48
                radius: 24
                border.color: Theme.alpha(Theme.highlight, 0.65)
                gradient: Gradient {
                    GradientStop {
                        position: 0
                        color: "#c4a2db"
                    }
                    GradientStop {
                        position: 0.47
                        color: "#70518b"
                    }
                    GradientStop {
                        position: 0.49
                        color: "#392448"
                    }
                    GradientStop {
                        position: 1
                        color: "#8d65ab"
                    }
                }
                IconImage {
                    anchors.centerIn: parent
                    implicitSize: 27
                    source: Quickshell.iconPath(Feedback.icon)
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 9
                RowLayout {
                    Layout.fillWidth: true
                    AeroText {
                        Layout.fillWidth: true
                        text: Feedback.label
                        font.pixelSize: 14
                    }
                    AeroText {
                        text: Feedback.muted ? "Wyciszono" : Feedback.percent + "%"
                        color: Feedback.muted ? Theme.muted : Theme.highlight
                        font.pixelSize: 13
                    }
                }
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 13
                    radius: 4
                    color: Theme.background
                    border.color: Theme.edge
                    Rectangle {
                        anchors {
                            left: parent.left
                            top: parent.top
                            bottom: parent.bottom
                            margins: 2
                        }
                        width: (parent.width - 4) * (Feedback.muted ? 0 : Math.min(Feedback.percent, 100) / 100)
                        radius: 2
                        gradient: Gradient {
                            GradientStop {
                                position: 0
                                color: "#ecd9ff"
                            }
                            GradientStop {
                                position: 0.45
                                color: "#b28dd2"
                            }
                            GradientStop {
                                position: 0.5
                                color: "#76518f"
                            }
                            GradientStop {
                                position: 1
                                color: "#be9aef"
                            }
                        }
                        Behavior on width {
                            NumberAnimation {
                                duration: Theme.duration
                            }
                        }
                    }
                }
            }
        }
    }
}

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
    id: root
    required property string outputName
    visible: Desktop.page !== "" && Desktop.screenName === outputName
    anchors {
        left: !Theme.rightPanel
        right: Theme.rightPanel
        top: Desktop.page === "launcher"
        bottom: Desktop.page !== "launcher"
    }
    margins {
        left: Theme.barWidth + 6
        right: Theme.barWidth + 6
        bottom: 12
        top: 12
    }
    implicitWidth: Math.min(Desktop.page === "launcher" ? 620 : 440, screen.width - 100)
    implicitHeight: Math.min(Desktop.page === "launcher" ? 560 : 580, screen.height - 32)
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: "amethyst-flyout"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    HyprlandFocusGrab {
        windows: [root]
        active: root.visible && !Desktop.preview
        onCleared: if (root.visible)
            Qt.callLater(Desktop.close)
    }
    Glass {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: Desktop.close()
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12
            RowLayout {
                Layout.fillWidth: true
                AeroText {
                    Layout.fillWidth: true
                    font.pixelSize: 17
                    text: ({
                            launcher: "Start",
                            wifi: "Sieć i Wi-Fi",
                            bluetooth: "Bluetooth",
                            audio: "Dźwięk i jasność",
                            notifications: "Powiadomienia",
                            session: "Twój pulpit"
                        })[Desktop.page] || "Amethyst Aero"
                }
                AeroButton {
                    implicitWidth: 28
                    implicitHeight: 25
                    iconName: "window-close"
                    iconSize: 14
                    hint: "Zamknij · Esc"
                    onClicked: Desktop.close()
                }
            }
            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 0
                Layout.minimumWidth: 0
                currentIndex: Math.max(0, ["launcher", "wifi", "bluetooth", "audio", "notifications", "session"].indexOf(Desktop.page))
                Launcher {}
                NetworkView {}
                BluetoothView {}
                AudioView {}
                NotificationView {}
                SessionView {}
            }
            RowLayout {
                visible: Desktop.page !== "launcher"
                Layout.fillWidth: true
                spacing: 5
                Repeater {
                    model: [
                        {
                            page: "wifi",
                            icon: "network-wireless",
                            label: "Wi-Fi"
                        },
                        {
                            page: "bluetooth",
                            icon: "preferences-system-bluetooth",
                            label: "Bluetooth"
                        },
                        {
                            page: "audio",
                            icon: "audio-volume-high",
                            label: "Dźwięk"
                        },
                        {
                            page: "notifications",
                            icon: "preferences-desktop-notification",
                            label: "Powiadomienia"
                        },
                        {
                            page: "session",
                            icon: "system-shutdown",
                            label: "Sesja"
                        }
                    ]
                    AeroButton {
                        required property var modelData
                        Layout.fillWidth: true
                        implicitWidth: 35
                        iconName: modelData.icon
                        hint: modelData.label
                        selected: Desktop.page === modelData.page
                        onClicked: Desktop.page = modelData.page
                    }
                }
            }
        }
    }
}

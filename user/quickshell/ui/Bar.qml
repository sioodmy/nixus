import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Networking
import Quickshell.Bluetooth

PanelWindow {
    id: root
    anchors {
        top: true
        bottom: true
        left: !Theme.rightPanel
        right: Theme.rightPanel
    }
    implicitWidth: Theme.barWidth
    exclusiveZone: implicitWidth
    color: "transparent"
    WlrLayershell.namespace: "amethyst-bar"
    WlrLayershell.layer: WlrLayer.Top
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Glass {
        anchors.fill: parent
        anchors.margins: 4
        radius: 10
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 4
            spacing: 4
            AeroButton {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: 38
                implicitHeight: 40
                orb: true
                iconSize: 26
                iconName: "start-here"
                hint: "Start · Super+P"
                selected: Desktop.page === "launcher"
                onClicked: Desktop.toggle("launcher", root.screen.name)
            }
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Theme.alpha(Theme.highlight, 0.2)
            }
            TaskList {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 40
                outputName: root.screen.name
            }
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Theme.alpha(Theme.highlight, 0.2)
            }
            AeroButton {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: 36
                implicitHeight: 28
                iconSize: 18
                iconName: Networking.wifiEnabled ? "network-wireless" : "network-offline"
                hint: "Sieć i Wi-Fi"
                selected: Desktop.page === "wifi"
                onClicked: Desktop.toggle("wifi", root.screen.name)
            }
            AeroButton {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: 36
                implicitHeight: 28
                iconSize: 18
                iconName: "preferences-system-bluetooth"
                hint: "Bluetooth"
                selected: Desktop.page === "bluetooth"
                onClicked: Desktop.toggle("bluetooth", root.screen.name)
            }
            AeroButton {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: 36
                implicitHeight: 28
                iconSize: 18
                iconName: "audio-volume-high"
                hint: "Dźwięk i jasność"
                selected: Desktop.page === "audio"
                onClicked: Desktop.toggle("audio", root.screen.name)
            }
            AeroButton {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: 36
                implicitHeight: 28
                iconSize: 18
                iconName: Desktop.doNotDisturb ? "notifications-disabled" : "preferences-desktop-notification"
                hint: "Powiadomienia (" + Notices.count + ")"
                selected: Desktop.page === "notifications"
                onClicked: Desktop.toggle("notifications", root.screen.name)
                Rectangle {
                    visible: Notices.count > 0
                    width: 7
                    height: 7
                    radius: 4
                    anchors {
                        top: parent.top
                        right: parent.right
                        margins: 4
                    }
                    color: Theme.green
                }
            }
            BatteryIndicator {
                Layout.alignment: Qt.AlignHCenter
                selected: Desktop.page === "session"
                onClicked: Desktop.toggle("session", root.screen.name)
            }
            AeroButton {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: 36
                implicitHeight: 40
                leftPadding: 4
                rightPadding: 4
                text: Qt.formatDateTime(clock.date, "HH\nmm")
                hint: Qt.formatDateTime(clock.date, "dddd, d MMMM yyyy")
                onClicked: Desktop.toggle("session", root.screen.name)
            }
            AeroButton {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: 36
                implicitHeight: 28
                iconSize: 18
                iconName: "system-shutdown"
                hint: "Zablokuj / zasilanie"
                onClicked: Desktop.toggle("session", root.screen.name)
            }
        }
    }
}

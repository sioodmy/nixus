import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Networking
import Quickshell.Bluetooth
import Quickshell.Services.UPower
import Quickshell.Services.SystemTray

PanelWindow {
    id: root
    anchors {
        top: true
        bottom: true
        left: !Theme.rightPanel
        right: Theme.rightPanel
    }
    implicitWidth: 76
    exclusiveZone: 76
    color: "transparent"
    WlrLayershell.namespace: "amethyst-bar"
    WlrLayershell.layer: WlrLayer.Top
    readonly property var monitor: Hyprland.monitorFor(screen)
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Glass {
        anchors.fill: parent
        anchors.margins: 7
        radius: 10
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 5
            spacing: 7
            AeroButton {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: 48
                implicitHeight: 48
                orb: true
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
            Repeater {
                model: Apps.pins
                AeroButton {
                    id: pinButton
                    required property var modelData
                    readonly property var windows: ToplevelManager.toplevels.values.filter(w => Apps.pinMatches(modelData, w))
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: 46
                    implicitHeight: 45
                    iconSize: 30
                    iconName: modelData.fallback
                    hint: modelData.label
                    selected: windows.some(w => w.activated)
                    onClicked: {
                        if (!windows.length)
                            Apps.launchPin(modelData);
                        else
                            windows[(windows.indexOf(ToplevelManager.activeToplevel) + 1) % windows.length].activate();
                    }
                    Rectangle {
                        visible: pinButton.windows.length > 0
                        anchors {
                            left: parent.left
                            verticalCenter: parent.verticalCenter
                        }
                        width: 3
                        height: 20
                        radius: 2
                        color: Theme.highlight
                    }
                }
            }
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Theme.alpha(Theme.highlight, 0.2)
            }
            // Workspaces remain reachable on short laptop displays.
            GridLayout {
                Layout.alignment: Qt.AlignHCenter
                columns: 2
                columnSpacing: 3
                rowSpacing: 3
                Repeater {
                    model: [1, 2, 3, 4, 5, 6]
                    AeroButton {
                        required property int modelData
                        implicitWidth: 22
                        implicitHeight: 26
                        leftPadding: 0
                        rightPadding: 0
                        text: String(modelData)
                        hint: "Pulpit " + modelData
                        selected: root.monitor?.activeWorkspace?.id === modelData
                        onClicked: {
                            if (Hyprland.usingLua)
                                Hyprland.dispatch("hl.dsp.focus({workspace=" + modelData + "})");
                            else
                                Hyprland.dispatch("workspace " + modelData);
                        }
                    }
                }
            }
            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 0
                Layout.maximumHeight: Math.min(count * 44, 132)
                clip: true
                spacing: 4
                model: {
                    var seen = ({});
                    return ToplevelManager.toplevels.values.filter(w => {
                        if (w.parent || seen[w.appId] || Apps.pins.some(p => Apps.pinMatches(p, w)))
                            return false;
                        seen[w.appId] = true;
                        return true;
                    });
                }
                delegate: AeroButton {
                    required property var modelData
                    width: ListView.view.width
                    implicitHeight: 40
                    iconSize: 26
                    iconName: DesktopEntries.heuristicLookup(modelData.appId)?.icon || "application-x-executable"
                    hint: modelData.title
                    selected: modelData.activated
                    onClicked: modelData.activate()
                }
            }
            Item {
                Layout.fillHeight: true
                Layout.minimumHeight: 0
            }
            // AppIndicator menus are real D-Bus menus, including secondary actions.
            Repeater {
                model: SystemTray.items
                AeroButton {
                    id: trayButton
                    required property var modelData
                    Layout.alignment: Qt.AlignHCenter
                    implicitHeight: 29
                    implicitWidth: 42
                    iconSize: 20
                    hint: modelData.tooltipTitle || modelData.title
                    contentItem: Image {
                        source: trayButton.modelData.icon
                        sourceSize: Qt.size(20, 20)
                        fillMode: Image.PreserveAspectFit
                    }
                    onClicked: {
                        if (modelData.onlyMenu)
                            modelData.display(root, Theme.rightPanel ? 0 : root.width, trayButton.mapToItem(root.contentItem, 0, 0).y);
                        else
                            modelData.activate();
                    }
                    TapHandler {
                        acceptedButtons: Qt.RightButton
                        onTapped: trayButton.modelData.display(root, Theme.rightPanel ? 0 : root.width, trayButton.mapToItem(root.contentItem, 0, 0).y)
                    }
                }
            }
            AeroButton {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: 44
                implicitHeight: 32
                iconName: Networking.wifiEnabled ? "network-wireless" : "network-offline"
                hint: "Sieć i Wi-Fi"
                selected: Desktop.page === "wifi"
                onClicked: Desktop.toggle("wifi", root.screen.name)
            }
            AeroButton {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: 44
                implicitHeight: 32
                iconName: "preferences-system-bluetooth"
                hint: "Bluetooth"
                selected: Desktop.page === "bluetooth"
                onClicked: Desktop.toggle("bluetooth", root.screen.name)
            }
            AeroButton {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: 44
                implicitHeight: 32
                iconName: "audio-volume-high"
                hint: "Dźwięk i jasność"
                selected: Desktop.page === "audio"
                onClicked: Desktop.toggle("audio", root.screen.name)
            }
            AeroButton {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: 44
                implicitHeight: 32
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
            AeroText {
                visible: UPower.displayDevice.isLaptopBattery
                Layout.alignment: Qt.AlignHCenter
                text: Math.round(UPower.displayDevice.percentage * 100) + "%"
                color: UPower.onBattery ? Theme.muted : Theme.green
                font.pixelSize: 11
            }
            AeroButton {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: 46
                implicitHeight: 48
                text: Qt.formatDateTime(clock.date, "HH\nmm")
                hint: Qt.formatDateTime(clock.date, "dddd, d MMMM yyyy")
                onClicked: Desktop.toggle("session", root.screen.name)
            }
            AeroButton {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: 44
                implicitHeight: 30
                iconName: "system-shutdown"
                hint: "Zablokuj / zasilanie"
                onClicked: Desktop.toggle("session", root.screen.name)
            }
        }
    }
}

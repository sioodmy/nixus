import QtQuick
import QtQuick.Layouts
import Quickshell

ColumnLayout {
    id: root
    spacing: 12
    property string pending: ""
    onVisibleChanged: pending = ""
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
    AeroText {
        text: Qt.formatDateTime(clock.date, "HH:mm")
        font.pixelSize: 48
        Layout.alignment: Qt.AlignHCenter
    }
    AeroText {
        text: Qt.formatDateTime(clock.date, "dddd, d MMMM yyyy")
        color: Theme.muted
        Layout.alignment: Qt.AlignHCenter
    }
    RowLayout {
        visible: BatteryInfo.available
        Layout.fillWidth: true
        spacing: 14
        BatteryGauge {
            Layout.alignment: Qt.AlignVCenter
            level: BatteryInfo.level
            known: BatteryInfo.known
            charging: BatteryInfo.charging
            plugged: BatteryInfo.plugged
            low: BatteryInfo.low
            critical: BatteryInfo.critical
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4
            AeroText {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                elide: Text.ElideNone
                text: BatteryInfo.percentageText + " · " + BatteryInfo.stateText
                color: BatteryInfo.critical ? Theme.red : Theme.text
            }
            AeroText {
                visible: BatteryInfo.estimate !== ""
                text: BatteryInfo.estimate
                color: Theme.muted
                font.pixelSize: 12
            }
        }
    }
    Item {
        Layout.fillHeight: true
    }
    AeroButton {
        Layout.fillWidth: true
        implicitHeight: 48
        text: "Zablokuj ekran"
        iconName: "system-lock-screen"
        onClicked: Desktop.lock()
    }
    AeroButton {
        Layout.fillWidth: true
        text: "Uśpij"
        iconName: "system-suspend"
        onClicked: Desktop.run(["systemctl", "suspend"])
    }
    AeroButton {
        Layout.fillWidth: true
        text: "Uruchom ponownie"
        iconName: "system-reboot"
        onClicked: root.pending = "reboot"
    }
    AeroButton {
        Layout.fillWidth: true
        text: "Wyłącz komputer"
        iconName: "system-shutdown"
        onClicked: root.pending = "poweroff"
    }
    AeroButton {
        Layout.fillWidth: true
        text: "Wyloguj"
        iconName: "system-log-out"
        onClicked: root.pending = "logout"
    }
    RowLayout {
        visible: root.pending !== ""
        Layout.fillWidth: true
        AeroButton {
            Layout.fillWidth: true
            text: "Potwierdź"
            selected: true
            onClicked: {
                if (Desktop.preview) {
                    root.pending = "";
                    return;
                }
                if (root.pending === "logout")
                    Desktop.run(["hyprctl", "dispatch", "exit"]);
                else
                    Desktop.run(["systemctl", root.pending]);
            }
        }
        AeroButton {
            text: "Anuluj"
            onClicked: root.pending = ""
        }
    }
}

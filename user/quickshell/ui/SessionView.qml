import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower

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
    AeroText {
        visible: UPower.displayDevice.isLaptopBattery
        Layout.alignment: Qt.AlignHCenter
        text: "Bateria " + Math.round(UPower.displayDevice.percentage * 100) + "%" + (UPower.onBattery ? "" : " · ładowanie")
        color: Theme.muted
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

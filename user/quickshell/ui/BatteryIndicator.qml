import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

AbstractButton {
    id: root
    visible: BatteryInfo.available
    implicitWidth: 44
    implicitHeight: 42
    hoverEnabled: true
    Accessible.name: "Bateria: " + BatteryInfo.summary
    ToolTip.visible: hovered
    ToolTip.delay: 350
    ToolTip.text: BatteryInfo.summary
    background: Rectangle {
        radius: 5
        color: root.hovered || root.activeFocus ? Theme.alpha(Theme.highlight, 0.12) : "transparent"
        border.color: root.activeFocus ? Theme.highlight : "transparent"
    }
    contentItem: ColumnLayout {
        spacing: 3
        BatteryGauge {
            Layout.alignment: Qt.AlignHCenter
            level: BatteryInfo.level
            known: BatteryInfo.known
            charging: BatteryInfo.charging
            plugged: BatteryInfo.plugged
            low: BatteryInfo.low
            critical: BatteryInfo.critical
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: BatteryInfo.percentageText
            color: BatteryInfo.critical ? Theme.red : BatteryInfo.low ? "#e8d49a" : Theme.text
            font { family: Theme.font; pixelSize: 10 }
        }
    }
}

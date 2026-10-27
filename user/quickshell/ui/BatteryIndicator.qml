import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

AeroButton {
    id: root
    visible: BatteryInfo.available
    implicitWidth: 36
    implicitHeight: 36
    padding: 3
    leftPadding: 3
    rightPadding: 3
    hint: "Bateria: " + BatteryInfo.summary
    contentItem: ColumnLayout {
        spacing: 1
        Item {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: 24
            implicitHeight: 14
            BatteryGauge {
                anchors.centerIn: parent
                scale: 0.75
                level: BatteryInfo.level
                known: BatteryInfo.known
                charging: BatteryInfo.charging
                plugged: BatteryInfo.plugged
                low: BatteryInfo.low
                critical: BatteryInfo.critical
            }
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: BatteryInfo.percentageText
            color: BatteryInfo.critical ? Theme.red : BatteryInfo.low ? "#e8d49a" : Theme.text
            font { family: Theme.font; pixelSize: 9 }
        }
    }
}

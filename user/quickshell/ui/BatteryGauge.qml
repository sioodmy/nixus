import QtQuick
import QtQuick.Shapes

Item {
    id: root
    property real level: 1
    property bool known: true
    property bool charging: false
    property bool plugged: false
    property bool low: false
    property bool critical: false
    implicitWidth: 32
    implicitHeight: 18
    readonly property color chargeColor: critical ? "#ee849b" : low ? "#e5c785" : "#b9a0df"
    Rectangle {
        x: parent.width - 3; y: parent.height * 0.33
        width: 3; height: parent.height * 0.34; radius: 1
        color: "#b8a4cc"
    }
    Rectangle {
        id: casing
        width: parent.width - 3
        height: parent.height
        radius: 3
        border.color: root.critical ? "#ffb0bc" : "#d2c2e6"
        gradient: Gradient {
            GradientStop { position: 0; color: "#6c5a7d" }
            GradientStop { position: 0.45; color: "#30243e" }
            GradientStop { position: 1; color: "#21182e" }
        }
        Rectangle {
            x: 3; y: 3
            width: Math.max(0, (casing.width - 6) * Math.max(0, Math.min(1, root.level)))
            height: casing.height - 6
            radius: 1
            visible: root.known
            gradient: Gradient {
                GradientStop { position: 0; color: Qt.lighter(root.chargeColor, 1.25) }
                GradientStop { position: 0.48; color: root.chargeColor }
                GradientStop { position: 0.5; color: Qt.darker(root.chargeColor, 1.45) }
                GradientStop { position: 1; color: root.chargeColor }
            }
        }
        Shape {
            anchors.centerIn: parent
            width: 12; height: 16
            visible: root.known && root.charging
            ShapePath {
                fillColor: "#fff3ff"
                strokeColor: "#593c72"
                strokeWidth: 0.7
                startX: 7; startY: 0
                PathLine { x: 1; y: 9 }
                PathLine { x: 5; y: 9 }
                PathLine { x: 4; y: 16 }
                PathLine { x: 11; y: 6 }
                PathLine { x: 7; y: 6 }
                PathLine { x: 7; y: 0 }
            }
        }
        Item {
            anchors.centerIn: parent
            width: 10; height: 14
            visible: root.known && root.plugged && !root.charging
            Rectangle { x: 1; y: 4; width: 8; height: 6; radius: 2; color: "#fff0ff"; border.color: "#755285" }
            Rectangle { x: 2; y: 1; width: 2; height: 4; color: "#fff0ff" }
            Rectangle { x: 6; y: 1; width: 2; height: 4; color: "#fff0ff" }
            Rectangle { x: 4; y: 9; width: 2; height: 4; color: "#fff0ff" }
        }
        Text {
            anchors.centerIn: parent
            visible: !root.known || (root.critical && !root.charging && !root.plugged)
            text: !root.known ? "?" : "!"
            color: "#fff2ff"
            style: Text.Outline
            styleColor: "#60354c"
            font { family: Theme.font; pixelSize: 13; bold: true }
        }
    }
}

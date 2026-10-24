import QtQuick
import QtQuick.Controls

TextField {
    id: root
    implicitHeight: 38
    color: Theme.text
    placeholderTextColor: Theme.muted
    selectionColor: Theme.edge
    selectedTextColor: Theme.text
    font.family: Theme.font
    font.pixelSize: 14
    leftPadding: 12
    rightPadding: 12
    selectByMouse: true
    background: Rectangle {
        radius: 5
        color: "#d0130c20"
        border.color: root.activeFocus ? Theme.accent : Theme.edge
        Rectangle {
            anchors.fill: parent
            anchors.margins: 2
            radius: 3
            color: "transparent"
            border.color: "#20000000"
        }
    }
}

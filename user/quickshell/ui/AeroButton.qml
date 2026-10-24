import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

AbstractButton {
    id: root
    property string iconName: ""
    property bool selected: false
    property bool orb: false
    property int iconSize: orb ? 32 : 22
    property string hint: text
    implicitWidth: text ? Math.max(80, content.implicitWidth + 24) : 44
    implicitHeight: orb ? 54 : 38
    hoverEnabled: true
    focusPolicy: Qt.StrongFocus
    opacity: enabled ? 1 : 0.45
    scale: down ? 0.97 : 1
    Behavior on scale {
        NumberAnimation {
            duration: Theme.duration
            easing.type: Easing.OutQuad
        }
    }
    Accessible.name: hint
    ToolTip.visible: hovered && hint.length > 0
    ToolTip.delay: 600
    ToolTip.text: hint
    background: Rectangle {
        radius: root.orb ? height / 2 : 5
        border.width: 1
        border.color: root.activeFocus ? Theme.highlight : root.selected || root.hovered || root.orb ? Theme.alpha(Theme.highlight, 0.65) : Theme.alpha(Theme.edge, 0.55)
        gradient: Gradient {
            GradientStop {
                position: 0
                color: root.down ? "#4b3168" : root.selected || root.hovered || root.orb ? "#8b69b4" : "#51405f"
            }
            GradientStop {
                position: 0.48
                color: root.down ? "#382343" : root.selected || root.hovered || root.orb ? "#5f4085" : "#34273f"
            }
            GradientStop {
                position: 0.5
                color: root.selected || root.hovered || root.orb ? "#38204f" : "#251a2f"
            }
            GradientStop {
                position: 1
                color: root.selected || root.hovered || root.orb ? "#6d4294" : "#3b2b4a"
            }
        }
        Rectangle {
            anchors {
                fill: parent
                margins: 2
            }
            radius: Math.max(0, parent.radius - 2)
            color: "transparent"
            border.color: Theme.alpha(Theme.highlight, root.hovered || root.orb ? 0.22 : 0.08)
        }
    }
    contentItem: RowLayout {
        id: content
        spacing: 8
        Image {
            visible: root.iconName !== ""
            source: root.iconName ? Quickshell.iconPath(root.iconName, "application-x-executable") : ""
            sourceSize: Qt.size(root.iconSize, root.iconSize)
            Layout.preferredWidth: root.iconSize
            Layout.preferredHeight: root.iconSize
            Layout.alignment: Qt.AlignHCenter
        }
        Text {
            visible: root.text !== ""
            text: root.text
            font.family: Theme.font
            font.pixelSize: 13
            color: Theme.text
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true
            elide: Text.ElideRight
        }
    }
    leftPadding: text ? 12 : (width - iconSize) / 2
    rightPadding: leftPadding
}

import QtQuick

Rectangle {
    id: root
    property bool raised: false
    radius: 10
    border.width: 1
    border.color: Theme.alpha(Theme.highlight, 0.48)
    gradient: Gradient {
        GradientStop {
            position: 0
            color: Theme.alpha(root.raised ? Theme.edge : Theme.raised, 0.94)
        }
        GradientStop {
            position: 0.16
            color: Theme.alpha(Theme.surface, 0.91)
        }
        GradientStop {
            position: 0.52
            color: Theme.alpha(Theme.background, 0.91)
        }
        GradientStop {
            position: 1
            color: Theme.alpha(Theme.raised, 0.94)
        }
    }
    Rectangle {
        anchors.fill: parent
        anchors.margins: 2
        color: "transparent"
        radius: Math.max(0, parent.radius - 2)
        border.color: "#180c24"
        border.width: 1
    }
    Rectangle {
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 3
        }
        height: 1
        color: Theme.alpha(Theme.highlight, 0.23)
    }
}

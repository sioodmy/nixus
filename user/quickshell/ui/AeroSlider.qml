import QtQuick
import QtQuick.Controls

Slider {
    id: root
    implicitHeight: 32
    background: Rectangle {
        x: root.leftPadding
        y: (root.height - height) / 2
        width: root.availableWidth
        height: 7
        radius: 4
        color: Theme.background
        border.color: Theme.edge
        Rectangle {
            width: root.visualPosition * parent.width
            height: parent.height
            radius: 4
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: Theme.highlight
                }
                GradientStop {
                    position: 1
                    color: Theme.accent
                }
            }
        }
    }
    handle: Rectangle {
        x: root.leftPadding + root.visualPosition * (root.availableWidth - width)
        y: (root.height - height) / 2
        width: 15
        height: 23
        radius: 4
        border.color: root.activeFocus ? Theme.highlight : Theme.edge
        gradient: Gradient {
            GradientStop {
                position: 0
                color: Theme.highlight
            }
            GradientStop {
                position: 0.48
                color: Theme.accent
            }
            GradientStop {
                position: 0.5
                color: Theme.edge
            }
            GradientStop {
                position: 1
                color: Theme.accent
            }
        }
    }
}

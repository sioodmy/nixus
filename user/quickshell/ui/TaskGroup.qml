import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

Rectangle {
    id: root
    required property var workspace
    required property var windows
    required property string label
    required property bool current
    signal workspaceRequested()
    signal windowRequested(var window)
    implicitHeight: contents.implicitHeight + 8
    radius: 7
    border.color: Theme.alpha(Theme.highlight, current ? 0.48 : 0.14)
    gradient: Gradient {
        GradientStop { position: 0; color: root.current ? "#66534273" : "#183b294d" }
        GradientStop { position: 0.48; color: root.current ? "#502e2041" : "#10211630" }
        GradientStop { position: 1; color: root.current ? "#603e2858" : "#20332344" }
    }
    ColumnLayout {
        id: contents
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 4 }
        spacing: 3
        AbstractButton {
            id: heading
            Layout.fillWidth: true
            implicitHeight: 22
            hoverEnabled: true
            Accessible.name: "Pulpit " + root.label + ", okien: " + root.windows.length
            ToolTip.visible: hovered
            ToolTip.delay: 550
            ToolTip.text: Accessible.name
            onClicked: root.workspaceRequested()
            background: Rectangle {
                radius: 3
                color: heading.hovered || heading.activeFocus ? Theme.alpha(Theme.highlight, 0.15) : "transparent"
                border.color: heading.activeFocus ? Theme.highlight : "transparent"
            }
            contentItem: Row {
                anchors.centerIn: parent
                spacing: 4
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 4; height: 4; radius: 2
                    color: root.current ? Theme.highlight : Theme.edge
                }
                Text {
                    text: root.label
                    color: root.current ? Theme.highlight : Theme.muted
                    font { family: Theme.font; pixelSize: 10; weight: Font.DemiBold }
                    width: Math.min(implicitWidth, 27)
                    elide: Text.ElideRight
                }
            }
        }
        Repeater {
            model: root.windows
            AeroButton {
                id: task
                required property var modelData
                readonly property var window: modelData.wayland || modelData
                readonly property string appId: window.appId || modelData.lastIpcObject?.class || ""
                readonly property var entry: DesktopEntries.heuristicLookup(appId)
                Layout.fillWidth: true
                implicitHeight: 42
                iconSize: 30
                iconName: Apps.iconName(entry, appId)
                hint: (entry?.name || appId || "Okno") + " · " + (window.title || modelData.title || "")
                selected: modelData.activated || window.activated
                onClicked: root.windowRequested(modelData)
                Rectangle {
                    anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                        leftMargin: -3
                    }
                    width: 3
                    height: task.selected ? 23 : 10
                    radius: 2
                    color: task.modelData.urgent ? Theme.green : task.selected ? Theme.highlight : Theme.alpha(Theme.accent, 0.55)
                }
            }
        }
        Text {
            visible: root.windows.length === 0
            Layout.fillWidth: true
            Layout.preferredHeight: visible ? 25 : 0
            text: "—"
            horizontalAlignment: Text.AlignHCenter
            color: Theme.edge
            font { family: Theme.font; pixelSize: 17 }
        }
    }
}

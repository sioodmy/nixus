import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications

PanelWindow {
    id: root
    required property bool primary
    visible: Notices.active.length > 0 && !Desktop.doNotDisturb && !Desktop.preview && primary
    anchors {
        top: true
        right: true
    }
    margins {
        top: 16
        right: Theme.rightPanel ? 90 : 16
    }
    implicitWidth: 370
    implicitHeight: Math.min(column.implicitHeight, screen.height - 32)
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: "amethyst-notifications"
    WlrLayershell.layer: WlrLayer.Overlay
    ColumnLayout {
        id: column
        width: parent.width
        spacing: 8
        Repeater {
            model: Notices.active
            Glass {
                id: toast
                required property var modelData
                required property int index
                visible: index >= Notices.active.length - 4
                Layout.fillWidth: true
                implicitHeight: content.implicitHeight + 28
                Timer {
                    // Timers also run for queued or hidden toasts and DND.
                    interval: toast.modelData.expireTimeout > 0 ? toast.modelData.expireTimeout : 6500
                    running: toast.modelData.expireTimeout !== 0 && toast.modelData.urgency !== NotificationUrgency.Critical
                    onTriggered: toast.modelData.expire()
                }
                ColumnLayout {
                    id: content
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: 14
                    }
                    spacing: 7
                    RowLayout {
                        Layout.fillWidth: true
                        AeroText {
                            Layout.fillWidth: true
                            text: toast.modelData.appName
                            color: Theme.muted
                            font.pixelSize: 11
                        }
                        AeroButton {
                            implicitWidth: 24
                            implicitHeight: 22
                            iconName: "window-close"
                            iconSize: 12
                            hint: "Odrzuć"
                            onClicked: toast.modelData.dismiss()
                        }
                    }
                    AeroText {
                        Layout.fillWidth: true
                        text: toast.modelData.summary
                        wrapMode: Text.Wrap
                        font.pixelSize: 14
                        elide: Text.ElideNone
                    }
                    AeroText {
                        Layout.fillWidth: true
                        text: toast.modelData.body
                        color: Theme.muted
                        wrapMode: Text.Wrap
                        maximumLineCount: 4
                    }
                    Flow {
                        Layout.fillWidth: true
                        spacing: 6
                        Repeater {
                            model: toast.modelData.actions
                            AeroButton {
                                required property var modelData
                                text: modelData.text
                                implicitHeight: 29
                                onClicked: modelData.invoke()
                            }
                        }
                    }
                }
            }
        }
    }
}

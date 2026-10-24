import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    spacing: 12
    RowLayout {
        Layout.fillWidth: true
        AeroButton {
            Layout.fillWidth: true
            text: Desktop.doNotDisturb ? "Nie przeszkadzać: włączone" : "Nie przeszkadzać"
            selected: Desktop.doNotDisturb
            iconName: "notifications-disabled"
            onClicked: Desktop.doNotDisturb = !Desktop.doNotDisturb
        }
        AeroButton {
            text: "Wyczyść"
            enabled: Notices.count > 0
            onClicked: Notices.clear()
        }
    }
    ListView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        spacing: 8
        model: Notices.history
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar {}
        delegate: Rectangle {
            id: notice
            required property var modelData
            width: ListView.view.width
            height: content.implicitHeight + 24
            radius: 5
            color: "#7020152f"
            border.color: Theme.alpha(Theme.edge, 0.6)
            ColumnLayout {
                id: content
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 12
                }
                spacing: 5
                RowLayout {
                    Layout.fillWidth: true
                    AeroText {
                        Layout.fillWidth: true
                        text: notice.modelData.app
                        color: Theme.muted
                        font.pixelSize: 11
                    }
                    AeroText {
                        text: notice.modelData.time
                        color: Theme.muted
                        font.pixelSize: 11
                    }
                }
                AeroText {
                    Layout.fillWidth: true
                    text: notice.modelData.title
                    font.pixelSize: 14
                    wrapMode: Text.Wrap
                    elide: Text.ElideNone
                }
                AeroText {
                    Layout.fillWidth: true
                    text: notice.modelData.body
                    color: Theme.muted
                    wrapMode: Text.Wrap
                    maximumLineCount: 5
                }
            }
        }
        AeroText {
            anchors.centerIn: parent
            visible: Notices.count === 0
            text: "Brak powiadomień"
            color: Theme.muted
        }
    }
}

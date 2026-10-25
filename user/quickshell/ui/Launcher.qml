import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell

Item {
    id: root
    property var results: Apps.search(search.text)
    function show() {
        search.text = "";
        resultsView.currentIndex = 0;
        search.forceActiveFocus();
    }
    onVisibleChanged: if (visible)
        Qt.callLater(show)
    Connections {
        target: Desktop
        function onPageChanged() {
            if (Desktop.page === "launcher")
                Qt.callLater(root.show);
        }
    }
    function activate() {
        var shortcuts = {
            ":wifi": "wifi",
            ":bt": "bluetooth",
            ":audio": "audio",
            ":power": "session"
        };
        if (shortcuts[search.text.trim()])
            Desktop.page = shortcuts[search.text.trim()];
        else if (root.results[resultsView.currentIndex])
            Apps.launch(root.results[resultsView.currentIndex]);
    }
    ColumnLayout {
        anchors.fill: parent
        spacing: 12
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 16
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumWidth: 260
                Layout.preferredWidth: 400
                color: "#65110c1c"
                border.color: Theme.alpha(Theme.edge, 0.65)
                radius: 6
                ListView {
                    id: resultsView
                    anchors.fill: parent
                    anchors.margins: 5
                    clip: true
                    spacing: 2
                    model: root.results
                    currentIndex: 0
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.vertical: ScrollBar {}
                    highlightMoveDuration: 0
                    delegate: AbstractButton {
                        id: result
                        required property var modelData
                        required property int index
                        width: ListView.view.width
                        height: 51
                        hoverEnabled: true
                        onHoveredChanged: if (hovered)
                            resultsView.currentIndex = index
                        onClicked: Apps.launch(modelData)
                        background: Rectangle {
                            radius: 4
                            visible: result.ListView.isCurrentItem
                            border.color: Theme.alpha(Theme.highlight, 0.55)
                            gradient: Gradient {
                                GradientStop {
                                    position: 0
                                    color: "#825e9e"
                                }
                                GradientStop {
                                    position: 0.5
                                    color: "#49315f"
                                }
                                GradientStop {
                                    position: 1
                                    color: "#644480"
                                }
                            }
                        }
                        contentItem: RowLayout {
                            spacing: 10
                            Image {
                                source: Quickshell.iconPath(Apps.iconName(result.modelData), "application-x-executable")
                                sourceSize: Qt.size(32, 32)
                                Layout.preferredWidth: 32
                                Layout.preferredHeight: 32
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2
                                AeroText {
                                    Layout.fillWidth: true
                                    text: result.modelData.name
                                    font.pixelSize: 14
                                }
                                AeroText {
                                    Layout.fillWidth: true
                                    text: result.modelData.genericName || result.modelData.comment || result.modelData.id
                                    font.pixelSize: 11
                                    color: Theme.muted
                                }
                            }
                        }
                        leftPadding: 9
                        rightPadding: 9
                    }
                }
                AeroText {
                    anchors.centerIn: parent
                    visible: root.results.length === 0
                    text: search.text.startsWith(":") ? "Enter otwiera panel" : "Nie znaleziono aplikacji"
                    color: Theme.muted
                }
            }
            ColumnLayout {
                Layout.minimumWidth: 162
                Layout.maximumWidth: 162
                Layout.preferredWidth: 162
                Layout.fillHeight: true
                spacing: 5
                Glass {
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: 56
                    implicitHeight: 56
                    radius: 8
                    raised: true
                    Image {
                        anchors.centerIn: parent
                        width: 44
                        height: 44
                        source: Quickshell.iconPath("user-identity", "system-users")
                        sourceSize: Qt.size(44, 44)
                    }
                }
                AeroText {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: Quickshell.env("USER") || "sioodmy"
                    font.pixelSize: 16
                }
                Repeater {
                    model: [
                        {
                            title: "Folder domowy",
                            icon: "user-home",
                            directory: "HOME"
                        },
                        {
                            title: "Dokumenty",
                            icon: "folder-documents",
                            directory: "DOCUMENTS"
                        },
                        {
                            title: "Pobrane",
                            icon: "folder-downloads",
                            directory: "DOWNLOAD"
                        }
                    ]
                    AeroButton {
                        required property var modelData
                        Layout.fillWidth: true
                        implicitHeight: 30
                        text: modelData.title
                        iconName: modelData.icon
                        iconSize: 20
                        onClicked: Desktop.run(["aero-directory", modelData.directory])
                    }
                }
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 1
                    color: Theme.alpha(Theme.highlight, 0.2)
                }
                AeroButton {
                    Layout.fillWidth: true
                    implicitHeight: 30
                    text: "Sieć i Wi-Fi"
                    iconName: "network-wireless"
                    onClicked: Desktop.page = "wifi"
                }
                AeroButton {
                    Layout.fillWidth: true
                    implicitHeight: 30
                    text: "Bluetooth"
                    iconName: "preferences-system-bluetooth"
                    onClicked: Desktop.page = "bluetooth"
                }
                AeroButton {
                    Layout.fillWidth: true
                    implicitHeight: 30
                    text: "Dźwięk"
                    iconName: "audio-volume-high"
                    onClicked: Desktop.page = "audio"
                }
                Item {
                    Layout.fillHeight: true
                }
                AeroButton {
                    Layout.fillWidth: true
                    implicitHeight: 30
                    text: "Zablokuj"
                    iconName: "system-lock-screen"
                    onClicked: Desktop.lock()
                }
                AeroButton {
                    Layout.fillWidth: true
                    implicitHeight: 30
                    text: "Zasilanie"
                    iconName: "system-shutdown"
                    onClicked: Desktop.page = "session"
                }
            }
        }
        AeroField {
            id: search
            Layout.fillWidth: true
            placeholderText: "Szukaj programów…"
            onTextChanged: resultsView.currentIndex = 0
            onAccepted: root.activate()
            Keys.onDownPressed: resultsView.currentIndex = Math.min(resultsView.count - 1, resultsView.currentIndex + 1)
            Keys.onUpPressed: resultsView.currentIndex = Math.max(0, resultsView.currentIndex - 1)
            Keys.onEscapePressed: Desktop.close()
        }
        AeroText {
            text: "↑ ↓ wybór     Enter otwórz     Esc zamknij"
            color: Theme.muted
            font.pixelSize: 11
        }
    }
}

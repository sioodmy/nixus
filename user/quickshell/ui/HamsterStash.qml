import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

Glass {
    id: root
    raised: true
    focus: true
    Keys.onEscapePressed: Hamster.panelOpen = false
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 10
        RowLayout {
            Layout.fillWidth: true
            Image {
                source: "assets/chomikbox/idle.png"
                sourceClipRect: Qt.rect(152, 136, 88, 104)
                fillMode: Image.PreserveAspectFit
                Layout.preferredWidth: 38; Layout.preferredHeight: 38
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                AeroText { Layout.fillWidth: true; text: "Chomicze policzki"; font.pixelSize: 17 }
                AeroText { Layout.fillWidth: true; text: Hamster.items.length + " / 100 plików"; color: Theme.muted; font.pixelSize: 11 }
            }
            AeroButton {
                implicitWidth: 28; implicitHeight: 28
                iconName: "window-close"; iconSize: 14
                hint: "Zamknij · Esc"
                onClicked: Hamster.panelOpen = false
            }
        }
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 48
            radius: 6
            color: addArea.containsDrag ? Theme.alpha(Theme.accent, 0.35) : Theme.alpha(Theme.background, 0.6)
            border.color: addArea.containsDrag ? Theme.highlight : Theme.edge
            AeroText {
                anchors.centerIn: parent
                text: addArea.containsDrag ? "Mniam! Puść tutaj" : "Upuść pliki tutaj lub na chomika"
                color: Theme.highlight
            }
            DropArea {
                id: addArea
                anchors.fill: parent
                onEntered: drag => { drag.accepted = drag.hasUrls && (drag.supportedActions & Qt.CopyAction) !== 0; }
                onDropped: drop => {
                    if (drop.hasUrls && (drop.supportedActions & Qt.CopyAction)) {
                        Hamster.add(drop.urls);
                        drop.accept(Qt.CopyAction);
                    }
                }
            }
        }
        ListView {
            id: files
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 50
            clip: true
            spacing: 4
            model: Hamster.items
            ScrollBar.vertical: ScrollBar {}
            AeroText {
                anchors.centerIn: parent
                visible: Hamster.items.length === 0
                text: "Jeszcze pusto. Nakarm mnie plikami!"
                color: Theme.muted
                font.pixelSize: 12
            }
            delegate: Rectangle {
                id: row
                required property var modelData
                width: files.width
                height: 52
                radius: 5
                color: Hamster.selected.indexOf(modelData.id) !== -1 ? Theme.alpha(Theme.accent, 0.25) : Theme.alpha(Theme.background, 0.35)
                border.color: Theme.alpha(Theme.edge, 0.5)
                Drag.dragType: Drag.Automatic
                Drag.active: fileDrag.active
                Drag.supportedActions: Qt.CopyAction
                Drag.mimeData: ({"text/uri-list": modelData.url + "\r\n"})
                Drag.imageSource: Quickshell.iconPath("text-x-generic")
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 5
                    spacing: 6
                    AeroButton {
                        implicitWidth: 26; implicitHeight: 28
                        text: selected ? "✓" : "○"
                        selected: Hamster.selected.indexOf(row.modelData.id) !== -1
                        enabled: row.modelData.available
                        hint: "Wybierz " + row.modelData.name
                        onClicked: Hamster.toggleSelected(row.modelData.id)
                    }
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            spacing: 3
                            AeroText { width: parent.width; text: row.modelData.name; color: row.modelData.available ? Theme.text : Theme.red }
                            AeroText { width: parent.width; text: row.modelData.available ? Hamster.sizeLabel(row.modelData.size) + " · przeciągnij, aby zabrać" : "Plik przeniesiony lub usunięty"; font.pixelSize: 10; color: Theme.muted }
                        }
                        DragHandler {
                            id: fileDrag
                            target: null
                            enabled: row.modelData.available
                        }
                        HoverHandler { cursorShape: Qt.OpenHandCursor }
                    }
                    AeroButton {
                        implicitWidth: 28; implicitHeight: 28
                        iconName: "document-open"; iconSize: 15
                        enabled: row.modelData.available
                        hint: "Otwórz " + row.modelData.name
                        onClicked: Desktop.spawn(["xdg-open", row.modelData.url])
                    }
                    AeroButton {
                        implicitWidth: 28; implicitHeight: 28
                        iconName: "list-remove"; iconSize: 14
                        hint: "Usuń ze schowka (zachowaj oryginał)"
                        onClicked: Hamster.send({action: "remove", id: row.modelData.id})
                    }
                }
            }
        }
        AeroText {
            Layout.fillWidth: true
            visible: Hamster.error !== "" || Hamster.notice !== ""
            text: Hamster.error || Hamster.notice
            color: Hamster.error ? Theme.red : Theme.highlight
            font.pixelSize: 11
            wrapMode: Text.Wrap
            elide: Text.ElideNone
        }
        ColumnLayout {
            visible: Hamster.sharing
            Layout.fillWidth: true
            spacing: 6
            AeroText {
                Layout.fillWidth: true
                text: Hamster.url ? "Link działa do " + new Date(Hamster.expires * 1000).toLocaleTimeString(Qt.locale(), "HH:mm") : "Otwieram tunel Cloudflare…"
                color: Theme.green
                font.pixelSize: 12
            }
            RowLayout {
                Layout.fillWidth: true
                AeroButton {
                    Layout.fillWidth: true
                    text: "Kopiuj link"
                    iconName: "edit-copy"
                    enabled: Hamster.url !== ""
                    onClicked: {
                        Quickshell.execDetached(["wl-copy", "--type", "text/plain", "--", Hamster.url]);
                        Hamster.notice = "Link skopiowany.";
                    }
                }
                AeroButton { text: "Wyłącz link"; onClicked: Hamster.send({action: "stop"}) }
            }
        }
        AeroButton {
            Layout.fillWidth: true
            text: Hamster.busy ? "Pakuję pliki…" : Hamster.sharing ? "Zastąp link · 15 min" : "Udostępnij " + (Hamster.selected.length ? "wybrane" : "wszystkie") + " · 15 min"
            iconName: "network-transmit-receive"
            enabled: Hamster.ready && !Hamster.busy && Hamster.items.some(item => item.available)
            onClicked: Hamster.share()
        }
        AeroText {
            Layout.fillWidth: true
            text: "Każdy z linkiem pobierze wybrane pliki. Kilka plików trafi do ZIP-a. Komputer musi być włączony."
            color: Theme.muted
            font.pixelSize: 10
            wrapMode: Text.Wrap
            elide: Text.ElideNone
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: 5
            AeroButton {
                Layout.fillWidth: true
                text: "Opróżnij"
                hint: "Usuń odnośniki ze schowka, zachowując oryginalne pliki"
                enabled: Hamster.ready && Hamster.items.length > 0
                onClicked: Hamster.send({action: "clear"})
            }
            AeroButton {
                visible: Quickshell.screens.length > 1
                Layout.fillWidth: true
                text: "Inny ekran"
                onClicked: Hamster.nextScreen()
            }
            AeroButton {
                visible: !Hamster.ready
                text: "Obudź"
                onClicked: Hamster.wake()
            }
            AeroButton {
                Layout.fillWidth: true
                text: "Schowaj"
                hint: "Schowaj do restartu; aero-hamster przywoła chomika"
                onClicked: { Hamster.panelOpen = false; Hamster.hidden = true; }
            }
        }
    }
}

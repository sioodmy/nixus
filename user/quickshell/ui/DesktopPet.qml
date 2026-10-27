import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root
    readonly property real petX: Math.round(12 + Hamster.position.x * Math.max(0, petWindow.width - 108))
    readonly property real petY: Math.round(12 + Hamster.position.y * Math.max(0, petWindow.height - 108))
    readonly property string animation: creature.clipName
    readonly property int animationFrames: creature.frameCount
    readonly property bool spriteLoaded: creature.loaded
    PanelWindow {
        id: petWindow
        screen: Hamster.output
        visible: Hamster.enabled && !Hamster.hidden && Hamster.output !== null
        anchors { top: true; left: true; right: true; bottom: true }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        // Only the hamster accepts input. The rest of the desktop stays clickable.
        mask: Region { item: pet }
        WlrLayershell.namespace: "amethyst-hamster"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        Item {
            id: pet
            x: root.petX
            y: root.petY
            width: 84
            height: 88
            scale: drop.containsDrag ? 1.1 : 1
            Behavior on scale { NumberAnimation { duration: Theme.duration } }
            Rectangle {
                anchors.centerIn: parent
                width: 78; height: 78; radius: 39
                visible: drop.containsDrag
                color: Theme.alpha(Theme.accent, 0.28)
                border.color: Theme.highlight
            }
            ChomikSprite {
                id: creature
                anchors.fill: parent
                active: petWindow.visible
                carrying: drop.containsDrag
                moving: mouse.pressed && mouse.moved
            }
            Rectangle {
                anchors { right: parent.right; top: parent.top; topMargin: 7 }
                width: Math.max(20, badge.implicitWidth + 10); height: 20; radius: 10
                visible: Hamster.items.length > 0 || Hamster.sharing
                color: Hamster.sharing ? Theme.green : "#6d4294"
                border.color: Theme.highlight
                Text {
                    id: badge
                    anchors.centerIn: parent
                    text: Hamster.items.length
                    font { family: Theme.font; pixelSize: 11; bold: true }
                    color: Hamster.sharing ? Theme.background : Theme.text
                }
            }
            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                property point start
                property point origin
                property bool moved: false
                onPressed: event => {
                    start = pet.mapToItem(petWindow.contentItem, event.x, event.y);
                    origin = Qt.point(pet.x, pet.y);
                    moved = false;
                }
                onPositionChanged: event => {
                    if (!pressed || !(pressedButtons & Qt.LeftButton)) return;
                    const point = pet.mapToItem(petWindow.contentItem, event.x, event.y);
                    const dx = point.x - start.x, dy = point.y - start.y;
                    if (Math.abs(dx) + Math.abs(dy) > 5) moved = true;
                    if (moved) {
                        Hamster.panelOpen = false;
                        pet.x = Math.max(12, Math.min(petWindow.width - 96, origin.x + dx));
                        pet.y = Math.max(12, Math.min(petWindow.height - 100, origin.y + dy));
                    }
                }
                onReleased: {
                    if (moved) {
                        Hamster.move((pet.x - 12) / Math.max(1, petWindow.width - 108), (pet.y - 12) / Math.max(1, petWindow.height - 108), petWindow.screen.name);
                        pet.x = Qt.binding(() => root.petX);
                        pet.y = Qt.binding(() => root.petY);
                    } else {
                        Hamster.toggle();
                    }
                }
                ToolTip.visible: containsMouse && !pressed && !Hamster.panelOpen
                ToolTip.delay: 800
                ToolTip.text: "Chomik · upuść pliki, kliknij po schowek\nPrzytrzymaj, żeby przesunąć"
            }
            DropArea {
                id: drop
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
        Connections {
            target: Hamster
            function onFed(reaction) { creature.play(reaction === "screenshot" ? "screenshot" : "drop"); }
            function onMusicStarted() { creature.play("music"); }
        }
    }
    PanelWindow {
        id: panel
        screen: Hamster.output
        visible: petWindow.visible && Hamster.panelOpen
        anchors { left: true; top: true }
        implicitWidth: Math.min(380, (screen?.width || 440) - 24)
        implicitHeight: Math.min(500, (screen?.height || 600) - 24)
        margins.left: Math.max(12, Math.min((screen?.width || 440) - width - 12,
            root.petY >= height + 20 ? root.petX - width + 84 : root.petX >= width + 20 ? root.petX - width - 8 : root.petX + 92))
        margins.top: Math.max(12, Math.min((screen?.height || 600) - height - 12,
            root.petY >= height + 20 ? root.petY - height - 8 : root.petY - height / 2 + 44))
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.namespace: "amethyst-hamster-stash"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
        HyprlandFocusGrab {
            windows: [panel, petWindow]
            active: panel.visible && !Desktop.preview
            onCleared: Hamster.panelOpen = false
        }
        HamsterStash { anchors.fill: parent }
    }
}

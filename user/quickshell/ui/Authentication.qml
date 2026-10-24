import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Polkit

Scope {
    id: root
    property var agent: null
    property Component agentComponent: Component {
        PolkitAgent {}
    }
    Component.onCompleted: if (!Desktop.preview)
        agent = agentComponent.createObject(root)
    FloatingWindow {
        id: window
        title: "Autoryzacja · Amethyst Aero"
        visible: !!root.agent?.isActive
        implicitWidth: 430
        implicitHeight: 330
        color: Theme.background
        onVisibleChanged: {
            password.text = "";
            if (visible)
                Qt.callLater(() => password.forceActiveFocus());
        }
        Glass {
            anchors.fill: parent
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 22
                spacing: 12
                AeroText {
                    text: "Wymagana autoryzacja"
                    font.pixelSize: 19
                }
                AeroText {
                    Layout.fillWidth: true
                    text: root.agent?.flow?.message || ""
                    wrapMode: Text.Wrap
                    elide: Text.ElideNone
                }
                AeroText {
                    Layout.fillWidth: true
                    text: root.agent?.flow?.supplementaryMessage || (root.agent?.flow?.failed ? "Nieprawidłowe hasło. Spróbuj ponownie." : "")
                    wrapMode: Text.Wrap
                    color: Theme.muted
                    elide: Text.ElideNone
                }
                Item {
                    Layout.fillHeight: true
                }
                AeroField {
                    id: password
                    Layout.fillWidth: true
                    placeholderText: root.agent?.flow?.inputPrompt || "Hasło"
                    echoMode: root.agent?.flow?.responseVisible ? TextInput.Normal : TextInput.Password
                    enabled: !!root.agent?.flow?.isResponseRequired
                    onAccepted: submit.clicked()
                }
                RowLayout {
                    AeroButton {
                        id: submit
                        text: "Potwierdź"
                        selected: true
                        enabled: !!root.agent?.flow?.isResponseRequired
                        onClicked: {
                            if (!enabled)
                                return;
                            root.agent.flow.submit(password.text);
                            password.text = "";
                        }
                    }
                    AeroButton {
                        text: "Anuluj"
                        onClicked: {
                            root.agent.flow.cancelAuthenticationRequest();
                            password.text = "";
                        }
                    }
                }
            }
        }
        Connections {
            target: root.agent?.flow || null
            function onIsResponseRequiredChanged() {
                password.text = "";
                if (root.agent.flow.isResponseRequired)
                    password.forceActiveFocus();
            }
        }
    }
}

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking

ColumnLayout {
    id: root
    spacing: 12
    readonly property var devices: Networking.devices.values.filter(d => d.type === DeviceType.Wifi)
    property int deviceIndex: 0
    readonly property var device: devices[deviceIndex] || null
    property var selected: null
    property string status: ""
    readonly property bool needsPsk: selected && [WifiSecurityType.WpaPsk, WifiSecurityType.Wpa2Psk, WifiSecurityType.Sae].indexOf(selected.security) !== -1
    readonly property bool enterprise: selected && !needsPsk && selected.security !== WifiSecurityType.Open && selected.security !== WifiSecurityType.Owe
    onVisibleChanged: if (!visible) {
        password.text = "";
        selected = null;
    }
    Binding {
        target: root.device
        property: "scannerEnabled"
        value: root.visible && Networking.wifiEnabled
        when: !!root.device
    }
    RowLayout {
        Layout.fillWidth: true
        AeroText {
            Layout.fillWidth: true
            text: !Networking.wifiHardwareEnabled ? "Wi-Fi zablokowane sprzętowo" : Networking.wifiEnabled ? "Wi-Fi jest włączone" : "Wi-Fi jest wyłączone"
            color: Theme.muted
        }
        AeroButton {
            text: Networking.wifiEnabled ? "Wyłącz" : "Włącz"
            enabled: Networking.wifiHardwareEnabled
            selected: Networking.wifiEnabled
            onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
        }
    }
    ComboBox {
        visible: root.devices.length > 1
        Layout.fillWidth: true
        model: root.devices.map(d => d.name)
        onActivated: root.deviceIndex = currentIndex
    }
    ListView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        spacing: 6
        model: root.device ? root.device.networks.values.slice().sort((a, b) => Number(b.connected) - Number(a.connected) || b.signalStrength - a.signalStrength) : []
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar {}
        delegate: AeroButton {
            id: networkButton
            required property var modelData
            width: ListView.view.width
            implicitHeight: 56
            selected: modelData.connected || root.selected === modelData
            iconName: modelData.connected ? "network-wireless-connected" : "network-wireless"
            text: ""
            leftPadding: 12
            rightPadding: 12
            hint: modelData.name
            contentItem: RowLayout {
                Image {
                    source: Quickshell.iconPath("network-wireless")
                    sourceSize: Qt.size(26, 26)
                    Layout.preferredWidth: 26
                    Layout.preferredHeight: 26
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 3
                    AeroText {
                        Layout.fillWidth: true
                        text: networkButton.modelData.name || "Ukryta sieć"
                        font.pixelSize: 14
                    }
                    AeroText {
                        Layout.fillWidth: true
                        font.pixelSize: 11
                        color: networkButton.modelData.connected ? Theme.green : Theme.muted
                        text: networkButton.modelData.connected ? "Połączono" : networkButton.modelData.stateChanging ? "Łączenie…" : WifiSecurityType.toString(networkButton.modelData.security) + (networkButton.modelData.known ? " · zapamiętana" : "")
                    }
                }
                AeroText {
                    text: Math.round(networkButton.modelData.signalStrength * 100) + "%"
                    color: Theme.muted
                    font.pixelSize: 11
                }
            }
            onClicked: {
                root.selected = modelData;
                root.status = "";
                password.text = "";
                if (!modelData.connected && (modelData.known || !root.needsPsk && !root.enterprise))
                    modelData.connect();
                else if (root.needsPsk)
                    password.forceActiveFocus();
            }
        }
    }
    AeroText {
        visible: !root.device || (root.device.networks.values.length === 0 && Networking.wifiEnabled)
        text: root.device ? "Wyszukiwanie dostępnych sieci…" : "Nie znaleziono karty Wi-Fi."
        color: Theme.muted
        Layout.fillWidth: true
    }
    Connections {
        target: root.selected
        function onConnectionFailed(reason) {
            root.status = reason === ConnectionFailReason.NoSecrets ? "Podaj hasło lub sprawdź, czy jest poprawne." : "Nie udało się połączyć: " + ConnectionFailReason.toString(reason);
            password.text = "";
            if (root.needsPsk)
                password.forceActiveFocus();
        }
        function onConnectedChanged() {
            if (root.selected?.connected) {
                root.status = "Połączono z " + root.selected.name;
                password.text = "";
            }
        }
    }
    AeroText {
        visible: root.status !== ""
        Layout.fillWidth: true
        wrapMode: Text.Wrap
        text: root.status
        color: Theme.highlight
        elide: Text.ElideNone
    }
    ColumnLayout {
        visible: !!root.selected
        Layout.fillWidth: true
        spacing: 8
        AeroText {
            Layout.fillWidth: true
            text: root.selected?.name || ""
            font.pixelSize: 14
        }
        AeroField {
            id: password
            Layout.fillWidth: true
            visible: root.needsPsk && !root.selected?.connected
            placeholderText: "Hasło sieci"
            echoMode: TextInput.Password
            onAccepted: connectButton.clicked()
        }
        AeroText {
            visible: root.enterprise && !root.selected?.known
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            elide: Text.ElideNone
            color: Theme.muted
            text: "Sieci firmowe i eduroam skonfigurujesz w edytorze połączeń poniżej. Zapisany profil połączysz tutaj."
        }
        RowLayout {
            AeroButton {
                id: connectButton
                text: root.selected?.connected ? "Rozłącz" : root.selected?.stateChanging ? "Łączenie…" : "Połącz"
                enabled: !!root.selected && !root.selected.stateChanging && (!root.needsPsk || root.selected.connected || root.selected.known || password.text.length > 0)
                onClicked: {
                    if (!enabled)
                        return;
                    if (root.selected.connected)
                        root.selected.disconnect();
                    else if (root.enterprise && !root.selected.known)
                        Desktop.run(["nm-connection-editor"]);
                    else if (root.needsPsk && password.text.length) {
                        root.selected.connectWithPsk(password.text);
                        password.text = "";
                    } else
                        root.selected.connect();
                }
            }
            AeroButton {
                visible: !!root.selected?.known
                text: "Zapomnij"
                onClicked: {
                    root.selected.forget();
                    root.status = "Usunięto zapisany profil.";
                }
            }
        }
    }
    AeroButton {
        Layout.fillWidth: true
        text: "Edytuj połączenia / ukryta sieć"
        iconName: "preferences-system-network"
        onClicked: Desktop.run(["nm-connection-editor"])
    }
}

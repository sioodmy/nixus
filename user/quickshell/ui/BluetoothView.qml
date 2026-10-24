import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth

ColumnLayout {
    id: root
    spacing: 12
    property int adapterIndex: 0
    readonly property var adapter: Bluetooth.adapters.values[adapterIndex] || null
    property bool scanning: false
    property var scanAdapter: null
    property var pending: null
    function stopScan() {
        if (scanning && scanAdapter)
            scanAdapter.discovering = false;
        scanning = false;
        scanAdapter = null;
    }
    onVisibleChanged: if (!visible)
        stopScan()
    onAdapterChanged: stopScan()
    Timer {
        interval: 60000
        running: root.scanning
        onTriggered: root.stopScan()
    }
    RowLayout {
        Layout.fillWidth: true
        AeroText {
            Layout.fillWidth: true
            color: Theme.muted
            text: !root.adapter ? "Brak adaptera Bluetooth" : root.adapter.enabled ? "Bluetooth jest włączony" : "Bluetooth jest wyłączony"
        }
        AeroButton {
            text: root.adapter?.enabled ? "Wyłącz" : "Włącz"
            enabled: !!root.adapter
            selected: !!root.adapter?.enabled
            onClicked: root.adapter.enabled = !root.adapter.enabled
        }
    }
    ComboBox {
        visible: Bluetooth.adapters.values.length > 1
        Layout.fillWidth: true
        model: Bluetooth.adapters.values.map(a => a.name)
        onActivated: root.adapterIndex = currentIndex
    }
    AeroButton {
        Layout.fillWidth: true
        enabled: !!root.adapter?.enabled
        text: root.scanning ? "Zatrzymaj wyszukiwanie" : "Znajdź urządzenie"
        iconName: "edit-find"
        onClicked: {
            if (root.scanning)
                root.stopScan();
            else {
                root.scanAdapter = root.adapter;
                root.adapter.discovering = true;
                root.scanning = true;
            }
        }
    }
    ListView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        spacing: 7
        boundsBehavior: Flickable.StopAtBounds
        model: root.adapter ? root.adapter.devices.values.slice().sort((a, b) => Number(b.connected) - Number(a.connected) || Number(b.paired) - Number(a.paired) || a.name.localeCompare(b.name)) : []
        ScrollBar.vertical: ScrollBar {}
        delegate: ColumnLayout {
            id: deviceRow
            required property var modelData
            width: ListView.view.width
            spacing: 4
            AeroButton {
                Layout.fillWidth: true
                implicitHeight: 57
                leftPadding: 12
                rightPadding: 12
                selected: deviceRow.modelData.connected
                hint: deviceRow.modelData.name
                contentItem: RowLayout {
                    Image {
                        source: Quickshell.iconPath(deviceRow.modelData.icon, "preferences-system-bluetooth")
                        sourceSize: Qt.size(28, 28)
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 28
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3
                        AeroText {
                            Layout.fillWidth: true
                            text: deviceRow.modelData.name
                            font.pixelSize: 14
                        }
                        AeroText {
                            Layout.fillWidth: true
                            font.pixelSize: 11
                            color: deviceRow.modelData.connected ? Theme.green : Theme.muted
                            text: deviceRow.modelData.pairing ? "Parowanie…" : deviceRow.modelData.state === BluetoothDeviceState.Connecting ? "Łączenie…" : deviceRow.modelData.connected ? "Połączono" + (deviceRow.modelData.batteryAvailable ? " · " + Math.round(deviceRow.modelData.battery * 100) + "%" : "") : deviceRow.modelData.paired ? "Sparowane · kliknij, aby połączyć" : "Kliknij, aby sparować"
                        }
                    }
                }
                onClicked: {
                    if (deviceRow.modelData.connected)
                        deviceRow.modelData.disconnect();
                    else if (deviceRow.modelData.paired)
                        deviceRow.modelData.connect();
                    else {
                        root.pending = deviceRow.modelData;
                        deviceRow.modelData.pair();
                    }
                }
            }
            RowLayout {
                visible: deviceRow.modelData.paired || deviceRow.modelData.pairing
                AeroButton {
                    text: deviceRow.modelData.pairing ? "Anuluj" : deviceRow.modelData.trusted ? "Zaufane" : "Ufaj urządzeniu"
                    implicitHeight: 27
                    selected: deviceRow.modelData.trusted
                    onClicked: {
                        if (deviceRow.modelData.pairing)
                            deviceRow.modelData.cancelPair();
                        else
                            deviceRow.modelData.trusted = !deviceRow.modelData.trusted;
                    }
                }
                AeroButton {
                    text: "Usuń parę"
                    implicitHeight: 27
                    visible: deviceRow.modelData.paired
                    onClicked: deviceRow.modelData.forget()
                }
            }
        }
    }
    Connections {
        target: root.pending
        function onPairedChanged() {
            if (root.pending?.paired) {
                root.pending.trusted = true;
                root.pending.connect();
                root.pending = null;
            }
        }
    }
    AeroText {
        Layout.fillWidth: true
        wrapMode: Text.Wrap
        elide: Text.ElideNone
        color: Theme.muted
        text: "Potwierdzenie kodu PIN pojawi się w oknie parowania. Pozostałe opcje są w menedżerze urządzeń."
        font.pixelSize: 12
    }
    AeroButton {
        Layout.fillWidth: true
        text: "Menedżer urządzeń Bluetooth"
        iconName: "preferences-system-bluetooth"
        onClicked: Desktop.run(["blueman-manager"])
    }
}

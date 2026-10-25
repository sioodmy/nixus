import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import ".." 1.0 as Aero

Rectangle {
    id: root
    required property var auth
    color: "#190d30"
    readonly property real contentScale: Math.min(1, width / 520, height / 580)
    SystemClock { id: clock; precision: SystemClock.Minutes }
    Image {
        anchors.fill: parent
        source: Aero.Theme.wallpaper
        fillMode: Image.PreserveAspectCrop
        opacity: 0.63
    }
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0; color: "#60291b49" }
            GradientStop { position: 0.55; color: "#352b1745" }
            GradientStop { position: 1; color: "#dd1b102f" }
        }
    }
    // The login controls sit directly on the desktop, as in Vista/Windows 7.
    Item {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -35 * root.contentScale
        width: 420
        height: 340
        scale: root.contentScale
        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 0
            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 140; height: 140
                Rectangle {
                    x: 1; y: 4; width: 138; height: 138; radius: 9
                    color: "#500c0617"
                }
                Rectangle {
                    anchors.fill: parent
                    radius: 8
                    border.color: "#efdcff"
                    gradient: Gradient {
                        GradientStop { position: 0; color: "#f0e6f7" }
                        GradientStop { position: 0.08; color: "#a99ab9" }
                        GradientStop { position: 0.5; color: "#675675" }
                        GradientStop { position: 0.94; color: "#c5b4d7" }
                        GradientStop { position: 1; color: "#ede0fa" }
                    }
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 5
                        radius: 4
                        border.color: "#422657"
                        gradient: Gradient {
                            GradientStop { position: 0; color: "#b6a2da" }
                            GradientStop { position: 0.48; color: "#77649e" }
                            GradientStop { position: 0.5; color: "#493464" }
                            GradientStop { position: 1; color: "#9b7abe" }
                        }
                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: 22; width: 38; height: 38; radius: 19
                            gradient: Gradient {
                                GradientStop { position: 0; color: "#fffbff" }
                                GradientStop { position: 1; color: "#c9b6e0" }
                            }
                        }
                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: 66; width: 76; height: 49; radius: 27
                            gradient: Gradient {
                                GradientStop { position: 0; color: "#f9efff" }
                                GradientStop { position: 1; color: "#b09aca" }
                            }
                        }
                        Rectangle {
                            anchors { top: parent.top; left: parent.left; right: parent.right; margins: 2 }
                            height: 55
                            radius: 3
                            gradient: Gradient {
                                GradientStop { position: 0; color: "#60ffffff" }
                                GradientStop { position: 1; color: "#05ffffff" }
                            }
                        }
                    }
                }
            }
            Item { width: 1; height: 18 }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Quickshell.env("USER") || "Użytkownik"
                color: "#fff5ff"
                font { family: Aero.Theme.font; pixelSize: 26 }
                textFormat: Text.PlainText
                style: Text.Raised
                styleColor: "#7021133a"
            }
            Item { width: 1; height: 4 }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Zablokowany"
                color: "#e3d7ef"
                font { family: Aero.Theme.font; pixelSize: 13 }
            }
            Item { width: 1; height: 20 }
            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 260
                height: 34
                TextField {
                    id: password
                    anchors { left: parent.left; right: parent.right; rightMargin: 1; verticalCenter: parent.verticalCenter }
                    height: 30
                    leftPadding: 9
                    rightPadding: 10
                    color: "#30233d"
                    placeholderTextColor: "#7a7183"
                    selectionColor: "#9e80c3"
                    selectedTextColor: "white"
                    font { family: Aero.Theme.font; pixelSize: 13 }
                    placeholderText: root.auth.responseVisible ? "Odpowiedź" : "Hasło"
                    echoMode: root.auth.responseVisible ? TextInput.Normal : TextInput.Password
                    passwordCharacter: "●"
                    enabled: !root.auth.busy
                    selectByMouse: true
                    inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
                    onAccepted: root.auth.submit(text)
                    Component.onCompleted: forceActiveFocus()
                    Keys.onEscapePressed: clear()
                    onEnabledChanged: if (enabled) forceActiveFocus()
                    background: Rectangle {
                        radius: 3
                        color: "#faf6fd"
                        border.color: password.activeFocus ? "#b69bd6" : "#79638e"
                        Rectangle {
                            anchors.fill: parent; anchors.margins: 1
                            radius: 2; color: "transparent"; border.color: "#d5cbdc"
                        }
                    }
                }
                Button {
                    id: submit
                    anchors { left: parent.right; leftMargin: 9; verticalCenter: parent.verticalCenter }
                    width: 34; height: 34
                    enabled: !root.auth.busy && password.length > 0
                    hoverEnabled: true
                    onClicked: root.auth.submit(password.text)
                    Accessible.name: "Odblokuj"
                    background: Rectangle {
                        radius: 17
                        border.color: submit.activeFocus || submit.hovered ? "#ffffff" : "#d7c5ec"
                        gradient: Gradient {
                            GradientStop { position: 0; color: submit.down ? "#77608d" : "#dccff1" }
                            GradientStop { position: 0.48; color: "#9b80bf" }
                            GradientStop { position: 0.5; color: "#50316f" }
                            GradientStop { position: 1; color: "#b28bd5" }
                        }
                        Rectangle {
                            anchors.fill: parent; anchors.margins: 2
                            radius: 15; color: "transparent"; border.color: "#997aab"
                        }
                    }
                    contentItem: Text {
                        text: root.auth.busy ? "…" : "➜"
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font { family: Aero.Theme.font; pixelSize: 22 }
                        style: Text.Raised; styleColor: "#78528c"
                    }
                }
            }
            Item { width: 1; height: 16 }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 360
                text: root.auth.status === "Sesja zablokowana" ? "" : root.auth.status
                textFormat: Text.PlainText
                color: "#f1e2ff"
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                font { family: Aero.Theme.font; pixelSize: 13 }
            }
        }
    }
    Rectangle {
        anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
        height: 77
        color: "#30170d29"
        Rectangle { anchors.top: parent.top; width: parent.width; height: 1; color: "#15e4d3ff" }
    }
    Column {
        anchors { left: parent.left; bottom: parent.bottom; leftMargin: 30; bottomMargin: 19 }
        spacing: 3
        Text {
            text: Qt.formatDateTime(clock.date, "HH:mm")
            color: "#e7daf5"
            font { family: Aero.Theme.font; pixelSize: 17 }
        }
        Text {
            visible: root.width >= 600
            text: Qt.locale("pl_PL").toString(clock.date, "dddd, d MMMM")
            color: "#bda8cf"
            font { family: Aero.Theme.font; pixelSize: 11 }
        }
    }
    Row {
        anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter; bottomMargin: 28 }
        spacing: 9
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 23; height: 23; radius: 12
            border.color: "#d9c5f1"
            gradient: Gradient {
                GradientStop { position: 0; color: "#c9b2e3" }
                GradientStop { position: 0.48; color: "#7e5e9d" }
                GradientStop { position: 0.5; color: "#3e2356" }
                GradientStop { position: 1; color: "#a87bce" }
            }
            Text { anchors.centerIn: parent; text: "✧"; color: "#f5e9ff"; font.pixelSize: 23 }
        }
        Text {
            text: "Amethyst Aero"
            color: "#e7d9f5"
            font { family: Aero.Theme.font; pixelSize: root.width >= 600 ? 21 : 16; weight: Font.Light }
            style: Text.Raised; styleColor: "#501a0c2b"
        }
    }
    Aero.BatteryGauge {
        anchors { right: parent.right; bottom: parent.bottom; rightMargin: 30; bottomMargin: 29 }
        visible: Aero.BatteryInfo.available
        level: Aero.BatteryInfo.level
        known: Aero.BatteryInfo.known
        charging: Aero.BatteryInfo.charging
        plugged: Aero.BatteryInfo.plugged
        low: Aero.BatteryInfo.low
        critical: Aero.BatteryInfo.critical
    }
    Connections {
        target: root.auth
        function onClearInputs() { password.clear(); }
    }
}

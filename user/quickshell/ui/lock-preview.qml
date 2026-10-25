// Visual preview only: no session lock, PAM, or route to unlock a real session.
import QtQuick
import "lock"
import Quickshell

ShellRoot {
    QtObject {
        id: previewAuth
        property bool busy: false
        property bool responseVisible: false
        property string status: "Sesja zablokowana"
        signal clearInputs()
        function submit(value: string): void {
            clearInputs();
            status = "Podgląd — uwierzytelnianie jest wyłączone";
        }
    }
    FloatingWindow {
        title: "Amethyst Aero · podgląd blokady"
        implicitWidth: 1440
        implicitHeight: 900
        LockContent { anchors.fill: parent; auth: previewAuth }
    }
}

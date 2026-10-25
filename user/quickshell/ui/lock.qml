import QtQuick
import "lock"
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam

ShellRoot {
    id: root
    property string status: "Sesja zablokowana"
    property string pendingResponse: ""
    property bool hasPendingResponse: false
    property bool authenticated: false
    readonly property bool busy: pam.active && !pam.responseRequired
    readonly property bool responseVisible: pam.responseRequired && pam.responseVisible
    signal clearInputs()

    function submit(value: string): void {
        if (!lock.secure || authenticated || busy || value.length === 0)
            return;
        status = "Sprawdzanie…";
        if (pam.responseRequired) {
            pam.respond(value);
        } else {
            pendingResponse = value;
            hasPendingResponse = true;
            if (!pam.start()) {
                pendingResponse = "";
                hasPendingResponse = false;
                status = "Nie można rozpocząć uwierzytelniania.";
            }
        }
        clearInputs();
    }

    PamContext {
        id: pam
        config: "aero-lock"
        onPamMessage: {
            if (responseRequired && root.hasPendingResponse) {
                const response = root.pendingResponse;
                root.pendingResponse = "";
                root.hasPendingResponse = false;
                respond(response);
            } else if (responseRequired) {
                root.status = message || "Wpisz hasło";
                root.clearInputs();
            } else if (message) {
                root.status = message;
            }
        }
        onCompleted: result => {
            root.pendingResponse = "";
            root.hasPendingResponse = false;
            root.clearInputs();
            if (result === PamResult.Success) {
                root.authenticated = true;
                lock.locked = false;
                lockedHint.command = ["busctl", "call", "org.freedesktop.login1", "/org/freedesktop/login1/session/auto", "org.freedesktop.login1.Session", "SetLockedHint", "b", "false"];
                lockedHint.running = true;
            } else {
                root.status = result === PamResult.Failed ? "Nieprawidłowe hasło. Spróbuj ponownie." : "Błąd uwierzytelniania. Spróbuj ponownie.";
            }
        }
    }
    Process {
        id: lockedHint
        command: ["busctl", "call", "org.freedesktop.login1", "/org/freedesktop/login1/session/auto", "org.freedesktop.login1.Session", "SetLockedHint", "b", "true"]
        onExited: if (root.authenticated) Qt.quit()
    }
    WlSessionLock {
        id: lock
        locked: true
        onSecureChanged: if (secure) lockedHint.running = true
        WlSessionLockSurface {
            color: "#10091d"
            LockContent {
                anchors.fill: parent
                auth: root
            }
        }
    }
    // A rejected request (e.g. another locker owns the session) must not linger.
    Timer {
        interval: 5000
        running: true
        onTriggered: if (!lock.secure) Qt.quit()
    }
}

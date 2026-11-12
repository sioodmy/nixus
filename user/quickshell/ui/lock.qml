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
    property bool fingerprintMode: false
    property bool checking: false
    readonly property bool busy: checking
    readonly property bool responseVisible: pam.responseRequired && pam.responseVisible
    signal clearInputs()

    function startFingerprint(): void {
        if (!lock.secure || authenticated)
            return;
        pam.abort();
        fingerprintMode = true;
        checking = false;
        status = "Przyłóż palec do Touch ID lub wpisz hasło.";
        pam.config = "aero-lock";
        if (!pam.start()) {
            fingerprintMode = false;
            status = "Czytnik linii papilarnych jest niedostępny. Wpisz hasło.";
            startPassword();
        }
    }

    function startPassword(): void {
        if (!lock.secure || authenticated)
            return;
        pam.abort();
        fingerprintMode = false;
        checking = false;
        status = "Wpisz hasło.";
        pam.config = "aero-lock-password";
        if (!pam.start())
            status = "Nie można rozpocząć uwierzytelniania.";
    }

    function submit(value: string): void {
        if (!lock.secure || authenticated || value.length === 0)
            return;

        // The password prompt is already open (fingerprint failed or skipped).
        if (pam.active && pam.responseRequired) {
            checking = true;
            status = "Sprawdzanie…";
            pam.respond(value);
            clearInputs();
            return;
        }

        // The sensor is still waiting, or the previous attempt finished:
        // switch to the password-only PAM service and answer its prompt.
        pendingResponse = value;
        hasPendingResponse = true;
        checking = true;
        pam.abort();
        fingerprintMode = false;
        status = "Sprawdzanie…";
        pam.config = "aero-lock-password";
        if (!pam.start()) {
            pendingResponse = "";
            hasPendingResponse = false;
            checking = false;
            status = "Nie można rozpocząć uwierzytelniania.";
        }
        clearInputs();
    }

    PamContext {
        id: pam
        config: "aero-lock"

        onPamMessage: {
            const text = pam.message;

            if (pam.responseRequired && root.hasPendingResponse) {
                const response = root.pendingResponse;
                root.pendingResponse = "";
                root.hasPendingResponse = false;
                root.checking = true;
                respond(response);
            } else if (pam.responseRequired) {
                root.fingerprintMode = false;
                root.checking = false;
                root.status = text || "Wpisz hasło";
                root.clearInputs();
            } else if (text) {
                const lower = text.toLowerCase();
                if (lower.indexOf("finger") !== -1 || lower.indexOf("touch") !== -1) {
                    root.fingerprintMode = true;
                    root.status = "Przyłóż palec do Touch ID…";
                } else {
                    root.status = text;
                }
            }
        }

        onCompleted: result => {
            root.pendingResponse = "";
            root.hasPendingResponse = false;
            root.checking = false;
            root.clearInputs();
            if (result === PamResult.Success) {
                root.authenticated = true;
                lock.locked = false;
                lockedHint.command = ["busctl", "call", "org.freedesktop.login1", "/org/freedesktop/login1/session/auto", "org.freedesktop.login1.Session", "SetLockedHint", "b", "false"];
                lockedHint.running = true;
            } else {
                root.fingerprintMode = false;
                root.status = result === PamResult.Failed ? "Błąd: nieprawidłowe hasło. Spróbuj ponownie lub użyj Touch ID." : "Błąd uwierzytelniania. Spróbuj ponownie.";
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
        onSecureChanged: {
            if (secure) {
                lockedHint.running = true;
                root.startFingerprint();
            }
        }
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

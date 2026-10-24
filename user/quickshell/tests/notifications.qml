// Run under dbus-run-session, with AERO_PREVIEW=1 and a test Wayland display.
import QtQuick
import Quickshell

ShellRoot {
    Component.onCompleted: {
        deadline.start();
        Notices.startServer();
        sender.start();
    }
    Timer {
        id: sender
        interval: 300
        onTriggered: Quickshell.execDetached(["notify-send", "--app-name=Aero test", "--expire-time=900", "Notification integration", "<b>Plain text body</b>"])
    }
    Connections {
        target: Notices
        function onHistoryChanged() {
            if (Notices.history.length === 0)
                return;
            if (Notices.history.length !== 1 || Notices.history[0].title !== "Notification integration") {
                console.error("Notification integration failed");
                Qt.exit(1);
                return;
            }
            verify.start();
        }
    }
    Timer {
        id: verify
        interval: 100
        onTriggered: {
            if (Notices.active.length !== 1 || Notices.active[0].body !== "<b>Plain text body</b>") {
                console.error("Notification tracking failed");
                Qt.exit(1);
                return;
            }
            Notices.clear();
            if (Notices.count !== 0) {
                console.error("Notification clear failed");
                Qt.exit(1);
                return;
            }
            console.log("Notification D-Bus integration passed");
            Qt.quit();
        }
    }
    Timer {
        id: deadline
        interval: 5000
        onTriggered: {
            console.error("Notification integration timed out");
            Qt.exit(1);
        }
    }
}

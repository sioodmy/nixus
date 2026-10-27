import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {
    Variants {
        model: Quickshell.screens
        Scope {
            required property var modelData
            Bar {
                screen: modelData
            }
            Flyout {
                screen: modelData
                outputName: modelData.name
            }
            Toasts {
                screen: modelData
                primary: modelData === Quickshell.screens[0]
            }
            Osd {
                screen: modelData
                outputName: modelData.name
            }
        }
    }
    Authentication {}
    DesktopPet {}
    IpcHandler {
        target: "aero"
        function hamster(): void {
            Hamster.toggle();
        }
        function screenshot(path: string): void {
            Hamster.screenshot(path);
        }
        function launcher(): void {
            Desktop.toggle("launcher");
        }
        function wifi(): void {
            Desktop.toggle("wifi");
        }
        function bluetooth(): void {
            Desktop.toggle("bluetooth");
        }
        function audio(): void {
            Desktop.toggle("audio");
        }
        function notifications(): void {
            Desktop.toggle("notifications");
        }
        function session(): void {
            Desktop.toggle("session");
        }
        function close(): void {
            Desktop.close();
        }
        function showOsd(kind: string, percent: int, muted: bool): void {
            Feedback.show(kind, percent, muted);
        }
        function openPage(page: string): void {
            if (["launcher", "wifi", "bluetooth", "audio", "notifications", "session"].indexOf(page) !== -1)
                Desktop.open(page);
        }
        function status(): string {
            return JSON.stringify({
                page: Desktop.page,
                screen: Desktop.screenName,
                applications: Apps.indexed.length,
                preview: Desktop.preview,
                osd: {
                    active: Feedback.active,
                    kind: Feedback.kind,
                    percent: Feedback.percent,
                    muted: Feedback.muted
                }
            });
        }
    }
}

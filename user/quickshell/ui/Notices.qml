pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root
    property var history: []
    readonly property int count: history.length
    property var server: null
    readonly property var active: server ? server.trackedNotifications.values : []
    // Preview mode never registers on the user's notification bus.
    property Component serverComponent: Component {
        NotificationServer {
            actionsSupported: true
            bodySupported: true
            bodyMarkupSupported: false
            imageSupported: true
            onNotification: notification => {
                notification.tracked = true;
                var record = {
                    id: notification.id,
                    app: notification.appName,
                    title: notification.summary,
                    body: notification.body,
                    time: Qt.formatDateTime(new Date(), "HH:mm")
                };
                root.history = [record].concat(root.history.filter(n => n.id !== record.id)).slice(0, 100);
            }
        }
    }
    function startServer() {
        if (!server)
            server = serverComponent.createObject(root);
    }
    Component.onCompleted: if (!Desktop.preview)
        startServer()
    function clear() {
        history = [];
        active.slice().forEach(n => n.dismiss());
    }
}

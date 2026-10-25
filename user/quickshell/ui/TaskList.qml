import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

ListView {
    id: root
    objectName: "workspace-tasks"
    required property string outputName
    // Groups are rebuilt when membership, monitor assignment or workspace state
    // changes. Every window gets a task, including repeated application IDs.
    readonly property var groups: {
        const workspaces = Hyprland.workspaces.values;
        if (!workspaces.length) {
            const windows = ToplevelManager.toplevels.values.filter(window => !window.parent);
            return [{workspace: null, windows: windows, label: "01", current: true}];
        }
        return workspaces.filter(workspace => workspace.monitor?.name === outputName)
            .map(workspace => ({
                workspace: workspace,
                windows: workspace.toplevels.values.filter(window => !window.wayland?.parent),
                label: workspace.id > 0 ? String(workspace.name).padStart(2, "0") : workspace.name.replace("special:", ""),
                current: workspace.active
            }))
            .filter(group => group.windows.length > 0 || group.current);
    }
    model: groups
    spacing: 7
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    ScrollBar.vertical: ScrollBar {
        width: 3
        policy: ScrollBar.AsNeeded
    }
    currentIndex: groups.findIndex(group => group.current)
    onCurrentIndexChanged: if (currentIndex >= 0)
        positionViewAtIndex(currentIndex, ListView.Contain)
    delegate: TaskGroup {
        required property var modelData
        width: ListView.view.width
        workspace: modelData.workspace
        windows: modelData.windows
        label: modelData.label
        current: modelData.current
        onWorkspaceRequested: if (workspace) workspace.activate()
        onWindowRequested: window => {
            const handle = window.wayland || window;
            if (typeof handle.activate === "function")
                handle.activate();
            else if (window.address) {
                const address = "address:0x" + window.address;
                Hyprland.dispatch(Hyprland.usingLua
                    ? "hl.dsp.focus({window=" + JSON.stringify(address) + "})"
                    : "focuswindow " + address);
            }
        }
    }
}

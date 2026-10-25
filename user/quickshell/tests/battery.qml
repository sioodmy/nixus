import QtQuick
import Quickshell
import Quickshell.Services.UPower

ShellRoot {
    id: root
    property int stage: 0
    QtObject {
        id: device
        property bool ready: true
        property bool isLaptopBattery: true
        property bool isPresent: true
        property int state: UPowerDeviceState.Discharging
        property real percentage: 0.75
        property real timeToEmpty: 5400
        property real timeToFull: 0
    }
    function check(condition, message) {
        if (!condition) throw new Error(message);
    }
    Component.onCompleted: {
        BatteryInfo.device = device;
        BatteryInfo.onBattery = true;
    }
    Timer {
        interval: 40
        repeat: true
        running: true
        onTriggered: {
            switch (root.stage++) {
            case 0:
                root.check(BatteryInfo.available && BatteryInfo.percent === 75, "normalized UPower percentage");
                root.check(BatteryInfo.estimate.includes("1 godz. 30 min"), "discharge estimate");
                device.state = UPowerDeviceState.Charging;
                device.percentage = 0.5; device.timeToFull = 3600;
                BatteryInfo.onBattery = false;
                break;
            case 1:
                root.check(BatteryInfo.charging && BatteryInfo.plugged, "charging and AC");
                root.check(BatteryInfo.estimate.includes("Do pełna"), "charge estimate");
                device.state = UPowerDeviceState.FullyCharged;
                device.percentage = 1;
                break;
            case 2:
                root.check(BatteryInfo.full && !BatteryInfo.charging && BatteryInfo.percent === 100, "full is not charging");
                root.check(BatteryInfo.estimate === "", "full has no stale estimate");
                device.state = UPowerDeviceState.PendingCharge;
                device.percentage = 0.8;
                break;
            case 3:
                root.check(!BatteryInfo.charging && BatteryInfo.plugged && BatteryInfo.stateText.includes("wstrzymane"), "plugged with charging paused");
                device.state = UPowerDeviceState.Discharging;
                device.percentage = 0.05; device.timeToEmpty = 0;
                BatteryInfo.onBattery = true;
                break;
            case 4:
                root.check(BatteryInfo.critical && BatteryInfo.percent === 5, "critical level");
                root.check(BatteryInfo.estimate === "", "unknown time must not show zero minutes");
                device.percentage = 0.18;
                break;
            case 5:
                root.check(BatteryInfo.low && !BatteryInfo.critical, "low level");
                device.state = UPowerDeviceState.Unknown;
                break;
            case 6:
                root.check(!BatteryInfo.known && BatteryInfo.percentageText === "—", "unknown state");
                device.state = UPowerDeviceState.Discharging;
                device.percentage = NaN;
                break;
            case 7:
                root.check(!BatteryInfo.known, "invalid percentage");
                device.isPresent = false;
                break;
            case 8:
                root.check(!BatteryInfo.available, "battery removed/desktop");
                console.log("PASS: battery discharge, charge, full, paused, low/critical, missing data and removal");
                BatteryInfo.device = null;
                Qt.quit();
            }
        }
    }
}

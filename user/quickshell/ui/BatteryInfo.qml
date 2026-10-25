pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.UPower

Singleton {
    id: root
    property var device: UPower.displayDevice
    property bool onBattery: UPower.onBattery
    readonly property bool available: {
        if (!device) return false;
        return Boolean(device.ready && device.isLaptopBattery && device.isPresent);
    }
    readonly property int state: available ? device.state : UPowerDeviceState.Unknown
    readonly property bool known: available && state !== UPowerDeviceState.Unknown && Number.isFinite(device.percentage) && device.percentage >= 0 && device.percentage <= 1
    readonly property real level: known ? device.percentage : 0
    readonly property int percent: Math.round(level * 100)
    readonly property bool charging: state === UPowerDeviceState.Charging
    readonly property bool full: state === UPowerDeviceState.FullyCharged
    readonly property bool plugged: available && !onBattery
    readonly property bool critical: known && !plugged && level <= 0.10
    readonly property bool low: known && !plugged && level <= 0.20
    readonly property string percentageText: known ? percent + "%" : "—"
    readonly property string stateText: {
        if (!known) return "Stan baterii niedostępny";
        switch (state) {
        case UPowerDeviceState.Charging: return "Ładowanie";
        case UPowerDeviceState.FullyCharged: return "Bateria naładowana";
        case UPowerDeviceState.PendingCharge: return "Podłączono · ładowanie wstrzymane";
        case UPowerDeviceState.PendingDischarge: return "Zasilanie z baterii · oczekiwanie";
        case UPowerDeviceState.Empty: return "Bateria rozładowana";
        case UPowerDeviceState.Discharging: return plugged ? "Podłączono · bateria rozładowuje się" : critical ? "Krytycznie niski poziom baterii" : low ? "Niski poziom baterii" : "Zasilanie z baterii";
        default: return "Stan baterii niedostępny";
        }
    }
    readonly property string estimate: {
        if (!known) return "";
        if (charging && device.timeToFull > 0)
            return "Do pełna około " + duration(device.timeToFull);
        if (state === UPowerDeviceState.Discharging && device.timeToEmpty > 0)
            return "Pozostało około " + duration(device.timeToEmpty);
        return "";
    }
    readonly property string summary: percentageText + " · " + stateText + (estimate ? "\n" + estimate : "")
    function duration(seconds: real): string {
        const minutes = Math.max(1, Math.round(seconds / 60));
        const hours = Math.floor(minutes / 60);
        return (hours ? hours + " godz. " : "") + (minutes % 60 ? minutes % 60 + " min" : "");
    }
}

// Native layer surfaces, pointer movement and file drag/drop in isolated Wayland.
import assert from 'node:assert/strict';
import {spawn, execFile} from 'node:child_process';
import {promisify} from 'node:util';
import fs from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import net from 'node:net';
import {fileURLToPath} from 'node:url';
const exec = promisify(execFile);
const directory = await fs.mkdtemp(path.join(os.tmpdir(), 'aero-hamster-test-'));
const qs = process.env.QS_BINARY || 'qs';
const sway = process.env.SWAY_BINARY || 'sway';
const children = [];
let pointerSocket;
async function waitFor(callback, description) {
    let lastError;
    for (let i = 0; i < 80; i++) {
        try { const result = await callback(); if (result) return result; } catch (error) { lastError = error; }
        await new Promise(resolve => setTimeout(resolve, 100));
    }
    throw new Error(`Timed out: ${description}`, {cause: lastError});
}
function start(binary, args, env) {
    const child = spawn(binary, args, {env, stdio: ['ignore', 'pipe', 'pipe']});
    child.logs = '';
    child.stdout.on('data', data => child.logs += data);
    child.stderr.on('data', data => child.logs += data);
    child.on('error', error => child.logs += String(error));
    children.push(child);
    return child;
}
try {
    const ui = path.join(directory, 'ui');
    await fs.cp(fileURLToPath(new URL('../ui', import.meta.url)), ui, {recursive: true});
    const fullShell = await fs.readFile(path.join(ui, 'shell.qml'), 'utf8');
    await fs.writeFile(path.join(ui, 'shell.qml'), `import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
ShellRoot {
    id: test
    property int clicks: 0
    property var received: []
    DesktopPet { id: pet }
    PanelWindow {
        id: fixtureWindow
        anchors { top: true; left: true }
        margins { top: 20; left: 20 }
        implicitWidth: 140; implicitHeight: 160
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        Rectangle {
            id: source
            width: 140; height: 70; color: "#b28dd2"
            Drag.dragType: Drag.Automatic
            Drag.active: sourceDrag.active
            Drag.supportedActions: Qt.CopyAction
            Drag.mimeData: ({"text/uri-list": Quickshell.env("AERO_TEST_FILE") + "\\r\\n"})
            Text { anchors.centerIn: parent; text: "Drag test file" }
            MouseArea { anchors.fill: parent; onClicked: test.clicks++ }
            DragHandler { id: sourceDrag; target: null }
        }
        Rectangle {
            y: 80; width: 140; height: 80; color: "#a8d8b0"
            Text { anchors.centerIn: parent; text: "Drop here" }
            DropArea {
                anchors.fill: parent
                onDropped: drop => { test.received = drop.urls.map(url => url.toString()); drop.accept(Qt.CopyAction); }
            }
        }
    }
    IpcHandler {
        target: "test"
        function status(): string { return JSON.stringify({ready: Hamster.ready, items: Hamster.items, position: Hamster.position, panel: Hamster.panelOpen, error: Hamster.error, x: pet.petX, y: pet.petY, clicks: test.clicks, received: test.received, animation: pet.animation, animationFrames: pet.animationFrames, spriteLoaded: pet.spriteLoaded}); }
        function add(url: string): void { Hamster.add([url]); }
        function screenshot(url: string): void { Hamster.screenshot(url); }
        function move(x: real, y: real): void { Hamster.move(x, y, Quickshell.screens[0].name); }
        function panel(): void { Hamster.toggle(); }
        function clear(): void { Hamster.send({action: "clear"}); }
        function hideFixture(): void { fixtureWindow.visible = false; }
    }
}`);
    const runtime = path.join(directory, 'runtime');
    await fs.mkdir(runtime, {mode: 0o700});
    const fixture = path.join(directory, 'Plik testowy.txt');
    await fs.writeFile(fixture, 'a file for the hamster');
    const fixtureUrl = new URL(`file://${fixture}`).href;
    const env = {...process.env, XDG_RUNTIME_DIR: runtime, XDG_STATE_HOME: path.join(directory, 'state'), AERO_TEST_FILE: fixtureUrl, AERO_PREVIEW: '1', QT_QUICK_CONTROLS_STYLE: 'Basic'};
    delete env.WAYLAND_DISPLAY; delete env.SWAYSOCK; delete env.HYPRLAND_INSTANCE_SIGNATURE;
    const config = path.join(directory, 'sway.conf');
    await fs.writeFile(config, `output * mode 1024x768\nseat seat0 fallback true\noutput * bg ${fileURLToPath(new URL('../ui/assets/wallpaper.png', import.meta.url))} fill\n`);
    start(sway, ['--unsupported-gpu', '-c', config], {...env, WLR_BACKENDS: 'headless', WLR_RENDERER: 'pixman', WLR_LIBINPUT_NO_DEVICES: '1'});
    env.WAYLAND_DISPLAY = await waitFor(async () => (await fs.readdir(runtime)).find(name => /^wayland-\d+$/.test(name)), 'Sway startup');
    env.SWAYSOCK = path.join(runtime, await waitFor(async () => (await fs.readdir(runtime)).find(name => /^sway-ipc.*sock$/.test(name)), 'Sway IPC'));
    const shell = start(qs, ['-p', ui, '--no-color'], env);
    const call = async (method, ...args) => (await exec(qs, ['-p', ui, 'ipc', 'call', 'test', method, ...args.map(String)], {env})).stdout.trim();
    const status = async () => JSON.parse(await call('status'));
    await waitFor(async () => (await status()).ready, 'backend startup');
    await waitFor(async () => (await status()).spriteLoaded, 'original ChomikBox idle image');
    // aero-screenshot reports its file through this same IPC path.
    await call('screenshot', fixtureUrl);
    await waitFor(async () => {
        const state = await status();
        return state.animation === 'screenshot' && state.animationFrames >= 10 && state.spriteLoaded;
    }, 'screenshot reaction animation');
    await call('clear');
    await waitFor(async () => (await status()).items.length === 0, 'clearing the screenshot reference');
    await call('move', 0.5, 0.7);
    await waitFor(async () => (await status()).position.x === 0.5, 'moving hamster');
    if (process.env.AERO_CAPTURE_DIR) {
        await fs.mkdir(process.env.AERO_CAPTURE_DIR, {recursive: true});
        await exec('grim', [path.join(process.env.AERO_CAPTURE_DIR, 'hamster-before.png')], {env});
    }
    // Keep a real virtual pointer attached: Sway's cursor IPC alone does not
    // advertise a pointer to Qt when the headless seat has no input devices.
    pointerSocket = net.createConnection(path.join(runtime, env.WAYLAND_DISPLAY));
    await new Promise((resolve, reject) => { pointerSocket.once('connect', resolve); pointerSocket.once('error', reject); });
    const uints = values => { const data = Buffer.alloc(values.length * 4); values.forEach((value, i) => data.writeUInt32LE(value >>> 0, i * 4)); return data; };
    const send = (id, opcode, body = Buffer.alloc(0)) => pointerSocket.write(Buffer.concat([uints([id, ((body.length + 8) << 16) | opcode]), body]));
    let buffer = Buffer.alloc(0), manager;
    pointerSocket.on('data', chunk => {
        buffer = Buffer.concat([buffer, chunk]);
        while (buffer.length >= 8) {
            const size = buffer.readUInt32LE(4) >>> 16;
            if (buffer.length < size) break;
            const message = buffer.subarray(0, size);
            buffer = buffer.subarray(size);
            if (message.readUInt32LE(0) === 2 && (message.readUInt32LE(4) & 0xffff) === 0) {
                const length = message.readUInt32LE(12);
                if (message.toString('utf8', 16, 16 + length - 1) === 'zwlr_virtual_pointer_manager_v1') manager = message.readUInt32LE(8);
            }
        }
    });
    send(1, 1, uints([2]));
    await waitFor(() => manager, 'virtual pointer protocol');
    const name = Buffer.from('zwlr_virtual_pointer_manager_v1\0');
    const padded = Buffer.alloc(Math.ceil(name.length / 4) * 4); name.copy(padded);
    send(2, 0, Buffer.concat([uints([manager, name.length]), padded, uints([1, 3])]));
    send(3, 0, uints([0, 4]));
    await new Promise(resolve => setTimeout(resolve, 200));
    const pointer = async command => {
        const [action, x, y] = command.split(' ');
        const now = Date.now() >>> 0;
        if (action === 'set') send(4, 1, uints([now, Number(x), Number(y), 1024, 768]));
        else send(4, 2, uints([now, 0x110, action === 'press' ? 1 : 0]));
        send(4, 4);
        await new Promise(resolve => setTimeout(resolve, 100));
    };
    await pointer('set 60 50');
    await pointer('press button1');
    await pointer('release button1');
    await waitFor(async () => (await status()).clicks === 1, 'click through the transparent desktop surface');
    await pointer('press button1');
    await pointer('set 85 55');
    await pointer('set 510 510');
    await waitFor(async () => {
        const state = await status();
        return state.animation.startsWith('drag-') && state.animationFrames >= 10 && state.spriteLoaded;
    }, 'original drag animation and animated WebP decoder');
    await pointer('release button1');
    await waitFor(async () => (await status()).items.length === 1, 'native file drop onto the hamster');
    await waitFor(async () => {
        const state = await status();
        return state.animation === 'drop' && state.animationFrames === 130 && state.spriteLoaded;
    }, 'original file acceptance animation');
    await pointer('set 510 510');
    await pointer('press button1');
    await pointer('release button1');
    await waitFor(async () => (await status()).panel, 'opening the stash by clicking the mascot');
    await pointer('set 220 405');
    await pointer('press button1');
    await pointer('set 245 405');
    await pointer('set 60 140');
    await pointer('release button1');
    await waitFor(async () => (await status()).received.length === 1, 'native file drag out of the shelf');
    assert.equal(new URL((await status()).received[0]).href, fixtureUrl);
    if (process.env.AERO_CAPTURE_DIR) {
        await call('hideFixture');
        await new Promise(resolve => setTimeout(resolve, 150));
        await fs.mkdir(process.env.AERO_CAPTURE_DIR, {recursive: true});
        await exec('grim', [path.join(process.env.AERO_CAPTURE_DIR, 'hamster.png')], {env});
    }
    await call('panel');
    await pointer('set 510 510');
    await pointer('press button1');
    await pointer('set 360 430');
    await waitFor(async () => {
        const state = await status();
        return state.animation.startsWith('move-') && state.spriteLoaded;
    }, 'original movement animation');
    await pointer('release button1');
    await waitFor(async () => (await status()).position.x < 0.4, 'pointer drag and persisted position');
    await call('clear');
    await waitFor(async () => (await status()).items.length === 0, 'clearing references');
    assert.equal(await fs.readFile(fixture, 'utf8'), 'a file for the hamster');
    assert.doesNotMatch(shell.logs, /ReferenceError|TypeError|Binding loop|Unable to assign|startDrag\(\) drag must be active|Error Reading Animated Image File|Cannot open:|ERROR/);
    shell.kill();
    await new Promise(resolve => shell.once('exit', resolve));
    await fs.writeFile(path.join(ui, 'shell.qml'), fullShell);
    const packaged = process.env.AERO_PACKAGED_BINARY;
    const integrated = start(packaged || qs, packaged ? [] : ['-p', ui, '--no-color'], env);
    await waitFor(() => integrated.logs.includes('Configuration Loaded'), 'complete shell integration');
    await new Promise(resolve => setTimeout(resolve, 300));
    const integratedQml = integrated.logs.split('\n').filter(line => !line.includes('ERROR quickshell.service.pipewire.loop: Failed to connect pipewire context.')).join('\n');
    assert.doesNotMatch(integratedQml, /ReferenceError|TypeError|Binding loop|Unable to assign|ERROR/);
    console.log('PASS: real QML + Wayland: input mask, file drops in/out, screenshot reaction, mascot click/drag, position persistence, clear preserves originals.');
} catch (error) {
    for (const child of children) console.error(child.logs);
    throw error;
} finally {
    pointerSocket?.destroy();
    for (const child of children.reverse()) {
        if (child.exitCode !== null || child.signalCode !== null) continue;
        child.kill();
        await new Promise(resolve => child.once('exit', resolve));
    }
    await fs.rm(directory, {recursive: true, force: true});
}

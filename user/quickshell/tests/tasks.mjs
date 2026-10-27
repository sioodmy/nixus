// Real QML and native Hyprland models against an isolated IPC fixture + Sway.
import assert from 'node:assert/strict';
import {spawn, execFile} from 'node:child_process';
import {promisify} from 'node:util';
import fs from 'node:fs/promises';
import net from 'node:net';
import os from 'node:os';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
const exec = promisify(execFile);
const directory = await fs.mkdtemp(path.join('/tmp', 'aero-tasks-'));
const qs = process.env.QS_BINARY || 'qs';
const sway = process.env.SWAY_BINARY || 'sway';
const children = [];
const servers = [];
const eventClients = new Set();
const dispatches = [];
let current = '1';
let lua = true;
const workspaces = [
    {id: 1, name: '1', monitor: 'HEADLESS-1', monitorID: 0},
    {id: 2, name: '2', monitor: 'HEADLESS-1', monitorID: 0},
    {id: 3, name: '3', monitor: 'HEADLESS-2', monitorID: 1},
];
const windows = [
    {address: '0x101', class: 'kitty', title: 'Terminal A', workspace: {id: 1, name: '1'}},
    {address: '0x102', class: 'kitty', title: 'Terminal B', workspace: {id: 1, name: '1'}},
    {address: '0x103', class: 'helium', title: 'Browser', workspace: {id: 2, name: '2'}},
    {address: '0x104', class: 'nemo', title: 'Other monitor', workspace: {id: 3, name: '3'}},
];
const monitor = () => ({id: 0, name: 'HEADLESS-1', description: 'Test output', width: 1440, height: 900, scale: 1, focused: true, activeWorkspace: {id: Number(current), name: current}});
function emit(name, data = '') { for (const client of eventClients) client.write(`${name}>>${data}
`); }
async function waitFor(callback, description) {
    let lastError;
    for (let i = 0; i < 60; i++) {
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
    await fs.writeFile(path.join(ui, 'shell.qml'), `import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
ShellRoot {
    Bar { id: bar }
    function taskList() {
        function find(item) {
            if (item.objectName === "workspace-tasks") return item;
            for (const child of item.children || []) { const found = find(child); if (found) return found; }
            return null;
        }
        return find(bar.contentItem);
    }
    IpcHandler {
        target: "test"
        function status(): string {
            return JSON.stringify(taskList().groups.map(group => ({label: group.label, current: group.current, windows: group.windows.map(window => window.title)})));
        }
        function workspace(index: int): void { taskList().itemAtIndex(index).workspaceRequested(); }
        function window(group: int, index: int): void {
            const list = taskList(); list.itemAtIndex(group).windowRequested(list.groups[group].windows[index]);
        }
        function refresh(): void { Hyprland.refreshMonitors(); Hyprland.refreshWorkspaces(); Hyprland.refreshToplevels(); }
    }
}`);
    const runtime = path.join(directory, 'runtime');
    const signature = 'amethyst-test';
    const socketDir = path.join(runtime, 'hypr', signature);
    await fs.mkdir(socketDir, {recursive: true, mode: 0o700});
    await fs.chmod(runtime, 0o700);
    const requestServer = net.createServer(socket => socket.once('data', data => {
        const request = data.toString();
        let response;
        if (request === 'j/status') response = {configProvider: lua ? 'lua' : 'hyprlang'};
        else if (request === 'j/monitors') response = [monitor(), {id: 1, name: 'HEADLESS-2', width: 800, height: 600, scale: 1, activeWorkspace: {id: 3, name: '3'}}];
        else if (request === 'j/workspaces') response = workspaces;
        else if (request === 'j/clients') response = windows;
        else if (request.startsWith('dispatch ')) { dispatches.push(request); socket.end('ok'); return; }
        else throw new Error(`Unexpected IPC request: ${request}`);
        socket.end(JSON.stringify(response));
    }));
    const eventServer = net.createServer(socket => {
        eventClients.add(socket);
        socket.on('close', () => eventClients.delete(socket));
    });
    for (const [server, name] of [[requestServer, '.socket.sock'], [eventServer, '.socket2.sock']]) {
        servers.push(server);
        await new Promise(resolve => server.listen(path.join(socketDir, name), resolve));
    }
    const env = {...process.env, XDG_RUNTIME_DIR: runtime, AERO_PREVIEW: '1', QT_QUICK_CONTROLS_STYLE: 'Basic'};
    delete env.WAYLAND_DISPLAY; delete env.SWAYSOCK; delete env.HYPRLAND_INSTANCE_SIGNATURE;
    const config = path.join(directory, 'sway.conf');
    await fs.writeFile(config, `output * mode 1440x900
seat seat0 fallback true
output * bg ${fileURLToPath(new URL('../ui/assets/wallpaper.png', import.meta.url))} fill
`);
    const compositor = start(sway, ['--unsupported-gpu', '-c', config], {...env, WLR_BACKENDS: 'headless', WLR_RENDERER: 'pixman', WLR_LIBINPUT_NO_DEVICES: '1'});
    env.WAYLAND_DISPLAY = await waitFor(async () => (await fs.readdir(runtime)).find(name => /^wayland-\d+$/.test(name)), 'Sway startup');
    env.HYPRLAND_INSTANCE_SIGNATURE = signature;
    const shell = start(qs, ['-p', ui, '--no-color'], env);
    await waitFor(() => shell.logs.includes('Configuration Loaded'), 'QML startup');
    const call = async (method, ...args) => (await exec(qs, ['-p', ui, 'ipc', 'call', 'test', method, ...args.map(String)], {env})).stdout.trim();
    const status = async () => JSON.parse(await call('status'));
    await waitFor(async () => (await status())[0]?.windows.length === 2, 'initial windows');
    assert.deepEqual(await status(), [
        {label: '01', current: true, windows: ['Terminal A', 'Terminal B']},
        {label: '02', current: false, windows: ['Browser']},
    ], 'keep both windows of one application and exclude the other output');
    if (process.env.AERO_CAPTURE_DIR) {
        await fs.mkdir(process.env.AERO_CAPTURE_DIR, {recursive: true});
        await exec('grim', [path.join(process.env.AERO_CAPTURE_DIR, 'tasks-desktop.png')], {env});
        await exec('grim', ['-g', '0,0 76x900', path.join(process.env.AERO_CAPTURE_DIR, 'tasks-bar.png')], {env});
    }
    await call('workspace', 1);
    await waitFor(() => dispatches.includes('dispatch hl.dsp.focus({ workspace = "2" })'), 'Lua workspace activation');
    await call('window', 0, 1);
    await waitFor(() => dispatches.includes('dispatch hl.dsp.focus({window="address:0x102"})'), 'window activation');
    windows[1].workspace = {id: 2, name: '2'};
    emit('movewindowv2', '102,2,2');
    await call('refresh');
    await waitFor(async () => (await status())[1]?.windows.includes('Terminal B'), 'window move');
    current = '2'; emit('workspacev2', '2,2');
    await call('refresh');
    await waitFor(async () => (await status())[1]?.current === true, 'active workspace update');
    windows.splice(0, 1); emit('closewindow', '101');
    await call('refresh');
    await waitFor(async () => (await status()).length === 1, 'empty inactive workspace disappears');
    windows.splice(0, 2); emit('closewindow', '102'); emit('closewindow', '103');
    await call('refresh');
    await waitFor(async () => (await status())[0]?.windows.length === 0, 'empty current workspace remains reachable');
    assert.deepEqual(await status(), [{label: '02', current: true, windows: []}]);
    assert.doesNotMatch(shell.logs, /ReferenceError|TypeError|Binding loop|ERROR/);
    console.log('PASS: real QML/native models: duplicate windows, monitor filtering, Lua activation, moves, focus changes, closing and empty workspaces.');
} catch (error) {
    for (const child of children) console.error(child.logs);
    throw error;
} finally {
    for (const child of children.reverse()) { child.kill(); await new Promise(resolve => child.once('exit', resolve)); }
    for (const client of eventClients) client.destroy();
    await Promise.all(servers.map(server => new Promise(resolve => server.close(resolve))));
    await fs.rm(directory, {recursive: true, force: true});
}

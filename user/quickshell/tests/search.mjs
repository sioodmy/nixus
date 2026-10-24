import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import vm from "node:vm";
import { performance } from "node:perf_hooks";

const context = vm.createContext({});
vm.runInContext(readFileSync(new URL("../ui/Search.js", import.meta.url), "utf8").replace(".pragma library", ""), context);
const entries = [
  { id: "kitty", name: "Kitty", genericName: "Terminal emulator" },
  { id: "org.gnome.Nautilus", name: "Pliki", genericName: "File manager", keywords: ["Folder", "Dokumenty"] },
  { id: "helium", name: "Helium", genericName: "Web browser" },
  { id: "bt", name: "Łączność Bluetooth" },
];
const indexed = context.index(entries);
const ids = (query, usage = {}) => Array.from(context.search(query, indexed, usage, 60), entry => entry.id);
assert.equal(ids("KITTY")[0], "kitty");
assert.equal(ids("terminal")[0], "kitty");
assert.equal(ids("folder")[0], "org.gnome.Nautilus");
assert.equal(ids("lacz")[0], "bt");
assert.equal(ids("hlm")[0], "helium");
assert.deepEqual(ids("does not exist"), []);
assert.equal(ids("", { helium: 10 })[0], "helium");
assert.equal(ids("kitty", { helium: 100000 })[0], "kitty");

const many = context.index(Array.from({ length: 2000 }, (_, i) => ({ id: `app-${i}`, name: `Application ${i}`, genericName: "Desktop utility", keywords: ["Tools"] })));
const start = performance.now();
for (let i = 0; i < 200; i++) context.search("apl", many, {}, 60);
const average = (performance.now() - start) / 200;
assert.equal(context.search("", many, {}, 60).length, 60);
console.log(`Search assertions passed. 2,000 apps: ${average.toFixed(2)} ms/query (Node ${process.version}; QML timing varies).`);

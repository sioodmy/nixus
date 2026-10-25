"""Check the installed .desktop inventory against the theme, including aliases."""
import argparse
import configparser
import json
from pathlib import Path
import xml.etree.ElementTree as ET

parser = argparse.ArgumentParser()
parser.add_argument("theme", type=Path)
parser.add_argument("applications", nargs="*", type=Path, default=[Path("/run/current-system/sw/share/applications"), Path.home() / ".local/share/applications"])
args = parser.parse_args()
manifest = json.loads((Path(__file__).parent.parent / "manifest.json").read_text())
aliases = {alias for entry in manifest for alias in entry["aliases"]}
assert len(aliases) == sum(len(entry["aliases"]) for entry in manifest), "Duplicate aliases"
for entry in manifest:
    directory = args.theme / "scalable" / entry.get("context", "apps")
    for name in ["amethyst-" + entry["id"], *entry["aliases"]]:
        icon = directory / (name + ".svg")
        assert icon.is_file(), f"Missing generated icon: {icon}"
        ET.parse(icon)
checked = 0
missing = []
for directory in args.applications:
    for desktop in directory.glob("*.desktop"):
        config = configparser.ConfigParser(interpolation=None, strict=False)
        config.read(desktop)
        entry = config["Desktop Entry"]
        icon = Path(entry.get("Icon", "")).stem
        name = entry.get("Name", "").lower()
        candidates = [icon, desktop.stem, entry.get("StartupWMClass", ""), name]
        if any(candidate in aliases for candidate in candidates):
            checked += 1
        else:
            missing.append((desktop.name, icon, name))
assert not missing, f"Uncovered installed desktop entries: {missing}"
print(f"PASS: {len(manifest)} SVG designs, {len(aliases)} aliases, all {checked} installed desktop entries covered")

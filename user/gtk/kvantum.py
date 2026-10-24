"""Recolor Kvantum's bundled KvDark artwork, retaining its bevels and gloss.

The upstream artwork stays in the Nix dependency, with its original license.
Only palette changes are made; no SVG elements or theme IDs are rewritten.
"""
import json
import re
import sys
from pathlib import Path

source, destination, palette_file = map(Path, sys.argv[1:])
palette = json.loads(palette_file.read_text())
stops = [(0, "background"), (.18, "surface"), (.35, "raised"),
         (.60, "edge"), (.82, "accent"), (1, "text")]


def channels(color):
    return tuple(int(color[i:i + 2], 16) for i in (1, 3, 5))


def recolor(match):
    color = match.group()
    if len(color) == 4:
        color = "#" + "".join(c * 2 for c in color[1:])
    original = channels(color)
    value = max(original) / 255
    for (low, left), (high, right) in zip(stops, stops[1:]):
        if value <= high:
            fraction = max(0, (value - low) / (high - low))
            mixed = tuple(round(a + (b - a) * fraction) for a, b in
                          zip(channels(palette[left]), channels(palette[right])))
            return "#" + "".join(f"{c:02x}" for c in mixed)
    return palette["text"]


destination.mkdir(parents=True, exist_ok=True)
for extension in ("svg", "kvconfig"):
    text = (source / f"KvDark.{extension}").read_text()
    text = re.sub(r"#[\da-fA-F]{6}(?![\da-fA-F])|#[\da-fA-F]{3}(?![\da-fA-F])", recolor, text)
    if extension == "kvconfig":
        text = re.sub(r"(?m)(\.color=)white$", r"\g<1>" + palette["text"], text)
        text = re.sub(r"(?m)(\.color=)black$", r"\g<1>" + palette["background"], text)
        overrides = {
            "window.color": palette["surface"], "base.color": palette["background"],
            "alt.base.color": palette["raised"], "button.color": palette["raised"],
            "highlight.color": palette["accent"], "inactive.highlight.color": palette["edge"],
            "highlight.text.color": palette["background"], "link.color": palette["blue"],
            "link.visited.color": palette["accent"], "disabled.text.color": palette["muted"],
            "translucent_windows": "true", "blurring": "true", "reduce_window_opacity": "5",
        }
        for key, value in overrides.items():
            text = re.sub(r"(?m)^" + re.escape(key) + r"=.*$", key + "=" + value, text)
        text = text.replace("author=Tsu Jan", "author=Tsu Jan; Amethyst palette by sioodmy")
    (destination / f"Amethyst-Aero.{extension}").write_text(text)

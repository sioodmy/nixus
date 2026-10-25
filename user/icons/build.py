"""Build the original Amethyst Aero SVG icon family and freedesktop aliases."""
import argparse
import json
from pathlib import Path
from xml.sax.saxutils import escape


def path(d, fill="url(#body)", stroke="#d8c5f0", width=1.4, extra=""):
    return f'<path d="{d}" fill="{fill}" stroke="{stroke}" stroke-width="{width}" stroke-linejoin="round" stroke-linecap="round" {extra}/>'


def rect(x, y, w, h, r=3, fill="url(#body)", stroke="#d8c5f0", width=1.4):
    return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{r}" fill="{fill}" stroke="{stroke}" stroke-width="{width}"/>'


def circle(x, y, r, fill="url(#orb)", stroke="#dbc5f4", width=1.4):
    return f'<circle cx="{x}" cy="{y}" r="{r}" fill="{fill}" stroke="{stroke}" stroke-width="{width}"/>'


def line(d, color="#eee3fc", width=3):
    return path(d, "none", color, width)


def folder(emblem=""):
    return (path("M7 17Q7 13 11 13H25L30 19H53Q57 19 57 24V49Q57 53 53 53H11Q7 53 7 49Z", "url(#back)")
            + path("M8 26Q8 23 12 23H53Q58 23 57 28L53 50Q52 54 48 54H11Q7 54 7 50Z")
            + path("M10 25H53L51 35Q31 43 9 36Z", "url(#shine)", "none") + emblem)


def document(emblem=""):
    return (path("M15 8H38L51 21V53Q51 56 47 56H16Q12 56 12 52V12Q12 8 15 8Z", "url(#paper)")
            + path("M38 8V21H51", "url(#back)") + emblem)


def medallion(emblem=""):
    return (circle(32, 31, 24) + circle(32, 31, 21, "none", "#eee1ff", 0.6)
            + path("M12 23C17 8 44 7 52 23Q33 35 12 23Z", "url(#shine)", "none") + emblem)


def glyph(shape):
    if shape == "folder":
        return folder()
    if shape == "home":
        return folder(path("M22 41L32 32L42 41V50H35V43H29V50H23V41", "#f0e5ff", "#795397", 0.8))
    if shape == "documents":
        return folder(rect(24, 29, 17, 21, 1, "url(#paper)") + line("M28 35H37M28 40H37M28 45H34", "#684889", 1.8))
    if shape == "downloads":
        return folder(path("M28 29H36V39H43L32 50L21 39H28Z", "url(#ice)", "#d8eeff", 1))
    if shape == "pictures":
        return folder(rect(20, 30, 25, 19, 2, "url(#ice)") + path("M21 47L29 37L35 43L39 39L45 48Z", "#70508f", "none") + circle(38, 35, 2, "#f7e8ff", "none"))
    if shape == "terminal":
        return (rect(6, 10, 52, 43, 5, "url(#back)") + rect(9, 13, 46, 36, 3, "#22182e", "#a78ac4", 1)
                + path("M10 14H54V27Q28 35 10 29Z", "url(#shine)", "none")
                + line("M17 24L25 31L17 38M31 39H43", "#f0dcff", 3.5)
                + path("M19 54H45L50 57H14Z", "url(#metal)", "#847092", 0.8))
    if shape == "zen":
        return medallion(circle(32, 31, 13, "#261a39", "#d3b6f2", 3) + path("M20 40C30 48 48 32 43 22", "none", "#f0dfff", 2) + circle(46, 18, 3, "url(#ice)"))
    if shape == "helium":
        return (circle(32, 32, 10, "url(#ice)") + ''.join(f'<ellipse cx="32" cy="32" rx="26" ry="10" transform="rotate({angle} 32 32)" fill="none" stroke="{color}" stroke-width="2.6"/>' for angle, color in [(0, '#d5b6f5'), (60, '#b8c6ed'), (120, '#a187c3')]) + circle(53, 17, 3, "#e2d0f5"))
    if shape == "signal":
        return (circle(32, 30, 25, "none", "#bca0dc", 2.5).replace('/>', ' stroke-dasharray="3 3"/>')
                + path("M13 17Q18 9 32 10Q51 10 52 29Q52 47 33 49H25L15 55L17 44Q9 38 11 26Q11 21 13 17Z")
                + path("M16 18Q34 5 48 23Q36 31 14 27Z", "url(#shine)", "none")
                + line("M22 27H41M22 34H36", "#f0e5ff", 2.7))
    if shape == "ferdium":
        return (path("M10 14Q10 8 17 8H48Q55 8 55 15V42Q55 49 48 49H30L16 57V49Q10 49 10 43Z")
                + path("M13 12H51V25Q35 34 13 25Z", "url(#shine)", "none")
                + path("M24 19H43V25H31V30H40V36H31V43H24Z", "#f1e5ff", "#9b74b9", 0.7))
    if shape == "mail":
        return (path("M5 25Q6 12 20 10Q37 5 49 17L58 28L54 47Q51 56 39 55Q24 56 15 48L7 45Q18 43 18 37Q10 38 5 34L15 29Z", "url(#back)")
                + rect(14, 24, 40, 27, 3, "url(#paper)")
                + path("M15 25L34 40L53 25M15 50L28 37M53 50L40 37", "none", "#80608f", 1.8)
                + path("M11 15Q30 5 46 17Q24 13 19 31L11 36Q14 25 11 15Z", "url(#ice)", "#c4c9ed", 1))
    if shape == "t3":
        return (path("M10 14L32 5L54 14V48L32 59L10 48Z", "url(#back)")
                + path("M12 15L32 8L52 15L32 25Z", "url(#shine)", "#aa8bc9", 0.8)
                + line("M18 25H31M24.5 25V43M37 25H45L39 33L45 36V42H36", "#e8d9fc", 3.3))
    if shape == "editor":
        return (path("M10 14L22 7L44 45V10L55 16V50L43 57L21 20V55L10 48Z", "url(#body)")
                + path("M22 7L44 45V55L21 20Z", "url(#ice)", "#dce3fb", 0.8))
    if shape == "key":
        return (circle(23, 24, 17) + circle(23, 24, 7, "#20132f", "#e1d0f0", 2)
                + path("M34 34L55 54L49 60L43 54L47 50L42 45L38 49L32 43L36 39Z", "url(#metal)", "#c9b2e5", 1.5)
                + path("M10 19Q17 5 33 13L35 20Q20 26 10 23Z", "url(#shine)", "none"))
    if shape == "gimp":
        return (path("M7 23L15 10L23 21L45 19L54 12L54 29Q62 43 45 51Q28 58 11 45Q5 39 7 23Z", "url(#back)")
                + path("M11 27Q28 36 52 24Q57 39 43 43Q24 48 11 36Z", "url(#body)", "#b9a3ce", 1)
                + circle(24, 29, 5, "#f2e7ff", "none") + circle(42, 27, 5, "#f2e7ff", "none")
                + circle(26, 30, 2, "#261735", "none") + circle(41, 28, 2, "#261735", "none")
                + path("M32 37Q37 33 41 37Q38 43 33 41Z", "#29192e", "none")
                + line("M38 49L57 27", "#d8c4ea", 4)
                + path("M37 47Q29 45 30 55Q38 59 40 50Z", "url(#ice)", "#d5b4e6", 0.8))
    if shape == "inkscape":
        return (path("M7 42L32 5L57 42L45 38L40 47L32 42L24 47L19 38Z", "url(#back)")
                + path("M22 21L32 6L42 21L34 18L30 24Z", "url(#paper)")
                + path("M7 53Q30 44 57 53L53 58Q32 54 11 58Z", "url(#metal)", "#b6a1ca", 1))
    if shape == "rnote":
        return (rect(10, 9, 38, 47, 4, "url(#paper)") + line("M17 23H37M17 30H33M17 37H36M17 44H27", "#9879ad", 1.8)
                + path("M30 43L47 13Q49 9 53 12L56 14Q58 17 55 20L38 49L28 54Z", "url(#body)")
                + path("M30 44L28 54L38 49Z", "#382047", "#cbb1df", 0.8))
    if shape == "prism":
        return (path("M32 5L56 18V46L32 60L8 46V18Z", "url(#body)")
                + path("M32 5L56 18L32 32L8 18Z", "url(#ice)")
                + path("M8 18L32 32V60L8 46Z", "url(#back)")
                + path("M32 32L56 18V46L32 60Z", "url(#body)")
                + line("M32 5V32L8 46M32 32L56 46", "#ead7ff", 0.8))
    if shape in ("play", "play-small"):
        return medallion(path("M26 19L44 31L26 43Z", "url(#paper)", "#c8aedf", 1))
    if shape == "image":
        return (rect(6, 12, 52, 41, 4, "url(#metal)") + rect(10, 16, 44, 33, 1, "url(#ice)", "#716180", 1)
                + path("M11 46L25 26L37 41L44 32L54 47Z", "url(#body)", "#a691c6", 1)
                + circle(43, 24, 4, "#fbecff", "none")
                + path("M11 17H53V29Q30 35 11 29Z", "url(#shine)", "none"))
    if shape == "pdf":
        return document(path("M19 44Q28 38 35 21Q31 40 45 45Q33 41 19 44Z", "none", "#8a589f", 3))
    if shape == "math":
        return document(line("M39 23H24L33 35L23 47H40", "#795096", 4))
    if shape == "tex":
        return document(line("M21 25H42M31 25V44M37 36H44M37 36V47H45", "#75528d", 2.8))
    if shape == "yazi":
        return (folder() + path("M20 31L29 40V49H35V40L44 31H37L32 36L27 31Z", "#eee0ff", "#715086", 0.8))
    if shape == "monitor":
        return (rect(6, 10, 52, 39, 4, "url(#metal)") + rect(10, 14, 44, 31, 1, "#21152d", "#7d5d95", 1)
                + line("M14 35H22L27 22L33 40L38 29H50", "#cba3f2", 2.6)
                + path("M28 49H36L38 55H45V58H19V55H26Z", "url(#metal)"))
    if shape == "drop":
        return (path("M32 5Q29 15 16 31Q6 46 20 55Q31 62 44 54Q58 45 47 30Q36 15 32 5Z")
                + path("M17 31Q18 23 30 13Q27 30 20 38Z", "url(#shine)", "none")
                + line("M22 46Q31 55 42 46", "#d7e1fb", 1.6))
    if shape == "transfer":
        return (path("M7 18L26 8L39 17V47L20 57L7 48Z", "url(#back)")
                + path("M28 15H38V35H46L33 49L20 35H28Z", "url(#ice)")
                + path("M42 8L56 22H48V42H39V22H32Z", "url(#body)")
                + line("M12 22L20 27V51", "#d3b3ed", 1))
    if shape == "nicotine":
        return (path("M9 17Q9 10 17 10H47Q55 10 55 18V42Q55 49 47 49H25L12 56V46Q9 45 9 39Z")
                + line("M19 38V22L32 38V22M39 29H49M44 24V34", "#f0dfff", 3.2)
                + path("M12 14H51V24Q29 30 12 25Z", "url(#shine)", "none"))
    if shape == "sync":
        return (circle(15, 16, 7) + circle(50, 29, 7, "url(#ice)") + circle(23, 51, 7)
                + line("M21 18L43 26M46 35L28 47M21 44L16 23", "#d9c2ee", 4)
                + circle(32, 32, 5, "#f2e3fc", "#a27abc", 1))
    if shape == "phone":
        return (rect(17, 5, 31, 54, 6, "url(#metal)") + rect(21, 11, 23, 38, 2, "url(#back)")
                + circle(32, 54, 2, "#f3e5ff", "#9e7fb6", 0.8)
                + line("M27 29H40L36 25M37 34H24L28 38", "#dfccf8", 2.5))
    if shape == "bluetooth":
        return medallion(line("M30 13V49L43 38L22 22M22 41L43 24L30 13", "#e9ddfc", 3.4))
    if shape in ("wifi", "offline"):
        result = (path("M6 21Q32 0 58 21L51 29Q32 13 13 29Z")
                  + path("M18 34Q32 22 46 34L39 42Q32 36 25 42Z", "url(#ice)") + circle(32, 49, 5))
        return result + (line("M11 11L54 55", "#f0bddb", 4) if shape == "offline" else "")
    if shape in ("speaker", "muted"):
        result = (path("M8 24H20L35 12V52L20 40H8Z") + path("M10 26H20L32 17V30Q21 37 10 33Z", "url(#shine)", "none"))
        return result + (line("M44 25L56 39M56 25L44 39", "#f0bddb", 3) if shape == "muted" else line("M42 23Q51 32 42 41M49 15Q64 32 49 49", "#d3c0f0", 3))
    if shape == "microphone":
        return (rect(23, 6, 18, 32, 9) + line("M16 28V32Q16 47 32 47Q48 47 48 32V28M32 47V56M23 57H41", "#d2bce9", 3)
                + line("M27 13V25", "#f7edff", 1.5))
    if shape == "printer":
        return (rect(17, 6, 30, 24, 1, "url(#paper)") + rect(7, 22, 50, 28, 5)
                + rect(17, 36, 30, 22, 1, "url(#paper)") + line("M23 43H41M23 49H36", "#9274aa", 2)
                + circle(49, 30, 2, "#bddeeb", "none"))
    if shape == "appearance":
        return (circle(32, 31, 24, "url(#metal)")
                + path("M32 7V55A24 24 0 0 1 32 7Z", "url(#body)", "none")
                + path("M32 7A24 24 0 0 1 56 31H32Z", "url(#ice)", "none")
                + circle(32, 31, 9, "#2b1a3b", "#e9d9fc", 1.5)
                + path("M14 18Q33 4 48 18Q30 27 14 24Z", "url(#shine)", "none"))
    if shape == "orb":
        return medallion(path("M32 13L46 32L32 48L18 32Z", "url(#ice)", "#f3e7ff", 1) + path("M32 13V48L18 32Z", "url(#body)", "none"))
    if shape == "user":
        return (rect(9, 6, 46, 52, 8) + circle(32, 24, 10, "url(#paper)") + path("M16 52V46Q16 35 32 35Q48 35 48 46V52Z", "url(#paper)"))
    if shape in ("bell", "bell-off"):
        result = (path("M13 44L18 38V25Q18 12 29 12V8H35V12Q46 12 46 25V38L51 44V48H13Z")
                  + path("M25 51Q32 62 39 51Z", "url(#metal)") + line("M24 23Q24 17 29 17", "#f3e7ff", 1.5))
        return result + (line("M12 10L53 55", "#efbdd8", 4) if shape == "bell-off" else "")
    if shape == "lock":
        return (path("M20 29V20Q20 6 32 6Q44 6 44 20V29H38V20Q38 12 32 12Q26 12 26 20V29Z", "url(#metal)")
                + rect(11, 26, 42, 31, 5) + circle(32, 38, 4, "#2e1b40", "#ceb4e9", 1)
                + path("M30 41H34L35 49H29Z", "#2e1b40", "none")
                + path("M14 29H50V37Q31 44 14 37Z", "url(#shine)", "none"))
    if shape in ("power", "reboot", "moon", "logout", "search", "close", "next", "previous", "pause", "sun"):
        content = {
            "power": line("M21 18A19 19 0 1 0 43 18M32 11V31", "#f1defe", 4),
            "reboot": line("M46 22A18 18 0 1 0 49 38M46 13V24H35", "#e6d6fc", 3.5),
            "moon": path("M38 13A18 18 0 1 0 48 43A21 21 0 0 1 38 13Z", "url(#paper)", "#d4bbeb", 1),
            "logout": line("M28 17H18V46H28M29 32H49L42 25M49 32L42 39", "#edddfc", 3.5),
            "search": circle(28, 27, 11, "#b7a8d1", "#f3e8ff", 3) + line("M37 36L47 47", "#ecdcfc", 5),
            "close": line("M22 21L43 42M43 21L22 42", "#efdefa", 4),
            "next": path("M19 20L37 31L19 43Z", "url(#paper)") + line("M43 20V43", "#ebddfc", 3),
            "previous": path("M45 20L27 31L45 43Z", "url(#paper)") + line("M21 20V43", "#ebddfc", 3),
            "pause": rect(21, 20, 8, 23, 1, "url(#paper)") + rect(36, 20, 8, 23, 1, "url(#paper)"),
            "sun": circle(32, 31, 8, "url(#paper)") + line("M32 13V17M32 45V49M14 31H18M46 31H50M19 18L22 21M42 41L45 44M19 44L22 41M42 21L45 18", "#ead8fb", 2.5),
        }[shape]
        return medallion(content)
    if shape == "trash":
        return (path("M16 20H48L44 56H20Z", "url(#ice)") + rect(12, 14, 40, 7, 2, "url(#metal)")
                + path("M25 14V8H39V14", "none", "#ccb6e2", 3) + line("M25 27L27 48M39 27L37 48", "#7e5e9b", 2))
    if shape == "application":
        return (rect(8, 9, 48, 46, 5) + rect(12, 14, 40, 35, 2, "#2c1d3c", "#a98bc4", 0.8)
                + path("M12 14H52V26Q32 33 12 26Z", "url(#shine)", "none")
                + path("M32 22L43 34L32 45L21 34Z", "url(#ice)", "#e7d8f9", 1))
    raise ValueError(f"Unknown icon shape: {shape}")


def svg(entry, palette):
    definitions = f'''<defs>
      <linearGradient id="body" x1="0" y1="0" x2="0.25" y2="1">
        <stop stop-color="#d4bbec"/><stop offset=".28" stop-color="#a27ac4"/>
        <stop offset=".49" stop-color="#765298"/><stop offset=".51" stop-color="#4c3067"/>
        <stop offset="1" stop-color="#9869b7"/>
      </linearGradient>
      <linearGradient id="back" x2=".3" y2="1"><stop stop-color="#82619e"/><stop offset=".5" stop-color="{palette['surface']}"/><stop offset="1" stop-color="#59406f"/></linearGradient>
      <linearGradient id="paper" x2=".2" y2="1"><stop stop-color="#fff4ff"/><stop offset=".5" stop-color="#e7d7f5"/><stop offset="1" stop-color="#baa5d5"/></linearGradient>
      <linearGradient id="metal" x2=".4" y2="1"><stop stop-color="#eee4f6"/><stop offset=".35" stop-color="#b5a6c4"/><stop offset=".5" stop-color="#7c6a90"/><stop offset="1" stop-color="#d4c5e4"/></linearGradient>
      <linearGradient id="ice" x2=".3" y2="1"><stop stop-color="#e2f0f9"/><stop offset=".4" stop-color="#b6cbeb"/><stop offset="1" stop-color="#8a85bd"/></linearGradient>
      <linearGradient id="shine" x2="0" y2="1"><stop stop-color="#ffffff" stop-opacity=".62"/><stop offset="1" stop-color="#ffffff" stop-opacity=".03"/></linearGradient>
      <radialGradient id="orb" cx=".35" cy=".23" r=".8"><stop stop-color="#bea0dd"/><stop offset=".48" stop-color="#755095"/><stop offset=".72" stop-color="#3a234f"/><stop offset="1" stop-color="#8052a0"/></radialGradient>
    </defs>'''
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">'
            f'<title>{escape(entry["name"])}</title>{definitions}'
            '<ellipse cx="32" cy="59" rx="23" ry="3" fill="#180c26" opacity=".28"/>'
            f'{glyph(entry["shape"])}</svg>\n')


def build(output, oxygen, palette_path):
    entries = json.loads(Path(__file__).with_name("manifest.json").read_text())
    palette = json.loads(palette_path.read_text())
    contexts = {"apps": "Applications", "places": "Places", "devices": "Devices", "status": "Status", "actions": "Actions"}
    output.mkdir(parents=True, exist_ok=True)
    names = set()
    for entry in entries:
        folder_path = output / "scalable" / entry.get("context", "apps")
        folder_path.mkdir(parents=True, exist_ok=True)
        target = folder_path / f'amethyst-{entry["id"]}.svg'
        target.write_text(svg(entry, palette))
        for alias in entry["aliases"]:
            if alias in names or "/" in alias:
                raise ValueError(f"Duplicate/invalid icon alias: {alias}")
            names.add(alias)
            (folder_path / f"{alias}.svg").symlink_to(target.name)
    # Keep all unmodified Oxygen system icons available through inheritance.
    index = ["[Icon Theme]", "Name=Amethyst Aero", "Comment=Original violet glass application and desktop icons", "Inherits=oxygen,Adwaita,hicolor", "Example=start-here",
             "Directories=" + ",".join(f"scalable/{c}" for c in contexts)]
    for context, label in contexts.items():
        (output / "scalable" / context).mkdir(exist_ok=True)
        index += ["", f"[scalable/{context}]", "Size=64", "MinSize=16", "MaxSize=512", "Type=Scalable", f"Context={label}"]
    (output / "index.theme").write_text("\n".join(index) + "\n")
    # Validate inheritance at build time, rather than silently losing fallback icons.
    if not (oxygen / "index.theme").is_file():
        raise ValueError("Missing Oxygen fallback theme")
    print(f"Built {len(entries)} original icons, {len(names)} aliases")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--oxygen", required=True, type=Path)
    parser.add_argument("--palette", required=True, type=Path)
    args = parser.parse_args()
    build(args.output, args.oxygen, args.palette)

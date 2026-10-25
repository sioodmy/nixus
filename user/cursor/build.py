"""Render original SVG cursor artwork and compile a multiscale Xcursor theme."""
import json
from pathlib import Path
import subprocess
import sys
import tempfile

out = Path(sys.argv[1])
palette = json.loads(Path(sys.argv[2]).read_text())
sizes = (16, 20, 24, 28, 32, 40, 48, 56, 64, 72, 96)
defs = f'''<defs>
  <linearGradient id="pearl" x1="0" y1="0" x2=".7" y2="1" gradientUnits="objectBoundingBox">
    <stop stop-color="#ffffff"/><stop offset=".38" stop-color="{palette['text']}"/>
    <stop offset=".64" stop-color="{palette['highlight']}"/><stop offset="1" stop-color="#9877ba"/>
  </linearGradient>
  <linearGradient id="ring" x1="0" y1="0" x2="1" y2="1">
    <stop stop-color="#fff5ff"/><stop offset=".4" stop-color="{palette['accent']}"/>
    <stop offset="1" stop-color="#644087"/>
  </linearGradient>
  <filter id="shadow" x="-30%" y="-30%" width="170%" height="170%">
    <feDropShadow dx="0" dy="1" stdDeviation="1" flood-color="#10081c" flood-opacity=".5"/>
  </filter>
</defs>'''


def shape(path):
    return f'<path d="{path}" fill="url(#pearl)" stroke="#2c1a40" stroke-width="2.3" stroke-linejoin="round" filter="url(#shadow)"/>'


arrow = shape('M10 6V49L22 38L31 57L40 53L31 35L48 34Z')
arrow += '<path d="M12 12V43L21 34" fill="none" stroke="#ffffff" stroke-opacity=".85" stroke-width="1.3"/>'
hand = shape('M23 32V12C23 5 31 5 31 12V27V21C31 15 39 15 39 21V28V25C39 19 47 19 47 25V31V30C47 25 54 25 54 31V43C54 50 48 55 45 59H25C23 53 16 46 12 40C8 34 13 28 18 33L23 38Z')
hand += '<path d="M25 13V31M33 23V32M41 27V33" fill="none" stroke="#ffffff" stroke-opacity=".7" stroke-width="1.2"/>'
fist = shape('M17 30V23C17 16 25 16 25 23V20C25 13 33 13 33 20V22C33 15 41 15 41 22V24C41 18 49 18 49 24V41C49 48 44 52 42 57H24L13 42C8 36 12 29 17 34Z')
beam_path = 'M23 9H41M32 9V55M23 55H41'
beam = f'<path d="{beam_path}" fill="none" stroke="#2c1a40" stroke-width="6" stroke-linecap="round"/><path d="{beam_path}" fill="none" stroke="url(#pearl)" stroke-width="3.5" stroke-linecap="round"/>'
resize = shape('M32 6L21 19H28V45H21L32 58L43 45H36V19H43Z')
move = shape('M32 5L23 16H28V28H16V23L5 32L16 41V36H28V48H23L32 59L41 48H36V36H48V41L59 32L48 23V28H36V16H41Z')
cross = '<path d="M32 8V25M32 39V56M8 32H25M39 32H56" stroke="#2c1a40" stroke-width="5"/><path d="M32 8V25M32 39V56M8 32H25M39 32H56" stroke="url(#pearl)" stroke-width="2.5"/>'
cross += '<circle cx="32" cy="32" r="2" fill="#fff" stroke="#2c1a40"/>'
forbidden = '<circle cx="32" cy="32" r="20" fill="#261733" stroke="#2c1a40" stroke-width="5"/><circle cx="32" cy="32" r="19" fill="none" stroke="#f29ba9" stroke-width="4"/><path d="M18 18L46 46" stroke="#f29ba9" stroke-width="4"/><path d="M19 16A20 20 0 0 1 46 18" fill="none" stroke="#fff0ff" stroke-width="1.4"/>'


def ring(frame, cx=32, cy=32, radius=17):
    return f'''<circle cx="{cx}" cy="{cy}" r="{radius + 3}" fill="#251630" fill-opacity=".85" stroke="#ead8ff" stroke-opacity=".65"/>
    <circle cx="{cx}" cy="{cy}" r="{radius}" fill="none" stroke="#533768" stroke-width="6"/>
    <circle cx="{cx}" cy="{cy}" r="{radius}" fill="none" stroke="url(#ring)" stroke-width="6" stroke-linecap="round" stroke-dasharray="{radius * 3.6} {radius * 2.69}" transform="rotate({frame * 30} {cx} {cy})"/>
    <path d="M{cx-radius*.8} {cy-radius*.45}Q{cx} {cy-radius*1.4} {cx+radius*.8} {cy-radius*.45}" fill="none" stroke="#fff" stroke-opacity=".5" stroke-width="1.2"/>'''


art = {
    'left_ptr': ([arrow], (10, 6)),
    'hand2': ([hand], (27, 9)),
    'grabbing': ([fist], (30, 30)),
    'xterm': ([beam], (32, 32)),
    'crosshair': ([cross], (32, 32)),
    'fleur': ([move], (32, 32)),
    'ns-resize': ([resize], (32, 32)),
    'ew-resize': ([f'<g transform="rotate(90 32 32)">{resize}</g>'], (32, 32)),
    'nesw-resize': ([f'<g transform="rotate(45 32 32)">{resize}</g>'], (32, 32)),
    'nwse-resize': ([f'<g transform="rotate(135 32 32)">{resize}</g>'], (32, 32)),
    'not-allowed': ([forbidden], (32, 32)),
    'watch': ([ring(i) for i in range(12)], (32, 32)),
    'left_ptr_watch': ([arrow + ring(i, 46, 46, 10) for i in range(12)], (10, 6)),
}
aliases = {
    'left_ptr': ['default', 'arrow', 'top_left_arrow', 'left-arrow'],
    'hand2': ['pointer', 'hand', 'hand1', 'pointing_hand', 'e29285e634086352946a0e7090d73106', '9d800788f1b08800ae810202380a0822'],
    'grabbing': ['closedhand', 'closed_hand', 'dnd-move'],
    'xterm': ['text', 'ibeam'],
    'crosshair': ['cross', 'tcross', 'plus'],
    'fleur': ['move', 'all-scroll', 'size_all'],
    'ns-resize': ['v_double_arrow', 'size_ver', 'n-resize', 's-resize', 'top_side', 'bottom_side', 'row-resize', 'split_v'],
    'ew-resize': ['h_double_arrow', 'size_hor', 'w-resize', 'e-resize', 'left_side', 'right_side', 'col-resize', 'split_h'],
    'nesw-resize': ['fd_double_arrow', 'size_bdiag', 'ne-resize', 'sw-resize', 'top_right_corner', 'bottom_left_corner'],
    'nwse-resize': ['bd_double_arrow', 'size_fdiag', 'nw-resize', 'se-resize', 'top_left_corner', 'bottom_right_corner'],
    'not-allowed': ['forbidden', 'crossed_circle', 'no-drop', 'dnd-no-drop', '03b6e0fcb3499374a867c041f52298f0'],
    'watch': ['wait'],
    'left_ptr_watch': ['progress', 'half-busy', '08e8e1c95fe2fc01f976f1e063a24ccd'],
}
(out / 'previews').mkdir()
with tempfile.TemporaryDirectory() as work:
    work = Path(work)
    for name, (frames, hotspot) in art.items():
        config = []
        for frame, body in enumerate(frames):
            svg = work / f'{name}-{frame}.svg'
            svg.write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">{defs}{body}</svg>')
            for size in sizes:
                png = work / f'{name}-{frame}-{size}.png'
                subprocess.run(['rsvg-convert', '-w', str(size), '-h', str(size), '-o', str(png), str(svg)], check=True)
                config.append(f'{size} {round(hotspot[0]*size/64)} {round(hotspot[1]*size/64)} {png} 60')
            if frame == 0:
                subprocess.run(['rsvg-convert', '-w', '128', '-h', '128', '-o', str(out / 'previews' / f'{name}.png'), str(svg)], check=True)
        source = work / f'{name}.cursor'
        source.write_text('\n'.join(config) + '\n')
        dest = out / 'cursors' / name
        dest.unlink(missing_ok=True)
        subprocess.run(['xcursorgen', str(source), str(dest)], check=True)
    for target, names in aliases.items():
        for name in names:
            dest = out / 'cursors' / name
            dest.unlink(missing_ok=True)
            dest.symlink_to(target)

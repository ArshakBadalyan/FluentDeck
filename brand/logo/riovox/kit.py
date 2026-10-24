"""Full logo kit for all three Riovox concepts -> kit/<concept>/{svg,png}."""
import os, subprocess
from build import (svg, wordmark, WM_W, a_symbol, b_symbol, c_symbol,
                   TEAL, CORAL, DARK, PAGE, FUR, EAR, CREAM, INK)

RENDER = os.path.expanduser('~/.claude/skills/logo-design/scripts/render_png.py')
LIGHT_TEXT = '#F3F7F7'
def ell(cx, cy, rx, ry=None):  # ellipse as a sub-path (for even-odd holes)
    ry = ry or rx
    return f'M{cx-rx} {cy}a{rx} {ry} 0 1 0 {2*rx} 0a{rx} {ry} 0 1 0 {-2*rx} 0z'

# One-colour masters: real holes (even-odd) instead of cream/white shapes.
def a_mono(c):
    return (f'<g fill="{c}"><path d="M70 180l-34 50 62-26z"/><circle cx="36" cy="108" r="17"/><circle cx="220" cy="108" r="17"/>'
            f'<path fill-rule="evenodd" d="M128 48c60 0 102 34 102 80s-42 80-102 80-102-34-102-80 42-80 102-80z{ell(88,106,12)}{ell(168,106,12)}M128 130A36 36 0 1 0 128 186A36 36 0 1 0 128 130Z"/>'
            f'<path d="M128 124c12 0 20 5 20 11s-9 13-20 13-20-7-20-13 8-11 20-11z"/></g>')
def b_mono(c):
    return (f'<g fill="{c}"><path d="M48 150c-14-4-30-14-38-30 18 4 34 10 46 20z"/>'
            f'<path fill-rule="evenodd" d="{ell(120,150,84,34)}{ell(128,140,58,18)}"/>'
            f'<ellipse cx="62" cy="122" rx="11" ry="16" transform="rotate(-20 62 122)"/><ellipse cx="80" cy="118" rx="11" ry="16" transform="rotate(-10 80 118)"/>'
            f'<path fill-rule="evenodd" transform="rotate(-12 129 90)" d="M113 58h32a9 9 0 0 1 9 9v46a9 9 0 0 1-9 9h-32a9 9 0 0 1-9-9V67a9 9 0 0 1 9-9zM117.5 74h21a3.5 3.5 0 0 1 0 7h-21a3.5 3.5 0 0 1 0-7zM117.5 88h13a3.5 3.5 0 0 1 0 7h-13a3.5 3.5 0 0 1 0-7z"/>'
            f'<circle cx="112" cy="124" r="11"/><circle cx="150" cy="118" r="11"/><circle cx="190" cy="94" r="10"/>'
            f'<path fill-rule="evenodd" d="{ell(202,120,36)}{ell(216,130,14)}M193 110q8-11 16 0q-8-5-16 0z"/><circle cx="226" cy="124" r="7"/>'
            f'<path d="M8 178c20-12 40-12 60 0s40 12 60 0 40-12 60 0 40 12 60 0v40a14 14 0 0 1-14 14H22a14 14 0 0 1-14-14z"/></g>')
def c_mono(c):
    s = f'fill="none" stroke="{c}" stroke-width="12" stroke-linecap="round"'
    return (f'<path d="M30 86a120 120 0 0 0 0 84M226 86a120 120 0 0 1 0 84" {s}/><path d="M6 66a160 160 0 0 0 0 124M250 66a160 160 0 0 1 0 124" {s} stroke-width="8"/>'
            f'<g fill="{c}"><circle cx="48" cy="92" r="16"/><circle cx="208" cy="92" r="16"/>'
            f'<path fill-rule="evenodd" d="M128 40c52 0 84 34 84 82 0 22-4 40-10 58H54c-6-18-10-36-10-58 0-48 32-82 84-82z{ell(96,100,11)}{ell(160,100,11)}M128 116A30 30 0 1 0 128 166A30 30 0 1 0 128 116Z"/>'
            f'<path d="M128 111c10 0 17 4 17 9s-8 11-17 11-17-6-17-11 7-9 17-9z"/>'
            f'<path d="M28 170c20-14 40-14 60 0s40 14 60 0 40-14 60 0 20 14 20 14v42a14 14 0 0 1-14 14H42a14 14 0 0 1-14-14z"/></g>')

# Small-size cuts (favicon, 16-48 px): fewer, bigger parts.
def b_small():
    return (f'<circle cx="92" cy="62" r="20" fill="{EAR}"/><circle cx="124" cy="124" r="84" fill="{FUR}"/>'
            f'<circle cx="168" cy="146" r="40" fill="{CREAM}"/><circle cx="194" cy="128" r="16" fill="{INK}"/>'
            f'<path d="M100 106q16-20 32 0" fill="none" stroke="{INK}" stroke-width="12" stroke-linecap="round"/>'
            f'<path fill="{TEAL}" d="M0 206c22-14 42-14 64 0s42 14 64 0 42-14 64 0 42 14 64 0v50H0z"/>')
def c_small():
    return c_symbol().split('opacity=".55"/>', 1)[1]  # the face without the ripples

CONCEPTS = {
    'a-rio-bubble': (a_symbol(), a_mono, a_symbol(), TEAL),
    'b-rio-floating': (b_symbol(), b_mono, b_small(), PAGE),
    'c-rio-river': (c_symbol(), c_mono, c_small(), PAGE),
}

def write(path, w, h, body):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    open(path, 'w').write(svg(w, h, body))

def png(src, out, *args):
    subprocess.run(['python3', RENDER, src, '-o', out, *args], check=True, capture_output=True)

for name, (sym, mono, small, tile) in CONCEPTS.items():
    d = f'kit/{name}'
    S, P = f'{d}/svg', f'{d}/png'
    wm_light, wm_dark = wordmark(DARK, CORAL, True), wordmark(LIGHT_TEXT, CORAL, True)
    lw = 300 + int(WM_W * .62) + 10
    files = {
        'symbol': (256, 256, sym),
        'symbol-small': (256, 256, small),
        'symbol-black': (256, 256, mono('#000000')),
        'symbol-white': (256, 256, mono('#FFFFFF')),
        'symbol-teal': (256, 256, mono(TEAL)),
        'horizontal': (lw, 256, f'{sym}<g transform="translate(290 49) scale(.62)">{wm_light}</g>'),
        'horizontal-on-dark': (lw, 256, f'{sym}<g transform="translate(290 49) scale(.62)">{wm_dark}</g>'),
        'horizontal-black': (lw, 256, f'{mono("#000000")}<g transform="translate(290 49) scale(.62)">{wordmark("#000000", "#000000", True)}</g>'),
        'stacked': (480, 400, f'<g transform="translate(112 0)">{sym}</g><g transform="translate(24 222) scale(.7)">{wm_light}</g>'),
        'stacked-on-dark': (480, 400, f'<g transform="translate(112 0)">{sym}</g><g transform="translate(24 222) scale(.7)">{wm_dark}</g>'),
        'wordmark': (WM_W, 256, wm_light),
        'wordmark-white': (WM_W, 256, wm_dark),
        'app-icon': (256, 256, f'<rect width="256" height="256" rx="56" fill="{tile}"/><g transform="translate(28 28) scale(.78)">{sym}</g>'),
        # store icons: full square, the stores round the corners themselves
        'app-icon-store': (256, 256, f'<rect width="256" height="256" fill="{tile}"/><g transform="translate(28 28) scale(.78)">{sym}</g>'),
        'favicon': (256, 256, f'<rect width="256" height="256" rx="56" fill="{tile}"/><g transform="translate(16 16) scale(.875)">{small}</g>'),
    }
    for k, (w, h, body) in files.items():
        write(f'{S}/riovox-{k}.svg', w, h, body)
    os.makedirs(P, exist_ok=True)
    png(f'{S}/riovox-symbol.svg', f'{P}/riovox-symbol-1024.png', '--size', '1024')
    png(f'{S}/riovox-horizontal.svg', f'{P}/riovox-horizontal-1200.png', '--width', '1200', '--height', str(int(1200 * 256 / lw)))
    png(f'{S}/riovox-horizontal-on-dark.svg', f'{P}/riovox-horizontal-on-dark-1200.png', '--width', '1200', '--height', str(int(1200 * 256 / lw)))
    png(f'{S}/riovox-stacked.svg', f'{P}/riovox-stacked-960.png', '--width', '960', '--height', '800')
    png(f'{S}/riovox-app-icon-store.svg', f'{P}/ios-app-icon-1024.png', '--size', '1024')
    png(f'{S}/riovox-app-icon-store.svg', f'{P}/google-play-icon-512.png', '--size', '512')
    png(f'{S}/riovox-app-icon.svg', f'{P}/apple-touch-icon-180.png', '--size', '180')
    for n in (192, 512):
        png(f'{S}/riovox-app-icon.svg', f'{P}/icon-{n}.png', '--size', str(n))
    for n in (16, 32, 48):
        png(f'{S}/riovox-favicon.svg', f'{P}/favicon-{n}.png', '--size', str(n))
    subprocess.run(['python3', RENDER, f'{S}/riovox-favicon.svg', '--ico', f'{P}/favicon.ico', '--ico-sizes', '16', '32', '48'], check=True, capture_output=True)
    print(name, 'ok')

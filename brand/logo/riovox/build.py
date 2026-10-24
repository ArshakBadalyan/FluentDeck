"""Riovox logo concepts: symbols, app icons and lockups (SVG)."""
FUR, EAR, CREAM, INK = '#8B5A36', '#5E3B22', '#F6E7CF', '#24160D'
TEAL, TEAL_LT, CORAL, DARK, PAGE = '#0D7C86', '#2EC4CF', '#FF7A59', '#102326', '#F3F7F7'

def svg(w, h, body):
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}">\n{body}\n</svg>\n'

# Wordmark "riovox", drawn with round strokes on a 256-high line (x-height 90..200).
def wordmark(color, accent, eyes=False, x0=0):
    s = 'fill="none" stroke-width="28" stroke-linecap="round" stroke-linejoin="round"'
    o = lambda cx: f'<circle cx="{x0+cx}" cy="145" r="51" stroke="{color}" {s}/>'
    pupils = ''
    if eyes:  # the two o's look at you; the v is the nose
        pupils = ''.join(f'<circle cx="{x0+cx+10}" cy="137" r="14" fill="{color}"/>' for cx in (190, 420))
    return (f'<path d="M{x0+30} 200V96M{x0+30} 138c0-30 18-44 46-42" stroke="{color}" {s}/>'
            f'<path d="M{x0+110} 96V200" stroke="{color}" {s}/><circle cx="{x0+110}" cy="50" r="17" fill="{color}"/>'
            + o(190) +
            f'<path d="M{x0+268} 96l37 104 37-104" stroke="{accent}" {s}/>'
            + o(420) + pupils +
            f'<path d="M{x0+500} 96l86 104M{x0+586} 96l-86 104" stroke="{color}" {s}/>')
WM_W = 616

# A — Rio bubble: the otter's head is a speech bubble; the coral tail is its voice.
def a_symbol():
    return (f'<path fill="{CORAL}" d="M70 180l-34 50 62-26z"/>'
            f'<circle cx="36" cy="108" r="17" fill="{EAR}"/><circle cx="220" cy="108" r="17" fill="{EAR}"/>'
            f'<path fill="{FUR}" d="M128 48c60 0 102 34 102 80s-42 80-102 80-102-34-102-80 42-80 102-80z"/>'
            f'<path fill="{CREAM}" d="M128 130A36 36 0 1 0 128 186A36 36 0 1 0 128 130Z"/>'
            f'<circle cx="88" cy="106" r="12" fill="{INK}"/><circle cx="168" cy="106" r="12" fill="{INK}"/>'
            f'<circle cx="92" cy="101" r="4" fill="#fff"/><circle cx="172" cy="101" r="4" fill="#fff"/>'
            f'<path fill="{INK}" d="M128 124c12 0 20 5 20 11s-9 13-20 13-20-7-20-13 8-11 20-11z"/>')

# B — Rio floats on its back holding a card (the deck); the water is the "flow".
def b_symbol():
    return (f'<path fill="{FUR}" d="M48 150c-14-4-30-14-38-30 18 4 34 10 46 20z"/>'
            f'<ellipse cx="120" cy="150" rx="84" ry="34" fill="{FUR}"/>'
            f'<ellipse cx="128" cy="140" rx="58" ry="18" fill="{CREAM}"/>'
            f'<ellipse cx="62" cy="122" rx="11" ry="16" fill="{EAR}" transform="rotate(-20 62 122)"/><ellipse cx="80" cy="118" rx="11" ry="16" fill="{EAR}" transform="rotate(-10 80 118)"/>'
            f'<rect x="104" y="58" width="50" height="64" rx="9" fill="{CORAL}" transform="rotate(-12 129 90)"/>'
            f'<rect x="114" y="74" width="28" height="7" rx="3.5" fill="#fff" transform="rotate(-12 129 90)"/>'
            f'<rect x="114" y="88" width="20" height="7" rx="3.5" fill="#fff" transform="rotate(-12 129 90)"/>'
            f'<circle cx="112" cy="122" r="12" fill="{FUR}"/><circle cx="150" cy="116" r="12" fill="{FUR}"/>'
            f'<circle cx="190" cy="94" r="10" fill="{EAR}"/>'
            f'<circle cx="202" cy="120" r="36" fill="{FUR}"/>'
            f'<circle cx="222" cy="130" r="17" fill="{CREAM}"/>'
            f'<circle cx="234" cy="123" r="7" fill="{INK}"/>'
            f'<path d="M196 110q7-8 14 0" fill="none" stroke="{INK}" stroke-width="5" stroke-linecap="round"/>'
            f'<path fill="{TEAL}" d="M8 178c20-12 40-12 60 0s40 12 60 0 40-12 60 0 40 12 60 0v40a14 14 0 0 1-14 14H22a14 14 0 0 1-14-14z"/>')

# C — Rio in the river: the otter rises out of a wave; ripples spread out like a voice.
def c_symbol():
    s = 'fill="none" stroke-width="12" stroke-linecap="round"'
    return (f'<path d="M30 86a120 120 0 0 0 0 84M226 86a120 120 0 0 1 0 84" stroke="{TEAL_LT}" {s}/>'
            f'<path d="M6 66a160 160 0 0 0 0 124M250 66a160 160 0 0 1 0 124" stroke="{TEAL_LT}" {s} opacity=".55"/>'
            f'<circle cx="48" cy="92" r="16" fill="{EAR}"/><circle cx="208" cy="92" r="16" fill="{EAR}"/>'
            f'<path fill="{FUR}" d="M128 40c52 0 84 34 84 82 0 22-4 40-10 58H54c-6-18-10-36-10-58 0-48 32-82 84-82z"/>'
            f'<path fill="{CREAM}" d="M128 116A30 30 0 1 0 128 166A30 30 0 1 0 128 116Z"/>'
            f'<circle cx="96" cy="100" r="11" fill="{INK}"/><circle cx="160" cy="100" r="11" fill="{INK}"/>'
            f'<circle cx="99" cy="96" r="3.5" fill="#fff"/><circle cx="163" cy="96" r="3.5" fill="#fff"/>'
            f'<path fill="{INK}" d="M128 111c10 0 17 4 17 9s-8 11-17 11-17-6-17-11 7-9 17-9z"/>'
            f'<path fill="{TEAL}" d="M28 170c20-14 40-14 60 0s40 14 60 0 40-14 60 0 20 14 20 14v42a14 14 0 0 1-14 14H42a14 14 0 0 1-14-14z"/>')

SYMBOLS = {'a': a_symbol(), 'b': b_symbol(), 'c': c_symbol()}
EYES = {'a': True, 'b': True, 'c': True}  # the riovox wordmark: o-v-o is a little face
for k, sym in SYMBOLS.items():
    open(f'{k}-symbol.svg', 'w').write(svg(256, 256, sym))
    open(f'{k}-icon.svg', 'w').write(svg(256, 256,
        f'<rect width="256" height="256" rx="56" fill="{TEAL}"/>'
        + (f'<g transform="translate(28 28) scale(.78)">{sym}</g>' if k == 'a' else
           f'<rect width="256" height="256" rx="56" fill="{PAGE}"/><g transform="translate(20 20) scale(.84)">{sym}</g>')))
    # Horizontal lockup: symbol + wordmark, wordmark scaled to 0.62 of the symbol height.
    wm = wordmark(DARK, CORAL, EYES[k])
    open(f'{k}-lockup.svg', 'w').write(svg(300 + int(WM_W * .62) + 10, 256,
        f'{sym}<g transform="translate(290 49) scale(.62)">{wm}</g>'))
open('wordmark.svg', 'w').write(svg(WM_W, 256, wordmark(DARK, CORAL, True)))
print('ok')

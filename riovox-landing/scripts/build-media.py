#!/usr/bin/env python3
"""Rebuild the landing page media from real app screenshots.

Input:  assets-src/screenshots/onboarding-{light,dark}-{1..5}.png (1170x2532,
        rendered from the Flutter app — see README "Updating screenshots").
Output: public/media/app/*.webp, public/media/onboarding-tour-*.{webp,gif},
        public/media/og-image.png.   Needs Pillow:  pip install pillow
"""
import glob
import os

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, 'assets-src', 'screenshots')
OUT = os.path.join(ROOT, 'public', 'media')
FONTS = os.path.join(ROOT, '..', 'riovox-app', 'assets', 'fonts')


def stills():
    os.makedirs(os.path.join(OUT, 'app'), exist_ok=True)
    for path in sorted(glob.glob(os.path.join(SRC, 'onboarding-*.png'))):
        im = Image.open(path).convert('RGB').resize((585, 1266), Image.LANCZOS)
        name = os.path.basename(path).replace('.png', '.webp')
        im.save(os.path.join(OUT, 'app', name), 'WEBP', quality=82, method=6)


def tour(theme, width, fmt):
    pages = [
        Image.open(os.path.join(SRC, f'onboarding-{theme}-{i}.png')).convert('RGB')
        .resize((width, int(width * 2532 / 1170)), Image.LANCZOS)
        for i in range(1, 6)
    ]
    frames, durations = [], []
    for i, page in enumerate(pages):
        frames.append(page)
        durations.append(1800)
        nxt = pages[(i + 1) % len(pages)]
        for t in (0.25, 0.5, 0.75):  # short crossfade to the next page
            frames.append(Image.blend(page, nxt, t))
            durations.append(70)
    out = os.path.join(OUT, f'onboarding-tour-{theme}.{fmt}')
    if fmt == 'gif':
        pal = [f.convert('P', palette=Image.ADAPTIVE, colors=128) for f in frames]
        pal[0].save(out, save_all=True, append_images=pal[1:], duration=durations, loop=0, optimize=True, disposal=1)
    else:
        frames[0].save(out, 'WEBP', save_all=True, append_images=frames[1:], duration=durations, loop=0, quality=78, method=6)


def og_image():
    w, h = 1200, 630
    base = Image.new('RGB', (w, h), (7, 18, 20))
    glow = Image.new('RGB', (w, h), (7, 18, 20))
    d = ImageDraw.Draw(glow)
    d.ellipse((650, -150, 1350, 550), fill=(13, 124, 134))
    d.ellipse((-250, 350, 350, 900), fill=(120, 45, 30))
    og = Image.blend(base, glow.filter(ImageFilter.GaussianBlur(160)), 0.55)
    big = ImageFont.truetype(os.path.join(FONTS, 'Rubik-Medium.ttf'), 64)
    small = ImageFont.truetype(os.path.join(FONTS, 'Rubik-Regular.ttf'), 30)
    brand = ImageFont.truetype(os.path.join(FONTS, 'Rubik-Medium.ttf'), 34)
    d = ImageDraw.Draw(og)
    d.rounded_rectangle((70, 70, 118, 118), radius=12, fill=(13, 124, 134))
    d.text((134, 74), 'Riovox', font=brand, fill=(243, 244, 246))
    y = 190
    for line in ('Speak English', 'without the fear'):
        d.text((70, y), line, font=big, fill=(243, 244, 246))
        y += 78
    d.text((70, y + 18), 'Practice speaking with an AI tutor that', font=small, fill=(190, 205, 207))
    d.text((70, y + 58), 'never judges you. Free to start.', font=small, fill=(190, 205, 207))
    shot = Image.open(os.path.join(SRC, 'onboarding-dark-1.png')).convert('RGB').resize((270, 584), Image.LANCZOS)
    mask = Image.new('L', shot.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0) + shot.size, radius=34, fill=255)
    frame = Image.new('RGB', (286, 600), (30, 40, 42))
    fmask = Image.new('L', frame.size, 0)
    ImageDraw.Draw(fmask).rounded_rectangle((0, 0) + frame.size, radius=42, fill=255)
    og.paste(frame, (840, 70), fmask)
    og.paste(shot, (848, 78), mask)
    og.save(os.path.join(OUT, 'og-image.png'), optimize=True)


if __name__ == '__main__':
    stills()
    for theme in ('light', 'dark'):
        tour(theme, 390, 'webp')
        tour(theme, 300, 'gif')
    og_image()
    print('Media rebuilt in public/media')

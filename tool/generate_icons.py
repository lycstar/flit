#!/usr/bin/env python3
"""Render Android launcher resources from the approved SVG foreground.

Requires rsvg-convert and Pillow. Adaptive layers are 108dp; the launcher mask
shows the central 72dp. All mark vertices fit inside the central 66dp safe circle.
"""
from pathlib import Path
import io
import subprocess
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
BACKGROUND = '#101C30'


def render(svg, size):
    data = subprocess.check_output(['rsvg-convert', '-w', str(size), '-h', str(size)], input=svg.encode())
    return Image.open(io.BytesIO(data)).convert('RGBA')


def main():
    svg = (ROOT / 'assets/branding/icon_foreground.svg').read_text()
    # Legacy launcher icons use the same central 72dp as adaptive icons.
    visible = svg.replace('viewBox="0 0 108 108"', 'viewBox="18 18 72 72"')
    visible = visible.replace('</defs>', '</defs><rect x="18" y="18" width="72" height="72" fill="' + BACKGROUND + '"/>')
    (ROOT / 'assets/branding/icon.svg').write_text(visible)
    logo = render(visible, 512)
    logo_mask = Image.new('L', logo.size)
    ImageDraw.Draw(logo_mask).rounded_rectangle((0, 0, 511, 511), radius=113, fill=255)
    logo.putalpha(logo_mask)
    logo.save(ROOT / 'assets/branding/logo.png')
    for density, size, layer in [('mdpi', 48, 108), ('hdpi', 72, 162),
                                 ('xhdpi', 96, 216), ('xxhdpi', 144, 324),
                                 ('xxxhdpi', 192, 432)]:
        directory = ROOT / f'android/app/src/main/res/mipmap-{density}'
        render(svg, layer).save(directory / 'ic_launcher_foreground.png')
        image = render(visible, size * 4)
        for name, circular in [('ic_launcher', False), ('ic_launcher_round', True)]:
            mask = Image.new('L', image.size)
            draw = ImageDraw.Draw(mask)
            bounds = (0, 0, image.width - 1, image.height - 1)
            if circular:
                draw.ellipse(bounds, fill=255)
            else:
                draw.rounded_rectangle(bounds, radius=image.width * .22, fill=255)
            result = image.copy()
            result.putalpha(mask)
            result.resize((size, size), Image.Resampling.LANCZOS).save(directory / f'{name}.png')


if __name__ == '__main__':
    main()

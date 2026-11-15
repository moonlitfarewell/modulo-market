"""Regenerate Modulo Market's original 64x64 UI glyph textures.

Requires Pillow. All geometry is authored in this project; no third-party
icon font, image, or texture is imported.
"""
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "AddOns" / "ModuloMarket" / "Textures"
SIZE = 256
WHITE = (218, 225, 235, 255)
RED = (231, 112, 112, 255)


def make_canvas():
    return Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))


def stroke(draw, points, colour, width=22):
    draw.line(points, fill=colour, width=width, joint="curve")


def write(image, name):
    image.resize((64, 64), Image.Resampling.LANCZOS).save(OUT / f"{name}.tga", format="TGA")


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    image = make_canvas(); draw = ImageDraw.Draw(image)
    stroke(draw, [(48, 132), (105, 188), (211, 72)], WHITE, 24); write(image, "check")

    image = make_canvas(); draw = ImageDraw.Draw(image)
    stroke(draw, [(62, 62), (194, 194)], WHITE, 24)
    stroke(draw, [(194, 62), (62, 194)], WHITE, 24); write(image, "close")

    image = make_canvas(); draw = ImageDraw.Draw(image)
    stroke(draw, [(62, 62), (194, 194)], RED, 24)
    stroke(draw, [(194, 62), (62, 194)], RED, 24); write(image, "cancel")

    image = make_canvas(); draw = ImageDraw.Draw(image)
    draw.arc((43, 43, 213, 213), 38, 326, fill=WHITE, width=22)
    draw.polygon([(195, 36), (223, 102), (153, 92)], fill=WHITE); write(image, "refresh")

    image = make_canvas(); draw = ImageDraw.Draw(image)
    stroke(draw, [(49, 93), (128, 172), (207, 93)], WHITE, 22); write(image, "chevron-down")

    image = make_canvas(); draw = ImageDraw.Draw(image)
    draw.ellipse((34, 30, 157, 153), outline=WHITE, width=20)
    stroke(draw, [(139, 139), (224, 224)], WHITE, 22); write(image, "search")


if __name__ == "__main__":
    main()

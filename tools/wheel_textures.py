"""The radial wheels' textures (Claude Design, design/radial/wheel/) as TGA files.

For each number of sections N (1 to 8):
  wheel_bg_N.png  (512 x 512)  -> textures/ck_wheel_bg_N.tga, as is
  wheel_sel_N.png / wheel_off_N.png (512 x 512, section 1 at the top, the
  rest transparent) -> textures/ck_wheel_sel_N.tga / ck_wheel_off_N.tga,
  cut to the section and centred in the smallest power-of-2 canvas: they are
  rotated about their own centre by the code, then moved where that centre
  goes (the same as rotating the whole 512 image about the wheel's centre).

Prints the Lua table of the cut overlays: { width, height, x, y } in pixels of
the 512 canvas, x / y the overlay centre's offset from the wheel centre (y up).

Usage:
    python tools/wheel_textures.py
"""
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "design" / "radial" / "wheel"
DST = ROOT / "textures"


def pow2(n):
    p = 1
    while p < n:
        p *= 2
    return p


def main():
    lines = []
    for n in range(1, 9):
        bg = Image.open(SRC / f"wheel_bg_{n}.png").convert("RGBA")
        assert bg.size == (512, 512)
        bg.save(DST / f"ck_wheel_bg_{n}.tga", rle=False)
        imgs = {k: Image.open(SRC / f"wheel_{k}_{n}.png").convert("RGBA") for k in ("sel", "off")}
        # One cut for both (the union of their sections), so they sit alike
        boxes = [im.getbbox() for im in imgs.values()]
        x0, y0 = min(b[0] for b in boxes), min(b[1] for b in boxes)
        x1, y1 = max(b[2] for b in boxes), max(b[3] for b in boxes)
        # The cut centred on the section, a power of 2 each way
        w, h = pow2(x1 - x0), pow2(y1 - y0)
        left, top = (x0 + x1 - w) // 2, (y0 + y1 - h) // 2
        for kind, img in imgs.items():
            canvas = Image.new("RGBA", (w, h), (0, 0, 0, 0))
            canvas.paste(img.crop((max(0, left), max(0, top), min(512, left + w), min(512, top + h))),
                         (max(0, -left), max(0, -top)))
            canvas.save(DST / f"ck_wheel_{kind}_{n}.tga", rle=False)
        cut = {"sel": (w, h, (left + w / 2) - 256, 256 - (top + h / 2))}
        w, h, x, y = cut["sel"]
        lines.append(f"    [{n}] = {{ {w}, {h}, {x:g}, {y:g} }},")
        print(n, cut)
    print("local OVERLAY = {\n" + "\n".join(lines) + "\n}")


if __name__ == "__main__":
    main()

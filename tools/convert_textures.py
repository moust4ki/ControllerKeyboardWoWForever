"""Convert the Claude Design PNG textures to TGA files WoW can load.

Usage:
    pip install pillow
    python tools/convert_textures.py            # design/textures/*.png -> textures/*.tga
    python tools/convert_textures.py path/to/pngs
"""
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent


def is_pow2(n):
    return n > 0 and n & (n - 1) == 0


def main():
    src = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "design" / "textures"
    dst = ROOT / "textures"
    dst.mkdir(exist_ok=True)
    pngs = sorted(src.glob("*.png"))
    if not pngs:
        sys.exit(f"No PNG found in {src}")
    for png in pngs:
        img = Image.open(png).convert("RGBA")
        w, h = img.size
        if not (is_pow2(w) and is_pow2(h)):
            print(f"  warning: {png.name} is {w}x{h}, WoW needs powers of 2")
        out = dst / (png.stem + ".tga")
        img.save(out, rle=False)
        print(f"{png.name} ({w}x{h}) -> textures/{out.name}")
    print(f"{len(pngs)} textures converted.")


if __name__ == "__main__":
    main()

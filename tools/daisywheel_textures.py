"""The daisywheel's textures (Claude Design, design/daisywheel/) as TGA files.

The wheel background and the selected section are the radial wheel's for 8
sections (ck_wheel_bg_8, ck_wheel_sel_8, same pixels). The veil over the other
sections is cut like ck_wheel_sel_8 (256 x 256, its centre 143 above the
wheel's); the small ones are converted as they are.

Usage:
    python tools/daisywheel_textures.py
"""
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "design" / "daisywheel" / "design_handoff_daisywheel" / "textures"
DST = ROOT / "textures"

AS_IS = {
    "dw_hub": "ck_dw_hub", "dw_hub_lit": "ck_dw_hub_lit",
    "dw_key_target": "ck_dw_target", "dw_key_hover": "ck_dw_hover",
    "dw_petal_ring": "ck_dw_ring", "dw_petal_ring_sel": "ck_dw_ring_sel",
}


def main():
    for src, dst in AS_IS.items():
        img = Image.open(SRC / f"{src}.png").convert("RGBA")
        img.save(DST / f"{dst}.tga", rle=False)
        print(src, img.size, "->", dst)
    # The veil, cut as ck_wheel_sel_8 (tools/wheel_textures.py: 256 x 256 at
    # left 128, top -15 of the 512 canvas)
    dim = Image.open(SRC / "dw_section_dim.png").convert("RGBA")
    canvas = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
    canvas.paste(dim.crop((128, 0, 384, 241)), (0, 15))
    canvas.save(DST / "ck_dw_dim.tga", rle=False)
    print("dw_section_dim -> ck_dw_dim (256 x 256, centre 0, 143)")


if __name__ == "__main__":
    main()

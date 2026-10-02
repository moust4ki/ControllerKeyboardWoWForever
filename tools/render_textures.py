"""Draw the textures of the 2.0 panel that are not pictures but shapes:
the Xbox controller silhouette of the Gamepad tab (the design handoff's SVG,
redrawn), and the small round / rounded shapes the panel tints itself.

Writes design/textures/*.png; tools/convert_textures.py then makes the TGA
files the game loads.

Usage:
    pip install pillow
    python tools/render_textures.py
    python tools/convert_textures.py
"""
import math
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "design" / "textures"
SS = 4  # supersampling: drawn 4 times larger, then reduced (smooth edges)


def hex_rgb(value):
    value = value.lstrip("#")
    return tuple(int(value[i:i + 2], 16) for i in (0, 2, 4))


class Canvas:
    """An RGBA picture drawn in design pixels (`scale` texels each)."""

    def __init__(self, size, scale):
        self.size, self.scale = size, scale
        self.k = scale * SS
        self.img = Image.new("RGBA", (size * SS, size * SS), (0, 0, 0, 0))

    def pt(self, x, y):
        return (x * self.k, y * self.k)

    def _paint(self, mask, color, opacity=1.0):
        layer = Image.new("RGBA", self.img.size, hex_rgb(color) + (0,))
        if opacity < 1:
            mask = mask.point(lambda a: int(a * opacity))
        layer.putalpha(mask)
        self.img = Image.alpha_composite(self.img, layer)

    def fill(self, polygons, color, opacity=1.0):
        mask = Image.new("L", self.img.size, 0)
        draw = ImageDraw.Draw(mask)
        for poly in polygons:
            draw.polygon([self.pt(x, y) for x, y in poly], fill=255)
        self._paint(mask, color, opacity)

    def stroke(self, polylines, color, width, closed=True, opacity=1.0):
        mask = Image.new("L", self.img.size, 0)
        draw = ImageDraw.Draw(mask)
        w = max(1, round(width * self.k))
        for line in polylines:
            pts = [self.pt(x, y) for x, y in line]
            if closed:
                pts = pts + pts[:2]
            draw.line(pts, fill=255, width=w, joint="curve")
            # Round caps: ends of open lines
            if not closed:
                r = w / 2
                for x, y in (pts[0], pts[-1]):
                    draw.ellipse((x - r, y - r, x + r, y + r), fill=255)
        self._paint(mask, color, opacity)

    def save(self, name):
        out = self.img.resize((self.size, self.size), Image.BOX)
        out.save(OUT / name)
        print("design/textures/" + name)


def circle(cx, cy, r, steps=160):
    return [(cx + r * math.cos(2 * math.pi * i / steps), cy + r * math.sin(2 * math.pi * i / steps))
            for i in range(steps)]


def parse_path(d):
    """SVG path data (M L C H V Z, and their relative forms) -> lists of points."""
    tokens = []
    num = ""
    for ch in d.replace(",", " "):
        if ch.isalpha():
            if num.strip():
                tokens.append(float(num))
            num = ""
            tokens.append(ch)
        elif ch in " \n\t":
            if num.strip():
                tokens.append(float(num))
            num = ""
        elif ch == "-" and num.strip() and not num.endswith("e"):
            tokens.append(float(num))
            num = ch
        else:
            num += ch
    if num.strip():
        tokens.append(float(num))

    paths, cur, x, y, cmd, i = [], [], 0.0, 0.0, None, 0

    def take(n):
        nonlocal i
        vals = tokens[i:i + n]
        i += n
        return vals

    while i < len(tokens):
        if isinstance(tokens[i], str):
            cmd = tokens[i]
            i += 1
            if cmd in "Zz":
                if cur:
                    paths.append(cur)
                cur = []
                continue
        rel = cmd.islower()
        c = cmd.upper()
        if c == "M":
            dx, dy = take(2)
            x, y = (x + dx, y + dy) if rel else (dx, dy)
            if cur:
                paths.append(cur)
            cur = [(x, y)]
            cmd = "l" if rel else "L"
        elif c == "L":
            dx, dy = take(2)
            x, y = (x + dx, y + dy) if rel else (dx, dy)
            cur.append((x, y))
        elif c == "H":
            (dx,) = take(1)
            x = x + dx if rel else dx
            cur.append((x, y))
        elif c == "V":
            (dy,) = take(1)
            y = y + dy if rel else dy
            cur.append((x, y))
        elif c == "C":
            x1, y1, x2, y2, x3, y3 = take(6)
            if rel:
                x1, y1, x2, y2, x3, y3 = x + x1, y + y1, x + x2, y + y2, x + x3, y + y3
            x0, y0 = x, y
            for s in range(1, 25):
                t = s / 24
                mt = 1 - t
                cur.append((mt ** 3 * x0 + 3 * mt * mt * t * x1 + 3 * mt * t * t * x2 + t ** 3 * x3,
                            mt ** 3 * y0 + 3 * mt * mt * t * y1 + 3 * mt * t * t * y2 + t ** 3 * y3))
            x, y = x3, y3
        else:
            raise ValueError("path command " + cmd)
    if cur:
        paths.append(cur)
    return paths


# ---------------------------------------------------------------------------
# The Xbox controller silhouette (Gamepad tab): the handoff's SVG, 480 x 344
# design pixels, drawn at 2x in the top left of a 1024 x 1024 texture (the
# panel shows it with SetTexCoord(0, 960/1024, 0, 688/1024)).
# ---------------------------------------------------------------------------
SHOULDERS = ("M64 54 C66 42 78 33 100 26 C125 18 146 14 156 14 L176 24 L304 24 L324 14 "
             "C334 14 355 18 380 26 C402 33 414 42 416 54")
BODY = ("M61 60 C80 48 120 34 145 31 C155 30 162 37 167 44 L190 74 C196 80 204 82 213 82 L267 82 "
        "C276 82 284 80 290 74 L313 44 C318 37 325 30 335 31 C360 34 400 48 419 60 C432 72 442 104 452 146 "
        "C463 194 474 252 476 290 C478 316 468 330 452 330 C438 330 428 324 418 314 L372 268 "
        "C352 252 334 246 310 246 L170 246 C146 246 128 252 108 268 L62 314 C52 324 42 330 28 330 "
        "C12 330 2 316 4 290 C6 252 17 194 28 146 C38 104 48 72 61 60 Z")
NOTCH = "M176 24 L167 44 M304 24 L313 44"
CROSS = "M166 130 h32 v54 h54 v32 h-54 v54 h-32 v-54 h-54 v-32 h54 z"


def pad():
    c = Canvas(1024, 2)
    c.fill(parse_path(SHOULDERS), "#140f0a")
    c.stroke(parse_path(SHOULDERS), "#5a4630", 2, closed=False)
    c.fill(parse_path(BODY), "#1a140e", opacity=0.9)
    c.stroke(parse_path(BODY), "#5a4630", 2)
    c.stroke(parse_path(NOTCH), "#5a4630", 2, closed=False)
    c.fill([circle(110, 100, 38)], "#120d08")
    c.stroke([circle(110, 100, 38)], "#3a2c1d", 1.5)
    c.stroke([circle(182, 200, 76)], "#3a2c1d", 1.5)
    c.fill(parse_path(CROSS), "#120d08")
    c.stroke(parse_path(CROSS), "#3a2c1d", 1.5)
    c.fill([circle(312, 212, 36)], "#120d08")
    c.stroke([circle(312, 212, 36)], "#3a2c1d", 1.5)
    c.save("ck_pad.png")


# ---------------------------------------------------------------------------
# Shapes the panel tints (white), 64 x 64 for a 32 design pixel shape
# ---------------------------------------------------------------------------
def disc():
    c = Canvas(64, 2)
    c.fill([circle(16, 16, 15.5)], "#ffffff")
    c.save("ck_dot.png")


def ring():
    # A 2 px ring for a 44 px round slot (the slot's own edge)
    c = Canvas(128, 128 / 46)
    c.stroke([circle(23, 23, 22)], "#ffffff", 2)
    c.save("ck_ring.png")


def ring_dash():
    # The editor's target: 2 px dashes, 4 px out of a 52 px slot (60 across)
    c = Canvas(128, 128 / 62)
    dashes, r = 24, 30
    for i in range(dashes):
        a0 = 2 * math.pi * i / dashes
        a1 = a0 + 2 * math.pi / dashes * 0.55
        arc = [(31 + r * math.cos(a0 + (a1 - a0) * s / 8), 31 + r * math.sin(a0 + (a1 - a0) * s / 8))
               for s in range(9)]
        c.stroke([arc], "#ffffff", 2, closed=False)
    c.save("ck_ring_dash.png")


def diamond():
    c = Canvas(32, 2)
    c.fill([[(8, 0.5), (15.5, 8), (8, 15.5), (0.5, 8)]], "#ffffff")
    c.save("ck_diamond.png")


def hatch():
    # Unavailable: diagonal stripes (3 px dark, 3 px darker) in a disc
    c = Canvas(64, 2)
    c.fill([circle(16, 16, 16)], "#0c0906")
    stripes = []
    for k in range(-40, 40):
        o = k * 6
        stripes.append([(o, 0), (o + 3, 0), (o + 3 + 32, 32), (o + 32, 32)])
    stripe = Canvas(64, 2)
    stripe.fill(stripes, "#1a1510")
    mask = Image.new("L", c.img.size, 0)
    ImageDraw.Draw(mask).ellipse((0, 0, c.img.size[0] - 1, c.img.size[1] - 1), fill=255)
    stripe.img.putalpha(Image.composite(stripe.img.getchannel("A"), Image.new("L", c.img.size, 0), mask))
    c.img = Image.alpha_composite(c.img, stripe.img)
    c.save("ck_hatch.png")


def triangle():
    # The list's "more below" arrow (flipped for "more above")
    c = Canvas(32, 2)
    c.fill([[(2, 4), (14, 4), (8, 12)]], "#ffffff")
    c.save("ck_tri.png")


def rounded(radius, border):
    """A rounded box for nine-slices: 32 texels for 16 px, corners of 8 texels."""
    def shape(canvas, inset, color):
        r = radius - inset
        x0, y0, x1, y1 = inset, inset, 16 - inset, 16 - inset
        pts = []
        for cx, cy, a0 in ((x1 - r, y0 + r, -90), (x1 - r, y1 - r, 0), (x0 + r, y1 - r, 90), (x0 + r, y0 + r, 180)):
            for s in range(0, 13):
                a = math.radians(a0 + 90 * s / 12)
                pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
        canvas.fill([pts], color)

    fill = Canvas(32, 2)
    shape(fill, 0, "#ffffff")
    fill.save("ck_box%d.png" % radius)
    if border:
        line = Canvas(32, 2)
        shape(line, 0, "#ffffff")
        hole = Canvas(32, 2)
        shape(hole, border, "#ffffff")
        alpha = Image.eval(hole.img.getchannel("A"), lambda a: 255 - a)
        line.img.putalpha(Image.composite(line.img.getchannel("A"), Image.new("L", line.img.size, 0), alpha))
        line.save("ck_box%d_line%d.png" % (radius, border))


def chip():
    # The grey pill of a text glyph (Select, Start, L4...): a nine-slice,
    # 22 px high, its gradient #7a7a7a -> #454545, a 1 px #151515 edge
    c = Canvas(64, 2)
    w, h, r = 32, 22, 11
    top, bottom = hex_rgb("#7a7a7a"), hex_rgb("#454545")
    grad = Image.new("RGBA", c.img.size, (0, 0, 0, 0))
    gd = ImageDraw.Draw(grad)
    for y in range(int(h * c.k)):
        t = y / (h * c.k)
        col = tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3)) + (255,)
        gd.line([(0, y + int(5 * c.k)), (grad.size[0], y + int(5 * c.k))], fill=col)
    mask = Image.new("L", c.img.size, 0)
    md = ImageDraw.Draw(mask)
    k = c.k
    md.rounded_rectangle((0, 5 * k, w * k - 1, (5 + h) * k - 1), radius=r * k, fill=255)
    edge = Image.new("RGBA", c.img.size, hex_rgb("#151515") + (255,))
    edge.putalpha(mask)
    inner = Image.new("L", c.img.size, 0)
    ImageDraw.Draw(inner).rounded_rectangle((k, 6 * k, w * k - 1 - k, (4 + h) * k - 1), radius=(r - 1) * k, fill=255)
    grad.putalpha(inner)
    c.img = Image.alpha_composite(Image.alpha_composite(c.img, edge), grad)
    c.save("ck_chip.png")


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    pad()
    disc()
    ring()
    ring_dash()
    diamond()
    hatch()
    triangle()
    rounded(3, 2)
    rounded(4, 1)
    rounded(4, 2)
    chip()


if __name__ == "__main__":
    main()

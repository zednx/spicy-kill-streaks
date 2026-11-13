"""Generates the Spicy Kill Streaks logo from code (needs Pillow).

    python3 tools/make_art.py

Writes:
  docs/logo.png       1024px square project logo (CurseForge, GitHub)
  docs/logo-400.png   400px logo for sites with small upload limits

Same look as Spicy Side Quests' logo (tile and chilli), with a flame trail for the streak and a
gold skull for the kill.
"""
import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent.parent


def bezier(p0, p1, p2, p3, n=80):
    pts = []
    for i in range(n + 1):
        t = i / n
        a, b, c, d = (1 - t) ** 3, 3 * t * (1 - t) ** 2, 3 * t * t * (1 - t), t ** 3
        pts.append((a * p0[0] + b * p1[0] + c * p2[0] + d * p3[0], a * p0[1] + b * p1[1] + c * p2[1] + d * p3[1]))
    return pts


def odd(n):
    n = max(3, int(round(n)))
    return n if n % 2 else n + 1


def draw_chilli(S):
    """Chilli on a transparent S x S canvas. Designed on a 512 grid, scaled by k."""
    k = S / 512
    P = lambda *pts: [(x * k, y * k) for x, y in pts]  # noqa: E731
    B = lambda a, b, c, d, n=80: bezier(*P(a, b, c, d), n)  # noqa: E731

    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))

    def layer(points, fill, blur=0):
        lay = Image.new("RGBA", (S, S), (0, 0, 0, 0))
        ImageDraw.Draw(lay).polygon(points, fill=fill)
        if blur:
            lay = lay.filter(ImageFilter.GaussianBlur(blur * k))
        return lay

    body = B((350, 150), (470, 260), (360, 470), (95, 445)) + B((95, 445), (300, 400), (330, 260), (245, 175)) + B((245, 175), (275, 130), (320, 125), (350, 150), 20)

    outline = layer(body, (40, 6, 6, 255)).filter(ImageFilter.MaxFilter(odd(17 * k)))
    img.alpha_composite(outline)
    img.alpha_composite(layer(body, (214, 32, 28, 255)))
    shade = B((392, 250), (400, 380), (300, 450), (110, 440)) + B((110, 440), (290, 415), (360, 330), (392, 250), 30)
    img.alpha_composite(layer(shade, (150, 14, 16, 200), blur=6))
    gloss = B((300, 190), (360, 220), (360, 300), (318, 340), 30) + B((318, 340), (335, 290), (330, 230), (300, 190), 30)
    img.alpha_composite(layer(gloss, (255, 190, 170, 210), blur=4))

    calyx = P((225, 165), (260, 120), (300, 108), (345, 118), (372, 150), (340, 160), (300, 150), (262, 172))
    img.alpha_composite(layer(calyx, (16, 40, 10, 255)).filter(ImageFilter.MaxFilter(odd(13 * k))))
    d = ImageDraw.Draw(img)
    d.polygon(calyx, fill=(70, 160, 40, 255))
    stem = B((300, 112), (295, 70), (320, 40), (365, 35), 40)
    for w, col in ((30 * k, (16, 40, 10, 255)), (18 * k, (90, 175, 50, 255))):
        d.line(stem, fill=col, width=int(w), joint="curve")
        for p in (stem[0], stem[-1]):
            d.ellipse((p[0] - w / 2, p[1] - w / 2, p[0] + w / 2, p[1] + w / 2), fill=col)
    return img


def draw_flames(S):
    """Flames rising from behind the chilli: it's on fire (512 grid, same as the chilli)."""
    k = S / 512
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))

    def tongue(cx, cy, r, h, lean):
        # A flame: round at the bottom, curling up to a point at (cx + lean, cy - h)
        tip = (cx + lean, cy - h)
        pts = bezier((cx - r, cy), (cx - r * 1.1, cy - h * 0.45), (tip[0] - r * 0.5, tip[1] + h * 0.35), tip, 40)
        pts += bezier(tip, (tip[0] + r * 0.15, tip[1] + h * 0.45), (cx + r * 1.1, cy - h * 0.35), (cx + r, cy), 40)
        pts += [(cx + r * math.cos(a), cy + r * 0.9 * math.sin(a)) for a in (i * math.pi / 20 for i in range(21))]
        return [(x * k, y * k) for x, y in pts]

    # (base x, base y, radius, height, lean) along the inside of the chilli's curve, leaning
    # out to the open left side; tallest in the middle
    tongues = [
        (268, 222, 44, 170, -55),
        (292, 300, 56, 250, -85),
        (276, 368, 58, 270, -100),
        (215, 410, 52, 235, -85),
        (150, 430, 44, 180, -65),
        (100, 440, 32, 120, -45),
    ]

    def flames(scale, fill):
        lay = Image.new("RGBA", (S, S), (0, 0, 0, 0))
        dr = ImageDraw.Draw(lay)
        for cx, cy, r, h, lean in tongues:
            # smaller layers sit low in the flame, like the hot core of a real one
            dr.polygon(tongue(cx, cy + r * (1 - scale) * 0.6, r * scale, h * scale, lean * scale), fill=fill)
        return lay

    # dark outline (same weight as the chilli's), then orange, yellow and a white-hot core
    img.alpha_composite(flames(1.0, (60, 12, 4, 255)).filter(ImageFilter.MaxFilter(odd(15 * k))))
    img.alpha_composite(flames(1.0, (245, 90, 20, 255)))
    img.alpha_composite(flames(0.66, (255, 180, 30, 255)).filter(ImageFilter.GaussianBlur(1.5 * k)))
    img.alpha_composite(flames(0.34, (255, 240, 190, 255)).filter(ImageFilter.GaussianBlur(2 * k)))
    return img


def draw_skull(S):
    """A chunky gold skull with a dark outline and a soft glow (512 grid)."""
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    k = S / 512
    cranium = (96 * k, 40 * k, 416 * k, 340 * k)
    jaw = (170 * k, 290 * k, 342 * k, 440 * k)

    def shape(fill, grow=0):
        lay = Image.new("RGBA", (S, S), (0, 0, 0, 0))
        dr = ImageDraw.Draw(lay)
        dr.ellipse(cranium, fill=fill)
        dr.rounded_rectangle(jaw, radius=int(40 * k), fill=fill)
        if grow:
            lay = lay.filter(ImageFilter.MaxFilter(odd(grow * k)))
        return lay

    glow = shape((255, 190, 40, 150), 41).filter(ImageFilter.GaussianBlur(26 * k))
    img.alpha_composite(glow)
    img.alpha_composite(shape((70, 40, 0, 255), 29))
    img.alpha_composite(shape((255, 209, 0, 255)))

    # top highlight, as on the Side Quests "!"
    hl = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    ImageDraw.Draw(hl).ellipse((170 * k, 70 * k, 330 * k, 150 * k), fill=(255, 245, 190, 140))
    img.alpha_composite(hl.filter(ImageFilter.GaussianBlur(12 * k)))

    d = ImageDraw.Draw(img)
    dark = (70, 40, 0, 255)
    # eye sockets, nose, and the gaps between the teeth
    d.ellipse((150 * k, 175 * k, 245 * k, 275 * k), fill=dark)
    d.ellipse((267 * k, 175 * k, 362 * k, 275 * k), fill=dark)
    d.polygon([(256 * k, 285 * k), (230 * k, 335 * k), (282 * k, 335 * k)], fill=dark)
    for x in (213, 256, 299):
        d.rounded_rectangle(((x - 7) * k, 365 * k, (x + 7) * k, 440 * k), radius=int(5 * k), fill=dark)
    return img


def draw_logo(S):
    """Rounded dark tile, warm glow, big chilli with a flame trail, gold skull top-right."""
    W = S * 2  # supersample
    tile = Image.new("RGBA", (W, W), (0, 0, 0, 0))

    # vertical gradient background
    grad = Image.new("RGBA", (W, W))
    gd = ImageDraw.Draw(grad)
    for y in range(W):
        t = y / W
        c = (int(36 - 18 * t), int(26 - 13 * t), int(28 - 14 * t), 255)
        gd.line([(0, y), (W, y)], fill=c)
    # warm radial glow behind the chilli
    glow = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    ImageDraw.Draw(glow).ellipse((W * 0.18, W * 0.22, W * 0.86, W * 0.90), fill=(255, 90, 30, 120))
    grad.alpha_composite(glow.filter(ImageFilter.GaussianBlur(W * 0.12)))

    mask = Image.new("L", (W, W), 0)
    r = int(W * 0.2)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, W - 1, W - 1), radius=r, fill=255)
    tile.paste(grad, (0, 0), mask)

    # chilli and its flame trail, placed like the Side Quests chilli
    cs = int(W * 0.86)
    ox, oy = int(W * 0.03), int(W * 0.10)
    flames = draw_flames(cs)
    clipped = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    clipped.alpha_composite(flames, (ox, oy))
    flame_mask = Image.new("L", (W, W), 0)
    flame_mask.paste(clipped.getchannel("A"), (0, 0), mask)  # keep the flames inside the tile
    clipped.putalpha(flame_mask)
    tile.alpha_composite(clipped)

    chilli = draw_chilli(cs)
    shadow = Image.new("RGBA", (cs, cs), (0, 0, 0, 0))
    shadow.putalpha(chilli.getchannel("A").point(lambda a: int(a * 0.55)))
    shadow = shadow.filter(ImageFilter.GaussianBlur(W * 0.015))
    tile.alpha_composite(shadow, (ox + int(W * 0.015), oy + int(W * 0.025)))
    tile.alpha_composite(chilli, (ox, oy))

    # inner border, drawn last so the flames stay inside it
    border = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    bw = max(2, int(W * 0.012))
    ImageDraw.Draw(border).rounded_rectangle((bw, bw, W - 1 - bw, W - 1 - bw), radius=r - bw, outline=(255, 140, 60, 110), width=bw)
    tile.alpha_composite(border)

    # kill skull
    ks = int(W * 0.36)
    tile.alpha_composite(draw_skull(ks), (int(W * 0.60), int(W * 0.06)))

    return tile.resize((S, S), Image.LANCZOS)


if __name__ == "__main__":
    (ROOT / "docs").mkdir(exist_ok=True)
    logo = draw_logo(1024)
    logo.save(ROOT / "docs" / "logo.png")
    logo.resize((400, 400), Image.LANCZOS).save(ROOT / "docs" / "logo-400.png")
    print("wrote docs/logo.png, docs/logo-400.png")

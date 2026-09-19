"""Generate Tanjiro's classic Shirt/Pants textures (585x559 Roblox clothing template).

Shirt: black Corps uniform under the green/black ichimatsu (checkered) haori, which is worn open at the front.
Pants: black uniform trousers with white kyahan leg wraps below the knee.
The Corps kanji on the uniform back is covered by the haori, so it is not drawn.
Upload the PNGs as Shirt/Pants and paste the IDs into data/assets.json (see docs/ASSETS.md).
"""
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
SIZE = (585, 559)
UNIFORM = (22, 22, 28)
UNIFORM_SEAM = (40, 40, 50)
GREEN = (27, 118, 86)
CHECK_BLACK = (18, 18, 20)
BUTTON = (201, 170, 96)
WRAP = (236, 234, 226)
WRAP_LINE = (196, 192, 182)

# Classic template regions (x, y, w, h).
TORSO = {"up": (231, 8, 128, 64), "front": (231, 74, 128, 128), "right": (165, 74, 64, 128),
         "back": (427, 74, 128, 128), "left": (361, 74, 64, 128), "down": (231, 204, 128, 64)}
# Each limb block: up/down caps and four 64x128 faces. Right limb on the left of the template, left limb on the right.
LIMBS = {
    "right": {"up": (217, 289, 64, 64), "down": (217, 485, 64, 64), "faces": [(19, 355), (85, 355), (151, 355), (217, 355)]},
    "left": {"up": (308, 289, 64, 64), "down": (308, 485, 64, 64), "faces": [(308, 355), (374, 355), (440, 355), (506, 355)]},
}
CHECK = 16


def checker(draw, box, phase=0):
    x, y, w, h = box
    for row in range(0, h, CHECK):
        for col in range(0, w, CHECK):
            green = ((row // CHECK) + (col // CHECK) + phase) % 2 == 0
            draw.rectangle([x + col, y + row, min(x + col + CHECK, x + w) - 1, min(y + row + CHECK, y + h) - 1], fill=GREEN if green else CHECK_BLACK)


def fill(draw, box, color):
    x, y, w, h = box
    draw.rectangle([x, y, x + w - 1, y + h - 1], fill=color)


def shirt():
    img = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for name, box in TORSO.items():
        checker(d, box) if name in ("back", "left", "right") else fill(d, box, UNIFORM)
    # Front: haori panels on both sides, open over the black uniform with its brass buttons.
    x, y, w, h = TORSO["front"]
    checker(d, (x, y, 34, h))
    checker(d, (x + w - 34, y, 34, h), phase=1)
    d.line([x + w // 2, y, x + w // 2, y + h], fill=UNIFORM_SEAM, width=2)
    for i in range(4):
        cy = y + 18 + i * 28
        d.ellipse([x + w // 2 - 4, cy - 4, x + w // 2 + 4, cy + 4], fill=BUTTON)
    # Collar of the uniform on the shoulders/top.
    fill(d, TORSO["up"], UNIFORM)
    # Sleeves: haori checker, uniform cuff showing at the wrist.
    for limb in LIMBS.values():
        for fx, fy in limb["faces"]:
            checker(d, (fx, fy, 64, 128))
            fill(d, (fx, fy + 112, 64, 16), UNIFORM)
        checker(d, limb["up"])
        fill(d, limb["down"], UNIFORM)
    return img


def pants():
    img = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for box in TORSO.values():
        fill(d, box, UNIFORM)
    # White belt at the top of the trousers.
    x, y, w, _ = TORSO["front"]
    fill(d, (x, y, w, 10), WRAP)
    bx, by, bw, _ = TORSO["back"]
    fill(d, (bx, by, bw, 10), WRAP)
    for limb in LIMBS.values():
        fill(d, limb["up"], UNIFORM)
        fill(d, limb["down"], WRAP)
        for fx, fy in limb["faces"]:
            fill(d, (fx, fy, 64, 128), UNIFORM)
            # Kyahan wraps from shin to ankle with cross-bound ties.
            fill(d, (fx, fy + 70, 64, 58), WRAP)
            for i in range(3):
                ty = fy + 80 + i * 16
                d.line([fx, ty, fx + 63, ty + 6], fill=WRAP_LINE, width=2)
    return img


def generate():
    out = ROOT / "assets" / "clothing"
    out.mkdir(parents=True, exist_ok=True)
    shirt().save(out / "tanjiro_shirt.png")
    pants().save(out / "tanjiro_pants.png")
    print("PASS generated assets/clothing/tanjiro_shirt.png and tanjiro_pants.png")


if __name__ == "__main__":
    generate()

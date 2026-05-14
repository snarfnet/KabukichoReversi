from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "KabukichoReversi" / "Assets.xcassets"
OUT = ROOT / "AppStoreScreenshots"

COLORS = {
    "bg": (12, 5, 24),
    "street": (26, 14, 36),
    "panel": (34, 19, 47, 235),
    "card": (255, 255, 255, 18),
    "line": (255, 255, 255, 36),
    "text": (246, 238, 247),
    "sub": (182, 160, 194),
    "neon": (255, 24, 148),
    "cyan": (30, 242, 230),
    "yellow": (245, 166, 48),
    "green": (61, 202, 95),
    "purple": (180, 82, 225),
}

PLAYERS = [
    ("ルナ", "リップ", "CharRuna", "PieceLipstick", COLORS["neon"]),
    ("アイリ", "ボトル", "CharAiri", "PieceStrongZero", COLORS["green"]),
    ("ミユ", "ネイル", "CharMiyu", "PieceNail", COLORS["purple"]),
    ("ユメ", "チョコ", "CharYume", "PieceChocolate", COLORS["yellow"]),
]


def font(size, bold=False):
    candidates = [
        r"C:\Windows\Fonts\meiryob.ttc" if bold else r"C:\Windows\Fonts\meiryo.ttc",
        r"C:\Windows\Fonts\YuGothB.ttc" if bold else r"C:\Windows\Fonts\YuGothR.ttc",
        r"C:\Windows\Fonts\msgothic.ttc",
    ]
    for path in candidates:
        if Path(path).exists():
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def asset(name):
    folder = next(ASSETS.glob(f"{name}.imageset"))
    image_file = next(p for p in folder.iterdir() if p.suffix.lower() in {".png", ".jpg", ".jpeg"})
    return Image.open(image_file).convert("RGBA")


def cover(img, size):
    w, h = img.size
    sw, sh = size
    scale = max(sw / w, sh / h)
    resized = img.resize((int(w * scale), int(h * scale)), Image.LANCZOS)
    left = (resized.width - sw) // 2
    top = (resized.height - sh) // 2
    return resized.crop((left, top, left + sw, top + sh))


def contain(img, size):
    w, h = img.size
    sw, sh = size
    scale = min(sw / w, sh / h)
    return img.resize((int(w * scale), int(h * scale)), Image.LANCZOS)


def rounded(draw, box, radius, fill, outline=None, width=1):
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=width)


def text(draw, xy, value, size, fill=None, bold=False, anchor=None, align="left"):
    draw.text(xy, value, font=font(size, bold), fill=fill or COLORS["text"], anchor=anchor, align=align)


def background(size):
    w, h = size
    img = Image.new("RGBA", size, COLORS["bg"])
    draw = ImageDraw.Draw(img, "RGBA")
    title_bg = cover(asset("TitleBackground"), size)
    img.alpha_composite(title_bg)
    draw.rectangle((0, 0, w, h), fill=(12, 5, 24, 150))
    for y in range(h):
        alpha = int(210 * (y / h) ** 1.8)
        draw.line((0, y, w, y), fill=(12, 5, 24, alpha))
    for x in (int(w * 0.08), int(w * 0.92)):
        draw.rectangle((x - 2, 0, x + 2, h), fill=(255, 24, 148, 26))
        step = int(h * 0.075)
        for y in range(70, h, step):
            rounded(draw, (x - 28, y, x + 28, y + 84), 10, (0, 0, 0, 0), (255, 24, 148, 160), 3)
    return img


def ad_bar(draw, w, y):
    draw.rectangle((0, y, w, y + 50), fill=(0, 0, 0, 210))
    text(draw, (w // 2, y + 25), "広告", 20, (255, 255, 255, 120), bold=True, anchor="mm")


def title_block(draw, w, y):
    text(draw, (w // 2, y), "KABUKICHO", int(w * 0.034), COLORS["cyan"], True, "ma")
    text(draw, (w // 2, y + int(w * 0.07)), "歌舞伎町", int(w * 0.115), COLORS["neon"], True, "ma")
    text(draw, (w // 2, y + int(w * 0.18)), "リバーシ", int(w * 0.075), COLORS["text"], True, "ma")
    text(draw, (w // 2, y + int(w * 0.27)), "4人のキャラクターが夜の盤面で競う、歌舞伎町風リバーシ", int(w * 0.03), COLORS["sub"], True, "ma")


def character_picker(img, top, scale):
    draw = ImageDraw.Draw(img, "RGBA")
    w, _ = img.size
    margin = int(w * 0.08)
    box = (margin, top, w - margin, top + int(520 * scale))
    rounded(draw, box, int(22 * scale), COLORS["panel"], (255, 255, 255, 42), 2)
    text(draw, (box[0] + int(34 * scale), box[1] + int(42 * scale)), "キャラを選ぶ", int(30 * scale), COLORS["sub"], True)
    card_w = (box[2] - box[0] - int(78 * scale)) // 2
    card_h = int(180 * scale)
    for idx, (name, piece, char_name, _, color) in enumerate(PLAYERS):
        col = idx % 2
        row = idx // 2
        x = box[0] + int(34 * scale) + col * (card_w + int(34 * scale))
        y = box[1] + int(86 * scale) + row * (card_h + int(28 * scale))
        fill = tuple(list(color) + [45]) if idx == 0 else COLORS["card"]
        rounded(draw, (x, y, x + card_w, y + card_h), int(16 * scale), fill, tuple(list(color) + [190]), 3 if idx == 0 else 2)
        portrait = cover(asset(char_name), (int(96 * scale), int(96 * scale)))
        mask = Image.new("L", portrait.size, 0)
        ImageDraw.Draw(mask).rounded_rectangle((0, 0, *portrait.size), radius=int(14 * scale), fill=255)
        img.paste(portrait, (x + int(22 * scale), y + int(26 * scale)), mask)
        text(draw, (x + int(140 * scale), y + int(40 * scale)), name, int(42 * scale), COLORS["text"], True)
        text(draw, (x + int(140 * scale), y + int(92 * scale)), piece, int(26 * scale), color, True)
    return box[3]


def draw_board(img, top, scale, mode=0):
    draw = ImageDraw.Draw(img, "RGBA")
    w, _ = img.size
    board = min(int(w * 0.84), int(720 * scale))
    x0 = (w - board) // 2
    cell = board // 10
    rounded(draw, (x0 - 6, top - 6, x0 + board + 6, top + board + 6), int(12 * scale), (255, 24, 148, 40), (255, 24, 148, 150), 3)
    texture = cover(asset("BoardTexture"), (board, board))
    img.alpha_composite(texture, (x0, top))
    for r in range(10):
        for c in range(10):
            x = x0 + c * cell
            y = top + r * cell
            draw.rectangle((x, y, x + cell, y + cell), outline=(255, 255, 255, 45), width=1)
    positions = [
        (4, 4, 0), (4, 5, 1), (5, 4, 2), (5, 5, 3),
        (3, 4, 0), (3, 5, 0), (4, 3, 2), (5, 3, 2),
        (6, 5, 3), (6, 6, 3), (2, 5, 1), (2, 6, 1),
    ]
    if mode >= 1:
        positions += [(3, 3, 0), (4, 6, 0), (5, 6, 3), (6, 4, 2), (7, 5, 1), (7, 6, 1)]
    if mode >= 2:
        positions += [(1, 5, 0), (1, 6, 0), (2, 4, 2), (6, 7, 3), (7, 7, 3), (8, 6, 1)]
    for r, c, player in positions:
        _, _, _, piece, color = PLAYERS[player]
        px = x0 + c * cell + cell // 2
        py = top + r * cell + cell // 2
        draw.ellipse((px - cell * 0.36, py - cell * 0.36, px + cell * 0.36, py + cell * 0.36), fill=tuple(list(color) + [210]))
        pimg = contain(asset(piece), (int(cell * 0.58), int(cell * 0.58)))
        img.alpha_composite(pimg, (px - pimg.width // 2, py - pimg.height // 2))
    for r, c in [(3, 6), (4, 7), (6, 3)]:
        x = x0 + c * cell + cell // 2
        y = top + r * cell + cell // 2
        draw.ellipse((x - cell * 0.14, y - cell * 0.14, x + cell * 0.14, y + cell * 0.14), fill=(30, 242, 230, 110))
    return top + board


def scorebar(img, top, scale):
    draw = ImageDraw.Draw(img, "RGBA")
    w, _ = img.size
    margin = int(w * 0.04)
    gap = int(10 * scale)
    card_w = (w - margin * 2 - gap * 3) // 4
    counts = [5, 4, 4, 3]
    for i, (name, _, char_name, _, color) in enumerate(PLAYERS):
        x = margin + i * (card_w + gap)
        y = top
        rounded(draw, (x, y, x + card_w, y + int(128 * scale)), int(14 * scale), COLORS["panel"], tuple(list(color) + [180 if i == 0 else 70]), 3 if i == 0 else 1)
        portrait = cover(asset(char_name), (int(56 * scale), int(56 * scale)))
        mask = Image.new("L", portrait.size, 0)
        ImageDraw.Draw(mask).rounded_rectangle((0, 0, *portrait.size), radius=int(9 * scale), fill=255)
        img.paste(portrait, (x + int(12 * scale), y + int(14 * scale)), mask)
        text(draw, (x + int(76 * scale), y + int(18 * scale)), name, int(20 * scale), COLORS["text"], True)
        text(draw, (x + int(76 * scale), y + int(54 * scale)), f"{counts[i]}", int(24 * scale), color, True)
    return top + int(142 * scale)


def dialogue(img, top, scale):
    draw = ImageDraw.Draw(img, "RGBA")
    w, _ = img.size
    margin = int(w * 0.06)
    h = int(106 * scale)
    rounded(draw, (margin, top, w - margin, top + h), int(18 * scale), COLORS["panel"], (255, 24, 148, 90), 2)
    portrait = cover(asset("CharRunaHappy"), (int(72 * scale), int(72 * scale)))
    mask = Image.new("L", portrait.size, 0)
    ImageDraw.Draw(mask).ellipse((0, 0, *portrait.size), fill=255)
    img.paste(portrait, (margin + int(22 * scale), top + int(17 * scale)), mask)
    text(draw, (margin + int(112 * scale), top + int(20 * scale)), "ルナ", int(22 * scale), COLORS["neon"], True)
    text(draw, (margin + int(112 * scale), top + int(56 * scale)), "そこ、もらうね", int(26 * scale), COLORS["text"], True)
    return top + h + int(18 * scale)


def result_overlay(img, scale):
    draw = ImageDraw.Draw(img, "RGBA")
    w, h = img.size
    draw.rectangle((0, 0, w, h), fill=(0, 0, 0, 150))
    bw = int(min(w * 0.74, 720 * scale))
    bh = int(650 * scale)
    x = (w - bw) // 2
    y = (h - bh) // 2
    rounded(draw, (x, y, x + bw, y + bh), int(28 * scale), (22, 10, 32, 245), (255, 24, 148, 120), 3)
    text(draw, (w // 2, y + int(60 * scale)), "GAME OVER", int(28 * scale), COLORS["neon"], True, "ma")
    text(draw, (w // 2, y + int(128 * scale)), "ルナ", int(66 * scale), COLORS["neon"], True, "ma")
    text(draw, (w // 2, y + int(208 * scale)), "あなたの勝ち！", int(36 * scale), COLORS["text"], True, "ma")
    rankings = [("ルナ", 34, COLORS["neon"]), ("ユメ", 27, COLORS["yellow"]), ("アイリ", 22, COLORS["green"]), ("ミユ", 17, COLORS["purple"])]
    for i, (name, count, color) in enumerate(rankings):
        yy = y + int((288 + i * 72) * scale)
        rounded(draw, (x + int(54 * scale), yy, x + bw - int(54 * scale), yy + int(54 * scale)), int(12 * scale), tuple(list(color) + [30]), None)
        text(draw, (x + int(92 * scale), yy + int(27 * scale)), f"{i + 1}.", int(26 * scale), COLORS["sub"], True, "mm")
        text(draw, (x + int(150 * scale), yy + int(27 * scale)), name, int(28 * scale), COLORS["text"], True, "lm")
        text(draw, (x + bw - int(92 * scale), yy + int(27 * scale)), f"{count}枚", int(28 * scale), color, True, "rm")
    rounded(draw, (x + int(54 * scale), y + bh - int(100 * scale), x + bw - int(54 * scale), y + bh - int(38 * scale)), int(14 * scale), COLORS["neon"], None)
    text(draw, (w // 2, y + bh - int(69 * scale)), "もう一回", int(30 * scale), (0, 0, 0), True, "mm")


def make_title(size, out):
    w, h = size
    scale = w / 1242
    img = background(size)
    draw = ImageDraw.Draw(img, "RGBA")
    title_block(draw, w, int(180 * scale))
    bottom = character_picker(img, int(620 * scale), scale)
    rounded(draw, (int(w * 0.16), bottom + int(70 * scale), int(w * 0.84), bottom + int(152 * scale)), int(18 * scale), COLORS["neon"], None)
    text(draw, (w // 2, bottom + int(111 * scale)), "対戦開始", int(40 * scale), (0, 0, 0), True, "mm")
    ad_bar(draw, w, h - 50)
    img.convert("RGB").save(out, quality=95)


def make_game(size, out, mode=0):
    w, h = size
    scale = w / 1242
    img = background(size)
    draw = ImageDraw.Draw(img, "RGBA")
    ad_bar(draw, w, 0)
    y = int(90 * scale)
    y = scorebar(img, y, scale)
    if mode:
        y = dialogue(img, y, scale)
    y = draw_board(img, y + int(8 * scale), scale, mode)
    rounded(draw, (int(w * 0.29), y + int(30 * scale), int(w * 0.71), y + int(90 * scale)), int(30 * scale), COLORS["panel"], None)
    text(draw, (w // 2, y + int(60 * scale)), "あなたのターン", int(26 * scale), COLORS["cyan"], True, "mm")
    ad_bar(draw, w, h - 50)
    img.convert("RGB").save(out, quality=95)


def make_result(size, out):
    w, h = size
    scale = w / 1242
    img = background(size)
    draw = ImageDraw.Draw(img, "RGBA")
    ad_bar(draw, w, 0)
    y = int(92 * scale)
    y = scorebar(img, y, scale)
    y = draw_board(img, y + int(18 * scale), scale, 2)
    result_overlay(img, scale)
    ad_bar(draw, w, h - 50)
    img.convert("RGB").save(out, quality=95)


def main():
    OUT.mkdir(exist_ok=True)
    specs = [
        ("iphone", (1242, 2688)),
        ("ipad", (2048, 2732)),
    ]
    for prefix, size in specs:
        make_title(size, OUT / f"kabukicho-reversi-{prefix}-01.png")
        make_game(size, OUT / f"kabukicho-reversi-{prefix}-02.png", 0)
        make_game(size, OUT / f"kabukicho-reversi-{prefix}-03.png", 1)
        make_result(size, OUT / f"kabukicho-reversi-{prefix}-04.png")


if __name__ == "__main__":
    main()

"""Draw the 12 App Store screenshots at 1290x2796.

Headlines are set in Segoe UI, not generated as pixels, so the store copy
stays exact. Run from anywhere:

    python tool/generate_store_screenshots.py
"""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "store_screenshots"
W, H = 1290, 2796

FONT_BOLD = Path(r"C:\Windows\Fonts\segoeuib.ttf")
FONT_REGULAR = Path(r"C:\Windows\Fonts\segoeui.ttf")
FONT_FALLBACK_BOLD = Path(r"C:\Windows\Fonts\arialbd.ttf")
FONT_FALLBACK_REGULAR = Path(r"C:\Windows\Fonts\arial.ttf")


@dataclass(frozen=True)
class Palette:
    top: tuple[int, int, int]
    bottom: tuple[int, int, int]
    primary: tuple[int, int, int]
    card: tuple[int, int, int]
    ink: tuple[int, int, int]
    muted: tuple[int, int, int]
    glow: tuple[int, int, int]


ANCIENT = Palette(
    (26, 5, 5),
    (58, 14, 14),
    (224, 169, 59),
    (58, 22, 22),
    (255, 248, 236),
    (196, 164, 122),
    (180, 90, 30),
)
ZENITH = Palette(
    (15, 23, 42),
    (8, 70, 64),
    (16, 185, 129),
    (30, 41, 59),
    (248, 250, 252),
    (148, 180, 176),
    (16, 185, 129),
)
APEX = Palette(
    (10, 17, 40),
    (16, 32, 64),
    (255, 159, 28),
    (28, 37, 65),
    (248, 250, 252),
    (160, 176, 204),
    (255, 159, 28),
)


def font(path: Path, fallback: Path, size: int) -> ImageFont.FreeTypeFont:
    chosen = path if path.exists() else fallback
    return ImageFont.truetype(str(chosen), size)


def bold(size: int) -> ImageFont.FreeTypeFont:
    return font(FONT_BOLD, FONT_FALLBACK_BOLD, size)


def regular(size: int) -> ImageFont.FreeTypeFont:
    return font(FONT_REGULAR, FONT_FALLBACK_REGULAR, size)


def vertical_gradient(size: tuple[int, int], top: tuple[int, int, int], bottom: tuple[int, int, int]) -> Image.Image:
    width, height = size
    column = Image.new("RGB", (1, height))
    pixels = column.load()
    for y in range(height):
        blend = y / (height - 1)
        pixels[0, y] = tuple(int(start + (end - start) * blend) for start, end in zip(top, bottom))
    return column.resize((width, height), Image.Resampling.BILINEAR).convert("RGBA")


def add_glow(canvas: Image.Image, center: tuple[int, int], radius: int, color: tuple[int, int, int], alpha: int) -> None:
    layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    cx, cy = center
    draw.ellipse((cx - radius, cy - radius, cx + radius, cy + radius), fill=(*color, alpha))
    layer = layer.filter(ImageFilter.GaussianBlur(radius // 2))
    canvas.alpha_composite(layer)


def text_size(draw: ImageDraw.ImageDraw, text: str, face: ImageFont.FreeTypeFont) -> tuple[int, int]:
    box = face.getbbox(text)
    return box[2] - box[0], box[3] - box[1]


def wrap(draw: ImageDraw.ImageDraw, text: str, face: ImageFont.FreeTypeFont, max_width: int) -> list[str]:
    words = text.split()
    lines: list[str] = []
    current = ""
    for word in words:
        trial = word if not current else f"{current} {word}"
        if draw.textlength(trial, font=face) <= max_width:
            current = trial
        else:
            if current:
                lines.append(current)
            current = word
    if current:
        lines.append(current)
    return lines


class Screen:
    def __init__(self, image: Image.Image, origin: tuple[int, int], size: tuple[int, int], palette: Palette) -> None:
        self.image = image
        self.draw = ImageDraw.Draw(image)
        self.ox, self.oy = origin
        self.w, self.h = size
        self.palette = palette
        self.pad = 44

    def at(self, x: int, y: int) -> tuple[int, int]:
        return self.ox + x, self.oy + y

    def rect(self, x: int, y: int, w: int, h: int) -> tuple[int, int, int, int]:
        x0, y0 = self.at(x, y)
        return x0, y0, x0 + w, y0 + h

    def round(self, x: int, y: int, w: int, h: int, radius: int, fill: tuple[int, int, int]) -> None:
        self.draw.rounded_rectangle(self.rect(x, y, w, h), radius=radius, fill=fill)

    def label(self, x: int, y: int, text: str, face: ImageFont.FreeTypeFont, fill: tuple[int, int, int]) -> None:
        self.draw.text(self.at(x, y), text, font=face, fill=fill)

    def centered(self, x: int, y: int, w: int, text: str, face: ImageFont.FreeTypeFont, fill: tuple[int, int, int]) -> None:
        width = self.draw.textlength(text, font=face)
        self.draw.text((self.ox + x + (w - width) / 2, self.oy + y), text, font=face, fill=fill)

    def status_bar(self) -> None:
        self.label(self.pad, 28, "9:41", bold(32), self.palette.ink)
        self.centered(self.w - 150, 34, 90, "5G", regular(24), self.palette.ink)

    def tabs(self, names: list[str], selected: int) -> None:
        bar_y = self.h - 168
        self.round(28, bar_y, self.w - 56, 112, 36, self.palette.card)
        slot = (self.w - 56) // len(names)
        for index, name in enumerate(names):
            color = self.palette.primary if index == selected else self.palette.muted
            self.centered(28 + index * slot, bar_y + 36, slot, name, bold(26), color)

    def chips(self, y: int, names: list[str], selected: int) -> None:
        x = self.pad
        face = bold(26)
        for index, name in enumerate(names):
            width = int(self.draw.textlength(name, font=face)) + 40
            fill = self.palette.primary if index == selected else self.palette.card
            ink = (20, 12, 8) if index == selected else self.palette.ink
            self.round(x, y, width, 64, 32, fill)
            self.centered(x, y + 16, width, name, face, ink)
            x += width + 14

    def ring(self, cx: int, cy: int, radius: int, progress: float, caption: str, value: str) -> None:
        box = self.rect(cx - radius, cy - radius, radius * 2, radius * 2)
        self.draw.arc(box, 0, 360, fill=self.palette.card, width=16)
        self.draw.arc(box, -90, -90 + int(360 * progress), fill=self.palette.primary, width=16)
        self.centered(cx - radius, cy - 28, radius * 2, value, bold(32), self.palette.ink)
        self.centered(cx - radius, cy + radius + 16, radius * 2, caption, regular(24), self.palette.muted)

    def slider(self, x: int, y: int, w: int, value: float) -> None:
        track = tuple(min(255, channel + 36) for channel in self.palette.card)
        self.round(x, y, w, 12, 6, track)
        self.round(x, y, max(16, int(w * value)), 12, 6, self.palette.primary)
        thumb = x + int(w * value)
        self.draw.ellipse(self.rect(thumb - 18, y - 12, 36, 36), fill=self.palette.ink)


def paint_headline(canvas: Image.Image, kicker: str, title: str, primary: tuple[int, int, int]) -> None:
    draw = ImageDraw.Draw(canvas)
    kicker_font = bold(28)
    spaced = " ".join(kicker)
    kicker_width = draw.textlength(spaced, font=kicker_font)
    draw.text(((W - kicker_width) / 2, 132), spaced, font=kicker_font, fill=primary)

    title_font = bold(84)
    lines = wrap(draw, title, title_font, 1120)
    if len(lines) > 2:
        title_font = bold(72)
        lines = wrap(draw, title, title_font, 1120)
    line_gap = 98 if title_font.size >= 80 else 84
    top = 196
    for index, line in enumerate(lines):
        width = draw.textlength(line, font=title_font)
        draw.text(((W - width) / 2, top + index * line_gap), line, font=title_font, fill=(255, 255, 255))


def paint_phone(canvas: Image.Image, palette: Palette, painter) -> None:
    x, y, phone_w, phone_h = 145, 470, 1000, 2060
    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle(
        (x + 8, y + 24, x + phone_w - 8, y + phone_h + 18),
        radius=86,
        fill=(0, 0, 0, 150),
    )
    canvas.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(28)))

    draw = ImageDraw.Draw(canvas)
    draw.rounded_rectangle((x, y, x + phone_w, y + phone_h), radius=84, fill=(236, 236, 240))
    inset = 14
    draw.rounded_rectangle(
        (x + inset, y + inset, x + phone_w - inset, y + phone_h - inset),
        radius=72,
        fill=palette.top,
    )
    screen = Screen(
        canvas,
        (x + inset + 10, y + inset + 10),
        (phone_w - (inset + 10) * 2, phone_h - (inset + 10) * 2),
        palette,
    )
    painter(screen)
    # Home indicator sits above the bezel curve.
    indicator_w = 180
    ix = screen.ox + (screen.w - indicator_w) // 2
    iy = screen.oy + screen.h - 22
    ImageDraw.Draw(canvas).rounded_rectangle((ix, iy, ix + indicator_w, iy + 8), radius=4, fill=(255, 255, 255))


def ancient_explore(screen: Screen) -> None:
    screen.status_bar()
    screen.label(screen.pad, 96, "Lessons", bold(48), screen.palette.ink)
    screen.chips(168, ["All", "Myths", "Writing", "Ritual"], 1)
    screen.round(screen.pad, 264, screen.w - 88, 300, 32, screen.palette.card)
    screen.label(72, 292, "MYTHS", bold(22), screen.palette.primary)
    screen.label(72, 332, "Scarab and the sun", bold(40), screen.palette.ink)
    screen.label(72, 392, "The beetle rolls the sun across the sky.", regular(26), screen.palette.muted)
    screen.round(72, 470, 180, 58, 29, screen.palette.primary)
    screen.centered(72, 484, 180, "Read", bold(26), (26, 12, 4))
    lessons = [
        ("House sign", "Writing", "A mark that names the house"),
        ("Barque of Ra", "Myths", "The day boat crosses the sky"),
        ("Incense at the threshold", "Ritual", "Smoke opens the doorway"),
    ]
    y = 592
    for title, category, detail in lessons:
        screen.round(screen.pad, y, screen.w - 88, 150, 28, screen.palette.card)
        screen.label(72, y + 28, category.upper(), bold(20), screen.palette.primary)
        screen.label(72, y + 60, title, bold(32), screen.palette.ink)
        screen.label(72, y + 104, detail, regular(24), screen.palette.muted)
        y += 170
    screen.tabs(["Lessons", "Trials", "Workshop", "Progress"], 0)


def ancient_quiz(screen: Screen) -> None:
    screen.status_bar()
    screen.label(screen.pad, 96, "Daily challenge", bold(46), screen.palette.ink)
    screen.label(screen.pad, 160, "High Priest  ·  3 questions", regular(26), screen.palette.muted)
    screen.round(screen.pad, 230, screen.w - 88, 220, 32, screen.palette.card)
    screen.label(72, 262, "Which sign means life?", bold(36), screen.palette.ink)
    screen.label(72, 330, "Choose the reading used in the temple.", regular(26), screen.palette.muted)
    options = [("Ankh", True), ("Owl", False), ("Bread", False)]
    y = 490
    for name, chosen in options:
        fill = screen.palette.primary if chosen else screen.palette.card
        ink = (26, 12, 4) if chosen else screen.palette.ink
        screen.round(screen.pad, y, screen.w - 88, 110, 28, fill)
        screen.label(80, y + 34, name, bold(34), ink)
        y += 132
    screen.round(screen.pad, y + 20, screen.w - 88, 150, 28, screen.palette.card)
    screen.label(72, y + 48, "Score", regular(24), screen.palette.muted)
    screen.label(72, y + 82, "Score: 90", bold(40), screen.palette.primary)
    screen.round(screen.pad, y + 200, screen.w - 88, 100, 28, screen.palette.primary)
    screen.centered(screen.pad, y + 230, screen.w - 88, "Next question", bold(30), (26, 12, 4))
    screen.tabs(["Lessons", "Trials", "Workshop", "Progress"], 1)


def ancient_glyphs(screen: Screen) -> None:
    screen.status_bar()
    screen.label(screen.pad, 96, "Workshop", bold(48), screen.palette.ink)
    screen.label(screen.pad, 158, "Glyphs and their meanings", regular(26), screen.palette.muted)
    glyphs = [
        ("Eye", "Protection and wholeness"),
        ("Scarab", "Rebirth of the sun"),
        ("Ankh", "Life"),
        ("Djed", "Support of the spine"),
        ("Ra", "Daytime sun"),
        ("Lion", "Strength of the pharaoh"),
    ]
    gap = 20
    card_w = (screen.w - screen.pad * 2 - gap) // 2
    for index, (name, meaning) in enumerate(glyphs):
        column = index % 2
        row = index // 2
        x = screen.pad + column * (card_w + gap)
        y = 230 + row * 250
        screen.round(x, y, card_w, 230, 28, screen.palette.card)
        mark = x + 28
        screen.draw.ellipse(screen.rect(mark, y + 28, 72, 72), outline=screen.palette.primary, width=4)
        screen.draw.ellipse(screen.rect(mark + 22, y + 50, 28, 28), fill=screen.palette.primary)
        screen.label(x + 28, y + 120, name, bold(32), screen.palette.ink)
        screen.label(x + 28, y + 164, meaning, regular(22), screen.palette.muted)
    screen.round(screen.pad, 1000, screen.w - 88, 150, 28, screen.palette.card)
    screen.label(76, 1032, "Reading", regular(22), screen.palette.primary)
    screen.label(76, 1074, "Eye is read as irt", bold(32), screen.palette.ink)
    screen.tabs(["Lessons", "Trials", "Workshop", "Progress"], 2)


def ancient_progress(screen: Screen) -> None:
    screen.status_bar()
    screen.label(screen.pad, 96, "Progress", bold(48), screen.palette.ink)
    screen.ring(screen.w // 2, 390, 130, 0.25, "Lesson read", "25%")
    stats = [("Lessons: 1", "Opened in the codex"), ("Score: 90", "High Priest quiz"), ("Sign keeper", "Badge unlocked")]
    y = 620
    for title, detail in stats:
        screen.round(screen.pad, y, screen.w - 88, 140, 28, screen.palette.card)
        screen.label(76, y + 32, title, bold(34), screen.palette.ink)
        screen.label(76, y + 82, detail, regular(24), screen.palette.muted)
        y += 160
    screen.round(screen.pad, y, screen.w - 88, 120, 28, screen.palette.card)
    screen.label(76, y + 38, "3 quizzes this week", bold(30), screen.palette.ink)
    screen.tabs(["Lessons", "Trials", "Workshop", "Progress"], 3)


def zenith_habits(screen: Screen) -> None:
    screen.status_bar()
    screen.label(screen.pad, 96, "Today", bold(48), screen.palette.ink)
    screen.label(screen.pad, 156, "Thursday, October 8", regular(26), screen.palette.muted)
    centers = [screen.w // 2 - 250, screen.w // 2, screen.w // 2 + 250]
    values = [("7,420", "Step", 0.74), ("95m", "Focus", 0.62), ("5/8", "Water", 0.62)]
    for cx, (value, caption, progress) in zip(centers, values):
        screen.ring(cx, 360, 92, progress, caption, value)
    habits = [("Morning page", True), ("Glass before noon", True), ("Short walk", False), ("Evening review", False)]
    y = 560
    for title, done in habits:
        screen.round(screen.pad, y, screen.w - 88, 120, 28, screen.palette.card)
        screen.draw.ellipse(screen.rect(76, y + 36, 48, 48), outline=screen.palette.primary, width=4)
        if done:
            screen.draw.line(screen.rect(88, y + 58, 12, 14)[:2] + screen.at(100, y + 72), fill=screen.palette.primary, width=4)
            screen.draw.line((*screen.at(100, y + 72), *screen.at(112, y + 50)), fill=screen.palette.primary, width=4)
        screen.label(148, y + 40, title, bold(32), screen.palette.ink)
        y += 140
    screen.tabs(["Day", "Timer", "Analytics"], 0)


def zenith_growth(screen: Screen) -> None:
    screen.status_bar()
    screen.label(screen.pad, 96, "Analytics", bold(48), screen.palette.ink)
    screen.round(screen.pad, 180, screen.w - 88, 420, 32, screen.palette.card)
    screen.label(72, 208, "Week", bold(32), screen.palette.ink)
    heights = [120, 180, 150, 240, 200, 280, 220]
    labels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    base = 520
    bar_w = 48
    gap = 28
    start = 90
    for index, (height, day) in enumerate(zip(heights, labels)):
        x = start + index * (bar_w + gap)
        screen.round(x, base - height, bar_w, height, 16, screen.palette.primary)
        screen.centered(x - 8, base + 16, bar_w + 16, day, regular(20), screen.palette.muted)
    screen.round(screen.pad, 640, screen.w - 88, 180, 32, screen.palette.card)
    screen.label(76, 678, "Streak", regular(24), screen.palette.muted)
    screen.label(76, 720, "5 days", bold(48), screen.palette.primary)
    screen.round(screen.pad, 850, screen.w - 88, 180, 32, screen.palette.card)
    screen.label(76, 888, "Trend", regular(24), screen.palette.muted)
    screen.label(76, 932, "Focus time is climbing", bold(34), screen.palette.ink)
    screen.tabs(["Day", "Timer", "Analytics"], 2)


def zenith_routine(screen: Screen) -> None:
    screen.status_bar()
    screen.label(screen.pad, 96, "Routine", bold(48), screen.palette.ink)
    screen.label(screen.pad, 158, "Goals and units", regular(26), screen.palette.muted)
    rows = [("Step goal", "10,000", 0.74), ("Focus", "95 min", 0.6), ("Water", "8 glasses", 0.62)]
    y = 240
    for title, value, position in rows:
        screen.round(screen.pad, y, screen.w - 88, 190, 28, screen.palette.card)
        screen.label(76, y + 28, title, bold(32), screen.palette.ink)
        screen.label(screen.w - 280, y + 28, value, bold(28), screen.palette.primary)
        screen.slider(76, y + 110, screen.w - 180, position)
        y += 214
    screen.round(screen.pad, y, screen.w - 88, 120, 28, screen.palette.card)
    screen.label(76, y + 40, "Distance in kilometers", bold(30), screen.palette.ink)
    screen.round(screen.pad, y + 146, screen.w - 88, 140, 28, screen.palette.card)
    screen.label(76, y + 180, "Quiet hours", bold(30), screen.palette.ink)
    screen.label(76, y + 226, "10:00 PM to 7:00 AM", regular(26), screen.palette.muted)
    screen.tabs(["Day", "Timer", "Analytics"], 0)


def zenith_accountable(screen: Screen) -> None:
    screen.status_bar()
    screen.label(screen.pad, 96, "Reminders", bold(48), screen.palette.ink)
    screen.label(screen.pad, 158, "A nudge, not a lecture", regular(26), screen.palette.muted)
    screen.round(screen.pad, 240, screen.w - 88, 150, 28, screen.palette.card)
    screen.label(76, 280, "Daily reminder", bold(34), screen.palette.ink)
    screen.label(76, 328, "8:00 in the morning", regular(26), screen.palette.muted)
    screen.round(screen.w - 180, 292, 92, 52, 26, screen.palette.primary)
    screen.round(screen.w - 140, 298, 40, 40, 20, screen.palette.ink)
    screen.round(screen.pad, 420, screen.w - 88, 150, 28, screen.palette.card)
    screen.label(76, 460, "Notifications", bold(34), screen.palette.ink)
    screen.label(76, 508, "Habit list and focus timer", regular(26), screen.palette.muted)
    screen.round(screen.pad, 610, screen.w - 88, 220, 32, screen.palette.card)
    screen.label(76, 648, "Still open today", bold(32), screen.palette.ink)
    screen.label(76, 708, "Short walk", regular(28), screen.palette.muted)
    screen.label(76, 752, "Evening review", regular(28), screen.palette.muted)
    screen.round(screen.pad, 860, screen.w - 88, 140, 28, screen.palette.card)
    screen.label(76, 896, "Quiet hours", bold(30), screen.palette.ink)
    screen.label(76, 942, "10:00 PM to 7:00 AM", regular(26), screen.palette.muted)
    screen.tabs(["Day", "Timer", "Analytics"], 0)


def apex_finance(screen: Screen) -> None:
    screen.status_bar()
    screen.label(screen.pad, 96, "Calc", bold(48), screen.palette.ink)
    screen.chips(170, ["Mortgage", "Deposit 12%", "Car savings"], 0)
    fields = [("Amount", "14,049"), ("Rate", "20%"), ("Term", "12 years")]
    y = 270
    for name, value in fields:
        screen.round(screen.pad, y, screen.w - 88, 110, 24, screen.palette.card)
        screen.label(76, y + 22, name, regular(22), screen.palette.muted)
        screen.label(76, y + 54, value, bold(34), screen.palette.ink)
        y += 126
    screen.round(screen.pad, y + 10, screen.w - 88, 200, 28, screen.palette.card)
    screen.label(76, y + 36, "Balance", regular(24), screen.palette.muted)
    screen.label(76, y + 78, "17,280", bold(64), screen.palette.primary)
    screen.label(76, y + 156, "After inflation", regular(24), screen.palette.muted)
    screen.tabs(["Calc", "Converter", "History"], 0)


def apex_currency(screen: Screen) -> None:
    screen.status_bar()
    screen.label(screen.pad, 96, "Converter", bold(48), screen.palette.ink)
    screen.round(screen.pad, 190, 360, 120, 28, screen.palette.card)
    screen.round(screen.w - 404, 190, 360, 120, 28, screen.palette.primary)
    screen.centered(screen.pad, 228, 360, "USD", bold(36), screen.palette.ink)
    screen.centered(screen.w - 404, 228, 360, "EUR", bold(36), (20, 12, 4))
    screen.round(screen.pad, 350, screen.w - 88, 280, 32, screen.palette.card)
    screen.label(76, 386, "100.00", bold(72), screen.palette.ink)
    screen.label(76, 480, "1 USD = 0.92 EUR", regular(28), screen.palette.muted)
    screen.round(screen.pad, 670, screen.w - 88, 220, 32, screen.palette.card)
    screen.label(76, 706, "Converted", regular(24), screen.palette.muted)
    screen.label(76, 754, "92.00", bold(68), screen.palette.primary)
    screen.round(screen.pad, 920, screen.w - 88, 130, 28, screen.palette.card)
    screen.label(76, 956, "Ledger currency: EUR", bold(30), screen.palette.ink)
    screen.tabs(["Calc", "Converter", "History"], 1)


def apex_history(screen: Screen) -> None:
    screen.status_bar()
    screen.label(screen.pad, 96, "History", bold(48), screen.palette.ink)
    notes = [
        ("Mortgage", "Mortgage, 12%"),
        ("Deposit", "Deposit 12%"),
        ("Car savings", "Saved from the calc tab"),
    ]
    y = 190
    for title, detail in notes:
        screen.round(screen.pad, y, screen.w - 88, 150, 28, screen.palette.card)
        screen.label(76, y + 32, title, bold(34), screen.palette.ink)
        screen.label(76, y + 84, detail, regular(26), screen.palette.muted)
        y += 172
    screen.round(screen.pad, y + 10, screen.w - 88, 110, 28, screen.palette.primary)
    screen.centered(screen.pad, y + 40, screen.w - 88, "Export PDF", bold(32), (20, 12, 4))
    screen.tabs(["Calc", "Converter", "History"], 2)


def apex_units(screen: Screen) -> None:
    screen.status_bar()
    screen.label(screen.pad, 96, "Units", bold(48), screen.palette.ink)
    screen.chips(170, ["Length", "Mass", "Money"], 0)
    screen.round(screen.pad, 280, screen.w - 88, 180, 28, screen.palette.card)
    screen.label(76, 314, "Meters", regular(24), screen.palette.muted)
    screen.label(76, 358, "1,000", bold(56), screen.palette.ink)
    screen.round(screen.pad, 490, screen.w - 88, 180, 28, screen.palette.card)
    screen.label(76, 524, "Kilometers", regular(24), screen.palette.muted)
    screen.label(76, 568, "1.0", bold(56), screen.palette.primary)
    screen.round(screen.pad, 710, screen.w - 88, 160, 28, screen.palette.card)
    screen.label(76, 754, "Lengths in meters", bold(32), screen.palette.ink)
    screen.label(76, 806, "Switch the pair from settings", regular(24), screen.palette.muted)
    screen.round(screen.pad, 900, screen.w - 88, 150, 28, screen.palette.card)
    screen.label(76, 936, "Feet", regular(24), screen.palette.muted)
    screen.label(76, 976, "3,281", bold(40), screen.palette.ink)
    screen.tabs(["Calc", "Converter", "History"], 1)


SHOTS = [
    ("ancient_codex", ANCIENT, "ANCIENT CODEX", [
        ("01_explore_ancient_history.png", "Explore Ancient History & Myths", ancient_explore),
        ("02_test_your_knowledge.png", "Test Your Knowledge Daily", ancient_quiz),
        ("03_discover_glyphs.png", "Discover Rare Artifacts & Glyphs", ancient_glyphs),
        ("04_track_learning_progress.png", "Track Your Learning Progress", ancient_progress),
    ]),
    ("zenith_habits", ZENITH, "ZENITH HABITS", [
        ("01_build_daily_habits.png", "Build Unstoppable Daily Habits", zenith_habits),
        ("02_visualize_growth.png", "Visualize Your Personal Growth", zenith_growth),
        ("03_customize_routine.png", "Customize Your Ideal Routine", zenith_routine),
        ("04_stay_accountable.png", "Stay Accountable Every Day", zenith_accountable),
    ]),
    ("apex_calc", APEX, "APEX CALC", [
        ("01_financial_calculations.png", "Advanced Financial Calculations", apex_finance),
        ("02_currency_conversion.png", "Instant Currency Conversion", apex_currency),
        ("03_reports_and_history.png", "Export Reports & Save History", apex_history),
        ("04_math_and_units.png", "Smart Math & Unit Tools", apex_units),
    ]),
]


def render(folder: str, palette: Palette, kicker: str, filename: str, title: str, painter) -> None:
    canvas = vertical_gradient((W, H), palette.top, palette.bottom)
    add_glow(canvas, (W // 2, 1500), 720, palette.glow, 90)
    paint_headline(canvas, kicker, title, palette.primary)
    paint_phone(canvas, palette, painter)
    destination = OUT / folder
    destination.mkdir(parents=True, exist_ok=True)
    path = destination / filename
    canvas.convert("RGB").save(path, "PNG", optimize=True)
    print(f"wrote {path.relative_to(ROOT)}")


def main() -> None:
    for folder, palette, kicker, shots in SHOTS:
        for filename, title, painter in shots:
            render(folder, palette, kicker, filename, title, painter)


if __name__ == "__main__":
    main()

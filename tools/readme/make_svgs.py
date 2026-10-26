#!/usr/bin/env python3
"""Draws the README hero and workflow SVGs in light and dark variants.

Usage: python3 -I tools/readme/make_svgs.py  (writes assets/readme/*.svg)

Colours repeat the «Чертёж» tokens of common_ui (UiColors) and the phase stripe colours of the
switchboard view; the board, stamp and numbers are the demo project «3-комнатная квартира».
"""

from __future__ import annotations

from pathlib import Path

OUT = Path(__file__).resolve().parents[2] / "assets" / "readme"

SANS = "'IBM Plex Sans', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif"
MONO = "'IBM Plex Mono', ui-monospace, SFMono-Regular, Menlo, Consolas, monospace"

THEMES = {
    "light": {
        "canvas": "#F4F4F4",
        "surface": "#FFFFFF",
        "sunken": "#EBEBEB",
        "border": "#D9D9D9",
        "strong": "#808080",
        "text": "#0A0A0A",
        "muted": "#525252",
        "accent": "#D9480F",
        "accentText": "#B03A0B",
        "success": "#1B6E34",
        "intake": "#0A0A0A",
        "onIntake": "#FFFFFF",
        "knob": "#3A3A3A",
    },
    "dark": {
        "canvas": "#0A0A0A",
        "surface": "#141414",
        "sunken": "#1F1F1F",
        "border": "#2A2A2A",
        "strong": "#737373",
        "text": "#F5F5F5",
        "muted": "#A3A3A3",
        "accent": "#FF7B36",
        "accentText": "#FF9157",
        "success": "#5BC984",
        "intake": "#F5F5F5",
        "onIntake": "#0A0A0A",
        "knob": "#BDBDBD",
    },
}

PHASE = {"L1": "#795548", "L2": "#212121", "L3": "#9E9E9E"}


def esc(text: str) -> str:
    return text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def module(x: float, y: float, w: float, head: str, label: str, strip: str, on_strip: str, c: dict) -> str:
    """One DIN module as the app draws it: a stripe with number and phase, rating, toggle."""
    h = 132
    return f"""
    <g transform="translate({x} {y})">
      <rect width="{w}" height="{h}" rx="2" fill="{c['surface']}" stroke="{c['strong']}"/>
      <rect width="{w}" height="26" rx="2" fill="{strip}"/>
      <text x="{w / 2}" y="18.5" text-anchor="middle" font-family="{MONO}" font-size="15" font-weight="600" fill="{on_strip}">{esc(head)}</text>
      <text x="{w / 2}" y="60" text-anchor="middle" font-family="{MONO}" font-size="{20 if w > 40 else 15}" font-weight="600" fill="{c['text']}">{esc(label)}</text>
      <rect x="{w / 2 - 6}" y="76" width="12" height="28" rx="1.5" fill="{c['knob']}"/>
    </g>"""


def hero(c: dict) -> str:
    unit = 32  # one DIN module (18 mm) in SVG units
    gap = 4
    rail_x, rail_y = 664, 112
    mods = [
        (2, "Ввод", "C63", c["intake"], c["onIntake"]),
        (2, "1 · L1", "C10", PHASE["L1"], "#FFFFFF"),
        (2, "2 · L1", "C16", PHASE["L1"], "#FFFFFF"),
        (2, "3 · L2", "C16", PHASE["L2"], "#FFFFFF"),
        (2, "4 · L3", "C16", PHASE["L3"], "#000000"),
        (1, "5", "B40", PHASE["L1"], "#FFFFFF"),
    ]
    parts = []
    x = rail_x
    for n, head, label, strip, on_strip in mods:
        w = n * unit + (n - 1) * gap
        parts.append(module(x, rail_y, w, head, label, strip, on_strip, c))
        x += w + gap
    used_end = x - gap
    rail_end = rail_x + 13 * (unit + gap) - gap
    # Free places on the rail: hairline outlines like the app's reserve slots.
    free = []
    fx = x
    while fx + unit <= rail_end + 0.5:
        free.append(
            f'<rect x="{fx}" y="{rail_y + 22}" width="{unit}" height="88" fill="none" stroke="{c["border"]}"/>'
        )
        fx += unit + gap
    dim_y = rail_y + 132 + 34
    return f"""<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="420" viewBox="0 0 1200 420" role="img" aria-labelledby="title desc">
  <title id="title">Щитовик – расчёт электрощита</title>
  <desc id="desc">Название проекта и описание слева; справа чертёж DIN-рейки с вводным автоматом и автоматами линий, размерная линия и штамп с итогами демо-проекта.</desc>

  <rect width="1200" height="420" rx="12" fill="{c['canvas']}"/>
  <rect x="24.5" y="24.5" width="1151" height="371" rx="4" fill="none" stroke="{c['strong']}"/>

  <g id="title-block" transform="translate(72 0)">
    <rect x="0" y="78" width="10" height="10" fill="{c['accent']}"/>
    <text x="20" y="88" font-family="{MONO}" font-size="18" letter-spacing="1.5" fill="{c['muted']}">РАСЧЁТ ЭЛЕКТРОЩИТА</text>
    <text x="-4" y="176" font-family="{SANS}" font-size="88" font-weight="600" letter-spacing="-1.5" fill="{c['text']}">Щитовик</text>
    <text x="0" y="226" font-family="{SANS}" font-size="24" fill="{c['text']}">Помещения и приборы →</text>
    <text x="0" y="258" font-family="{SANS}" font-size="24" fill="{c['text']}">линии, автоматы, УЗО, кабель,</text>
    <text x="0" y="290" font-family="{SANS}" font-size="24" fill="{c['text']}">щит на DIN-рейках, смета и PDF</text>
    <text x="0" y="352" font-family="{MONO}" font-size="16" letter-spacing="1" fill="{c['muted']}">ANDROID · iOS · WEB · ОФЛАЙН</text>
  </g>

  <g id="board">
    <text x="{rail_x}" y="{rail_y - 24}" font-family="{MONO}" font-size="16" letter-spacing="1" fill="{c['muted']}">РЕЙКА 1</text>
    <rect x="{rail_x - 16}" y="{rail_y + 52}" width="{rail_end - rail_x + 32}" height="28" fill="{c['sunken']}" stroke="{c['border']}"/>
    {''.join(free)}
    {''.join(parts)}
    <g id="dimension" stroke="{c['strong']}" fill="none">
      <path d="M{rail_x} {rail_y + 140} V{dim_y + 8} M{used_end} {rail_y + 140} V{dim_y + 8}"/>
      <path d="M{rail_x} {dim_y} H{used_end}"/>
      <path d="M{rail_x + 10} {dim_y - 4} L{rail_x} {dim_y} L{rail_x + 10} {dim_y + 4} M{used_end - 10} {dim_y - 4} L{used_end} {dim_y} L{used_end - 10} {dim_y + 4}"/>
    </g>
    <rect x="{(rail_x + used_end) / 2 - 58}" y="{dim_y - 13}" width="116" height="26" fill="{c['canvas']}"/>
    <text x="{(rail_x + used_end) / 2}" y="{dim_y + 6}" text-anchor="middle" font-family="{MONO}" font-size="17" fill="{c['muted']}">11 мод.</text>
  </g>

  <g id="stamp" transform="translate(663.5 299.5)" font-family="{MONO}">
    <rect width="512" height="96" fill="{c['surface']}" stroke="{c['strong']}"/>
    <path d="M0 32 H512 M128 32 V96 M256 32 V96 M384 32 V96" stroke="{c['strong']}" fill="none"/>
    <text x="16" y="22" font-size="15" letter-spacing="1" fill="{c['muted']}">ДЕМО: 3-КОМНАТНАЯ КВАРТИРА</text>
    <text x="16" y="56" font-size="14" letter-spacing="1" fill="{c['muted']}">ЛИНИЙ</text>
    <text x="16" y="84" font-size="22" font-weight="600" fill="{c['text']}">18</text>
    <text x="144" y="56" font-size="14" letter-spacing="1" fill="{c['muted']}">ВВОД</text>
    <text x="144" y="84" font-size="22" font-weight="600" fill="{c['text']}">56,8 <tspan font-size="16" font-weight="400" fill="{c['muted']}">А</tspan></text>
    <text x="272" y="56" font-size="14" letter-spacing="1" fill="{c['muted']}">КОРПУС</text>
    <text x="272" y="84" font-size="22" font-weight="600" fill="{c['text']}">3×18</text>
    <text x="400" y="56" font-size="14" letter-spacing="1" fill="{c['muted']}">СМЕТА</text>
    <text x="400" y="84" font-size="22" font-weight="600" fill="{c['accentText']}">75 694 <tspan font-size="16" font-weight="400">₽</tspan></text>
  </g>
</svg>
"""


STEPS = [
    ("01", "Объект", ["ввод, фазы,", "мощность"]),
    ("02", "Помещения", ["комнаты", "и приборы"]),
    ("03", "Линии", ["автоматы,", "УЗО, кабель"]),
    ("04", "Щит", ["DIN-рейки", "и корпус"]),
    ("05", "Смета и PDF", ["модели", "и три цены"]),
]


def workflow(c: dict) -> str:
    x0, top, cell_w, gap, cell_h = 48, 72, 204, 20, 168
    cells = []
    for i, (num, title, lines) in enumerate(STEPS):
        x = x0 + i * (cell_w + gap)
        last = i == len(STEPS) - 1
        body = "".join(
            f'<text x="20" y="{108 + j * 28}" font-family="{SANS}" font-size="20" fill="{c["muted"]}">{esc(line)}</text>'
            for j, line in enumerate(lines)
        )
        cells.append(f"""
    <g transform="translate({x} {top})">
      <rect width="{cell_w}" height="{cell_h}" rx="4" fill="{c['surface']}" stroke="{c['accent'] if last else c['border']}" stroke-width="{2 if last else 1}"/>
      <text x="20" y="36" font-family="{MONO}" font-size="16" letter-spacing="1" fill="{c['accentText'] if last else c['muted']}">{num}</text>
      <text x="20" y="70" font-family="{SANS}" font-size="24" font-weight="600" fill="{c['text']}">{esc(title)}</text>
      {body}
    </g>""")
        if not last:
            ax = x + cell_w
            ay = top + cell_h / 2
            cells.append(
                f'<path d="M{ax + 3} {ay} H{ax + gap - 3} M{ax + gap - 9} {ay - 5} L{ax + gap - 3} {ay} L{ax + gap - 9} {ay + 5}" stroke="{c["strong"]}" fill="none" stroke-width="1.5"/>'
            )
    return f"""<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="280" viewBox="0 0 1200 280" role="img" aria-labelledby="title desc">
  <title id="title">Как считает Щитовик</title>
  <desc id="desc">Пять шагов: объект, помещения, линии, щит, смета и PDF. Результаты каждого шага пересчитываются из ввода.</desc>

  <rect width="1200" height="280" rx="12" fill="{c['canvas']}"/>
  <text x="48" y="48" font-family="{MONO}" font-size="16" letter-spacing="1.5" fill="{c['muted']}">ВВОД ПОЛЬЗОВАТЕЛЯ → РАСЧЁТ ЯДРА → РЕЗУЛЬТАТ</text>
  {''.join(cells)}
</svg>
"""


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for name, colors in THEMES.items():
        (OUT / f"hero-{name}.svg").write_text(hero(colors), encoding="utf-8")
        (OUT / f"workflow-{name}.svg").write_text(workflow(colors), encoding="utf-8")


if __name__ == "__main__":
    main()

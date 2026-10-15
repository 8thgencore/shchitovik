"""Renders the source images of the app icon for `launcher_icons` (see README.md).

The mark is a switchboard enclosure with the Lucide `zap` (the brand icon of the app) inside,
white on the accent colour of the design system (UiColors.light.accent).

Usage: python3 -I tools/app_icon/render_icons.py <chrome binary>
Writes SVG and PNG sources to app/assets/icon/ and the link preview to app/web/opengraph.png
(launcher_icons links it by a relative URL, which crawlers ignore; index.html has absolute ones).
"""

import pathlib
import subprocess
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = ROOT / "app/assets/icon"
FONTS = ROOT / "common/common_ui/assets/fonts"

ACCENT = "#D9480F"
WHITE = "#FFFFFF"
CANVAS = "#F4F4F4"
INK = "#0A0A0A"

# Lucide `zap`, 24x24 grid, centred on (12, 12).
ZAP = (
    "M4 14a1 1 0 0 1-.78-1.63l9.9-10.2a.5.5 0 0 1 .86.46l-1.92 6.02A1 1 0 0 0 13 10h7"
    "a1 1 0 0 1 .78 1.63l-9.9 10.2a.5.5 0 0 1-.86-.46l1.92-6.02A1 1 0 0 0 11 14z"
)


def mark(scale: float, stroke: float, color: str = WHITE) -> str:
    """Enclosure and bolt on a 1024 grid centred on (512, 512); [scale] 1.0 spans ~47%."""
    w, h, r = 480, 560, 64
    return (
        f'<g transform="translate(512 512) scale({scale})">'
        f'<rect x="{-w / 2}" y="{-h / 2}" width="{w}" height="{h}" rx="{r}" fill="none" '
        f'stroke="{color}" stroke-width="{stroke}"/>'
        f'<path d="{ZAP}" transform="scale(15.5) translate(-12 -12)" fill="{color}" '
        f'stroke="{color}" stroke-width="0.6" stroke-linejoin="round"/>'
        "</g>"
    )


def svg(body: str, background: str | None = None, radius: int = 0) -> str:
    bg = (
        f'<rect width="1024" height="1024" rx="{radius}" fill="{background}"/>' if background else ""
    )
    return (
        '<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" '
        f'viewBox="0 0 1024 1024">{bg}{body}</svg>\n'
    )


ICONS = {
    # Full-bleed, opaque: iOS (the system rounds it), maskable PWA, Android legacy.
    "icon": svg(mark(1.0, 56), ACCENT),
    # Rounded tile for the PWA and the SVG favicon.
    "icon-rounded": svg(mark(1.0, 56), ACCENT, radius=224),
    # Favicon: the mark grows and the strokes thicken so the bolt survives 16 px.
    "favicon": svg(mark(1.38, 72), ACCENT, radius=192),
    # Android adaptive layers: art inside the 66% safe circle, no inset needed.
    "foreground": svg(mark(0.9, 56)),
    "monochrome": svg(mark(0.9, 56)),
}

OPENGRAPH = f"""<!doctype html><meta charset="utf-8"><style>
@font-face {{ font-family: Plex; src: url("{(FONTS / 'IBMPlexSans-SemiBold.ttf').as_uri()}"); font-weight: 600; }}
@font-face {{ font-family: Plex; src: url("{(FONTS / 'IBMPlexSans-Regular.ttf').as_uri()}"); font-weight: 400; }}
html, body {{ margin: 0; width: 1200px; height: 630px; background: {CANVAS}; font-family: Plex; color: {INK}; }}
main {{ display: flex; align-items: center; gap: 64px; height: 100%; padding: 0 96px; box-sizing: border-box; }}
img {{ width: 280px; height: 280px; flex: none; }}
h1 {{ margin: 0; font-size: 104px; font-weight: 600; letter-spacing: -2px; }}
p {{ margin: 16px 0 0; font-size: 40px; line-height: 1.3; color: #525252; }}
</style><main><img src="icon-rounded.svg"><div><h1>Щитовик</h1>
<p>Расчёт электрощита и смета:<br>автоматы, УЗО, кабели</p></div></main>
"""


def render(chrome: str, html: pathlib.Path, png: pathlib.Path, size: tuple[int, int]) -> None:
    subprocess.run(
        [
            chrome, "--headless=new", "--no-sandbox", "--disable-gpu", "--hide-scrollbars",
            "--force-device-scale-factor=1", "--default-background-color=00000000",
            f"--window-size={size[0]},{size[1]}", f"--screenshot={png}", html.as_uri(),
        ],
        check=True,
        capture_output=True,
    )


def main() -> None:
    chrome = sys.argv[1]
    OUT.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        tmp_dir = pathlib.Path(tmp)
        for name, source in ICONS.items():
            (OUT / f"{name}.svg").write_text(source)
            page = tmp_dir / f"{name}.html"
            page.write_text(
                '<!doctype html><style>html,body{margin:0;background:transparent}'
                f'svg{{display:block}}</style>{source}'
            )
            render(chrome, page, OUT / f"{name}.png", (1024, 1024))
        page = OUT / "opengraph.html"
        page.write_text(OPENGRAPH)
        try:
            render(chrome, page, ROOT / "app/web/opengraph.png", (1200, 630))
        finally:
            page.unlink()


main()

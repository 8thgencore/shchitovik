# Design System Master File

> **LOGIC:** When building a specific page, first check `design-system/shchitovik/pages/[page-name].md`.
> If that file exists, its rules **override** this Master file. If not, follow the rules below.
>
> Implementation: `app/lib/src/widget/app_theme.dart` (`AppTheme.light` / `AppTheme.dark`) and
> `app/lib/src/widget/status_colors.dart`. Taste, a11y, bans and voice: `.ux-profile.md`.

---

**Project:** Щитовик (Shchitovik) — switchboard calculator and estimate, Flutter (Android, iOS, Web)
**Source:** `ui-ux-pro-max` `--design-system` (query «engineering calculator tool electrical estimate»,
variance 2, motion 2, density 7), adapted 2026-10-13. Rejected parts are listed at the end.

---

## Style

**Minimalism & Swiss Style** — clean, functional, high contrast, grid-based, no decoration.
Matches the Stripe reference in `.ux-profile.md`: clear type, well-structured data, depth by 1px
borders instead of shadows.

## Color

Material 3 `ColorScheme`, set role by role (no raw hex in widgets — use `Theme.of(context).colorScheme`).

| Role | Light | Dark | Use |
|------|-------|------|-----|
| `primary` / `onPrimary` | `#1E3A5F` / `#FFFFFF` | `#93C5FD` / `#0F172A` | Primary actions, selection, focus |
| `primaryContainer` / `on…` | `#DBE5F1` / `#1E3A5F` | `#1E3A5F` / `#DBE5F1` | Completed steps, selected chips |
| `secondary` / `onSecondary` | `#2563EB` / `#FFFFFF` | `#60A5FA` / `#0F172A` | Links, secondary emphasis |
| `error` / `onError` | `#DC2626` / `#FFFFFF` | `#F87171` / `#450A0A` | Failures, destructive actions |
| `surface` | `#F8FAFC` | `#0F172A` | Page canvas (L0) |
| `surfaceContainerLowest` | `#FFFFFF` | `#0B1220` | Cards in light theme (L1) |
| `surfaceContainerLow` | `#F1F5F9` | `#162033` | Cards in dark theme (L1) |
| `surfaceContainer` / `High` / `Highest` | `#EEF2F6` / `#E2E8F0` / `#CBD5E1` | `#1E293B` / `#273449` / `#334155` | Switchboard enclosure, inactive steps |
| `onSurface` | `#0F172A` | `#F1F5F9` | Body text |
| `onSurfaceVariant` | `#475569` | `#94A3B8` | Secondary text, labels |
| `outline` | `#64748B` | `#7C8BA1` | Input and component borders (≥ 3:1) |
| `outlineVariant` | `#E2E8F0` | `#334155` | Card borders, dividers, hairlines |

Status colours (`StatusColors` theme extension): success `#2E7D32` / `#81C784`, warning `#A15C00` /
`#FFD54F`; failures use `error`. **Green is reserved for «passed»** — it is never an action colour.

Phase colours on the switchboard follow ГОСТ 33542-2015 (L1 brown, L2 black, L3 grey) and are not
theme roles; label text on them picks black or white by luminance.

Contrast (WCAG 2.1 AA, checked on `surface`, `surfaceContainerLowest/Low` and `surfaceContainer`):
text roles ≥ 4.5:1 (`onSurfaceVariant` 6.9–7.6 light, 5.7–7.0 dark), `outline` ≥ 3:1
(4.3–4.8 light, 4.2–5.2 dark), status colours ≥ 4:1.

## Typography

- **Font:** IBM Plex Sans (`fontFamily: 'IBMPlexSans'`), bundled in `app/assets/fonts` under OFL 1.1 —
  no runtime download, works offline. Full Cyrillic plus Δ, φ, №, ₽, ², ×, ≤, ≈.
- **Weights:** 400, 500 (Material 3 titles and labels), 600 (emphasis). Nothing above 600.
- **Numbers:** Plex digits are tabular by default (all 600 units wide), so columns of currents, lengths
  and prices line up without `FontFeature.tabularFigures`.
- **Scale:** Material 3 `TextTheme`; body 16 / secondary 14 / meta 12, nothing below 12.
- PDF reports keep Noto Sans (`engine/report_pdf`).

## Spacing and shape

- 8pt grid for layout, 4pt for micro gaps (density 7: 4 · 8 · 16 · 24 · 32).
- Radius 12 for cards and the projects list frame, 8 for small controls (Material defaults otherwise).
- Page content capped at 1280 (`ContentWidth`); chrome stays full width.

## Elevation

- **Borders first:** cards have `elevation: 0` and a 1px `outlineVariant` border; app bar and wizard
  footer are separated by a 1px border, no scroll tint or shadow.
- No decorative shadows. Overlays (bottom sheets, dialogs, menus) keep Material defaults.

## Motion

Material defaults only (page transitions, ripples, sheet slide). No decorative or looping animation.
Any new animation follows the VectorLab `motion` and `reduced-motion` skills.

## Icons

Material Icons (`Icons.*`, prefer `_outlined`). No other icon sets, no emoji.

---

## Rejected from the generated output

| Generated | Why rejected |
|-----------|--------------|
| Page pattern «Trust & Authority + Conversion» | Landing-page pattern; this is a working tool. Page patterns come from VectorLab `page-patterns` |
| Accent/CTA green `#059669` | Collides with the «passed» status; actions use `primary` |
| Poppins + Open Sans | Poppins has no Cyrillic; replaced by IBM Plex Sans from the follow-up typography search |
| Card shadows `--shadow-md/lg`, hover lift | Borders first per `.ux-profile.md` |
| Modal `backdrop-filter: blur` | Banned in `.ux-profile.md` |
| GSAP scroll reveal | Web-only library; not applicable to Flutter |
| CSS component specs, `cursor: pointer` | Web CSS; Flutter widgets and Material theme cover these |

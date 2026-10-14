# Design System Master File — «Чертёж»

> **LOGIC:** When building a specific page, first check `design-system/shchitovik/pages/[page-name].md`.
> If that file exists, its rules **override** this Master file. If not, follow the rules below.
>
> Implementation: package [`common/common_ui`](../../common/common_ui) — tokens (`UiColors`,
> `UiTextStyles`, `UiSpace`, `UiRadius`, `UiSize`, `UiMotion`, `UiIcons`), the theme (`UiTheme`) and
> the widgets. A live showcase of every widget is the `UiGallery` route `/dev/ui` (debug builds,
> link in Settings). Taste, a11y, bans and voice: `.ux-profile.md`.

---

**Project:** Щитовик (Shchitovik) — switchboard calculator and estimate, Flutter (Android, iOS, Web)
**Chosen:** 2026-10-14, direction A «Чертёж» out of three compared (A Чертёж, B Приборная панель,
C Ясный). Replaces the Material-based navy/slate theme of 2026-10-13.

---

## Idea

The interface reads like a neat engineering drawing: ink on paper, hairlines, stamp-like upper-case
labels, every quantity in a monospaced face. One signal colour (orange) marks what is current:
the wizard step, the selected section, keyboard focus. Status colours are reserved for check
results. Nothing decorative: no gradients, no shadows on content, no illustrations.

## Colour roles (`UiColors`)

| Role | Light | Dark | Use |
|------|-------|------|-----|
| `canvas` | `#F4F4F4` | `#0A0A0A` | Page background |
| `surface` | `#FFFFFF` | `#141414` | Cards, bars, sheets |
| `sunken` | `#EBEBEB` | `#1F1F1F` | Segmented track, table header, hover, selected nav |
| `border` | `#D9D9D9` | `#2A2A2A` | Hairlines between rows and around cards |
| `borderStrong` | `#808080` | `#737373` | Inputs, outlined buttons, switchboard frame (≥ 3:1) |
| `text` / `textMuted` | `#0A0A0A` / `#525252` | `#F5F5F5` / `#A3A3A3` | Body / secondary text, units |
| `primary` / `onPrimary` | `#0A0A0A` / `#FFFFFF` | `#F5F5F5` / `#0A0A0A` | Main action fill |
| `accent` / `accentText` / `accentSoft` | `#D9480F` / `#B03A0B` / `#FBE7DC` | `#FF7B36` / `#FF9157` / `#3A2216` | Current step, selection, focus ring |
| `success` (+ `Soft`) | `#1B6E34` | `#5BC984` | Passed check — never an action colour |
| `warning` (+ `Soft`) | `#95590A` | `#E8B651` | Needs review |
| `danger` (+ `Soft`, `onDanger`) | `#C42B1C` | `#FF6E61` | Failure, destructive actions |

Contrast is enforced by `common/common_ui/test/ui_colors_contrast_test.dart` (WCAG 2.1 AA) for both
themes: text roles ≥ 4.5:1 on `canvas`, `surface`, `sunken`; `borderStrong` and `accent` ≥ 3:1;
content on filled controls ≥ 4.5:1; every status tone ≥ 4.5:1 on its own tint. Change a colour →
the test must stay green.

Phase colours on the switchboard follow ГОСТ 33542-2015 (L1 brown, L2 black, L3 grey) and are not
theme roles; label text on them picks black or white by luminance.

## Typography (`UiTextStyles`)

- **IBM Plex Sans** for text, **IBM Plex Mono** for values, units and labels; both bundled in
  `common_ui/assets/fonts` (OFL 1.1), work offline. Plex Mono has no Greek, so mono styles fall back
  to Plex Sans for Δ, φ.
- Weights 400 / 500 / 600 only. Nothing below 12 px.

| Style | Size / weight | Use |
|-------|---------------|-----|
| `display` | 28 / 600 | Rare: wide page titles |
| `title` | 20 / 600 | Screen and sheet titles |
| `heading` | 16 / 600 | Card and section headings |
| `body` / `bodyStrong` | 16 / 400, 500 | Text, row titles, inputs |
| `bodySmall` | 14 / 400 | Subtitles, table cells |
| `caption` | 13 / 400 | Helper, error, field labels |
| `button` | 15 / 600 | Buttons |
| `label` (mono) | 12 / 500, +0.7 tracking, UPPER CASE | Stamp labels over values and groups |
| `value` / `valueStrong` (mono) | 14 / 400, 600 | Quantities in rows and tables |
| `reading` / `readingLarge` (mono) | 20 / 500, 28 / 600 | Metric tiles, the estimate total |

Quantity symbols (`In`, `Iz`, `ΔU`, `cos φ`) keep their case: `UiLabel(symbol: true)`,
`UiMetric(symbol: true)`.

## Space, shape, depth

- 4pt micro / 8pt layout: `UiSpace` 4 · 8 · 12 · 16 · 24 · 32 · 48. Gutter 16 on phones, 24 wide.
- Corners: 3 px controls, 4 px cards (`UiRadius`); sheets 8 px at the top.
- Depth by 1px hairlines only. Overlays (menus, dialogs) get one soft shadow; content never does.
- Touch targets 44 px (`UiSize.control`); small buttons are 36 px tall inside a 44 px hit area.

## Layout

- Breakpoints (`UiBreakpoints`): expanded layout from 840 px; two columns from 960 px of content;
  content max 1280 px; forms max 720 px.
- **Phone:** top bar + step bar (wizard Объект → Помещения → Линии → Смета), content, action bar
  with «Назад / Далее» and the step hint.
- **Web / wide:** 248 px sidebar (brand, project summary, sections with counts, «Все проекты»,
  «Настройки»), top bar with the project as a stamp label and the section as the title, actions
  on the right. Circuits become a `UiTable`; estimate, circuit details and rooms go two-column.
- Sheets (`showUiSheet`) are bottom sheets on phones and centered 560 px panels on wide screens.

## Widgets

`UiButton` (primary, secondary, ghost, danger; busy, small), `UiIconButton` (tooltip required),
`UiMenuButton`, `UiCard`, `UiFieldGroup`, `UiDivided`, `UiLabel`, `UiSectionHeader`,
`UiTextField`, `UiSelect`, `UiSegmented`, `UiSwitchRow`, `UiChoiceRow`, `UiListRow`, `UiKeyValueList`,
`UiMetricGrid`, `UiRangeBar`, `UiTable`, `UiBadge`, `UiStatusIcon`, `UiNotice`, `UiDisclosure`,
`UiEmptyState`, `UiTopBar`, `UiSidebar` + `UiNavItem`, `UiStepBar`, `UiActionBar`, `UiSheet`,
`showUiConfirm`, `showUiToast`, `UiSpinner`, `UiDeferredProgress`, `UiContentWidth`.

All tappable widgets build on `UiPressable`: hover tint, press tint, Enter/Space activation, pointer
cursor, button semantics, and a 2px orange focus ring in keyboard mode only.

## Motion

120 ms for hover/press/toggles, 200 ms for disclosure and chevrons, ease-out cubic; everything goes
through `UiMotion.of`, which returns zero when the platform asks to reduce motion. No ripples.

## Icons

Lucide, weight 300, through `UiIcons` only. No Material icons, no emoji.

---

## Rejected

| Option | Why rejected |
|--------|--------------|
| Direction B «Приборная панель» (graphite, Manrope + JetBrains Mono) | Dark-first default does not suit every user |
| Direction C «Ясный» (Onest, soft shadows, pill buttons) | Closest to generic apps, little own identity |
| Generated «Data-Dense Dashboard», amber CTA, Fira Code / Fira Sans | Amber collides with the warning status; Plex already bundled and has Cyrillic |
| Material ripples, FAB, NavigationRail, filled M3 inputs | Replaced by own widgets so the look is consistent on web and phones |
| Card shadows, glassmorphism, gradients | Borders first; banned in `.ux-profile.md` |

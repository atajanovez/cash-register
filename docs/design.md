# Design system

Reference apps: Mercury, Revolut Business, Stripe Dashboard, Square, Linear: neutral surfaces, one brand colour, money colours with meaning.

## Tokens (`lib/core/theme/app_theme.dart`)

Widgets read colours from `context.palette` (`AppPalette`), never raw hex.

| Token | Use |
|---|---|
| `canvas` / `surface` / `surfaceMuted` | page background / cards / hover, selected, quiet fills |
| `border` / `borderStrong` | card and divider lines / input and button outlines |
| `text` / `textMuted` / `textSubtle` | primary / secondary / tertiary text and icons |
| `brand` / `brandSoft` | primary actions, selection / selected backgrounds |
| `positive` / `negative` | money in / money out and errors |
| `warning` | open obligations, checked registers |
| `heroStart` → `heroEnd` | balance card gradient and logo |

- **Type:** Inter (bundled, OFL), with tabular figures (`tabularFigures`) for every amount.
- **Sizes:** display 32, headline 30/26/22, title 18/15/14, body 15/14/12.5.
- **Radius:** 10 for controls, 14 for cards, 16–20 for dialogs and sheets.

## Platform behaviour

- **Controls:** desktop (macOS, Windows, Linux) is denser, with 40 px controls and no ripple. Touch devices get 48 px.
- **Layout:** `isWide` (≥ 900 px) switches layouts:

| | Phone | Wide |
|---|---|---|
| Navigation | Bottom bar | Sidebar (labels ≥ 1100 px, icons below), user card at the bottom |
| Main action | Floating button | Filled button at the top right of the `PageHeader` |
| Rare actions | App bar "⋮" opens a bottom sheet | "⋯" menu in the header |
| Item actions | Long press opens a bottom sheet | Right-click opens a menu at the cursor (`showActionMenu`) |
| Balance | Blue `MoneyHeroCard` | Three `StatTile`s |
| Records | `RecordTile` (two lines) | `RecordRow` table with column headers |
| Forms | Bottom sheet | Dialog |

## Logo

`LogoPainter` (`lib/core/widgets/app_logo.dart`) draws a white receipt on the brand gradient. Launcher icons are rendered from it:

```sh
RENDER_ICONS=1 flutter test test/tool/render_icons_test.dart
dart run flutter_launcher_icons
```

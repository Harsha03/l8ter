# L8ter — Visual Refresh Design

Date: 2026-04-25
Status: Approved (pending implementation plan)
Scope: Visual / UI refresh of all SwiftUI views in `l8ter/l8ter/Views/`. No
behavioral changes, no new features, no model changes.

## 1. Direction

L8ter becomes a **quiet, modernist app with a violet pulse**.

- Dark-first. Surfaces are near-black, never pure black.
- Information is the hero. Decoration is rare.
- Type does the work: SF Pro for content, SF Mono for metadata.
- Color is purposeful, not decorative. **Purple = "alive"**: selected,
  nearby, in-progress, verified, active.

The app should feel closer to Linear, Things, or Arc than to Instagram.

## 2. Design tokens

These are the canonical values. All views consume them; no view defines
its own colors or font sizes.

### 2.1 Color (Color+Tokens.swift)

| Token              | Hex      | Usage                                                |
| ------------------ | -------- | ---------------------------------------------------- |
| `bgBase`           | #0E0E10  | App background, screen surface                       |
| `bgRaised`         | #15151A  | Inputs, raised cards, processing tray                |
| `bgSunken`         | #13131A  | Subtle inset panels (e.g., pipeline steps box)       |
| `bgShell`          | #0A0A0C  | Phone-frame-like shell, never visible inside content |
| `borderHairline`   | #1C1C20  | Row separators                                       |
| `borderQuiet`      | #2A2A2E  | Card and chip borders                                |
| `textPrimary`      | #E8E6E1  | Headlines, primary content                           |
| `textSecondary`   | #8A8A90  | Secondary metadata                                   |
| `textTertiary`     | #6E6E73  | Mono labels, timestamps, captions                    |
| `textDisabled`     | #5A5A5E  | Disabled state, inactive tabs                        |
| `accent`           | #A78BFA  | Primary purple — active, alive, selected             |
| `accentBright`     | #C4B5FD  | Text on tinted purple background                     |
| `accentDeep`       | #8B5CF6  | Hairline accents, strong emphasis (rare)             |
| `accentTint`       | rgba(167,139,250,0.08) | Tinted backgrounds              |
| `accentTintStrong` | rgba(167,139,250,0.18) | Selected card backgrounds       |

All tokens get light-mode equivalents in the same file. Light mode is
not in the brainstorm mockups but must be defined; it inverts surfaces
and keeps the same accent.

### 2.2 Type (Typography.swift)

Two families only:

- **Display / Body**: system SF Pro (`.system(...)`)
- **Mono**: `.system(.body, design: .monospaced)`

Roles:

| Role          | Size | Weight | Tracking   | Use                                       |
| ------------- | ---- | ------ | ---------- | ----------------------------------------- |
| `screenTitle` | 30   | 700    | -0.7       | All top-level screen titles               |
| `heroTitle`   | 26   | 700    | -0.6       | Detail-view hero title                    |
| `cardTitle`   | 20   | 700    | -0.4       | Selection sheet titles                    |
| `rowTitle`    | 15   | 600    | -0.2       | List item titles                          |
| `body`        | 14   | 400    | 0          | Body copy, addresses, notes               |
| `secondary`   | 13   | 400    | 0          | Secondary text                            |
| `metaCaps`    | 10   | 600    | 1.4 (UC)   | **Mono.** Category + state labels         |
| `metaSmall`   | 11   | 400    | 0          | **Mono.** Sublines, source URLs           |
| `metaTiny`    | 9.5  | 600    | 1.0–1.4 UC | **Mono.** Tab bar labels, tiny captions   |

`metaCaps`, `metaSmall`, `metaTiny` are **monospaced** and the lower
case sub-text is rendered as `lowercase-with-hyphens` (e.g.
`sicilian-slice · brooklyn`).

### 2.3 Spacing & radii

Spacing scale: **4, 6, 8, 10, 14, 18, 22, 30**. Avoid in-betweens.

Radii:

- chip: 6
- button: 10–14
- thumbnail (small): 10
- thumbnail (large): 12
- input / card: 14

### 2.4 Effects

- **Glow**: `.shadow(color: accent.opacity(0.6), radius: 8)` for
  pulse dots, selected pin, progress fill, primary CTA.
- **Tinted card halo** (selected nearby card):
  `border: 0.5 accent`, `bg: accentTint`.
- **Pulse dot**: 5pt circle, `fill: accent`, glow as above. Used for
  "near you" indicators and the active pipeline step.
- **Animated pulse** for the active processing step: 1.2s opacity
  fade between 1.0 and 0.4.

## 3. Components (new SwiftUI views)

These are the primitives. Every screen composes them.

### 3.1 `MetaLabel`

`text` + optional `pulsing: Bool`. Renders mono-caps with optional
leading pulse dot. Used for category + state lines everywhere.

### 3.2 `Chip`

`label`, `tone: .neutral | .accent`. Hairline-bordered pill with
optional purple tint. Replaces today's plain text tags.

### 3.3 `Pulse`

5pt glowing circle. Optional `animated: Bool` for processing state.

### 3.4 `ConfidenceBar`

Tiny 3pt-tall bar with purple fill + glow. Used in the review queue
and the processing-completed state.

### 3.5 `PrimaryButton` / `GhostButton`

`PrimaryButton`: solid `accent`, dark text, 14pt 600.
`GhostButton`: hairline border, light text.

### 3.6 `SectionLabel`

Small `metaCaps` label used as a section header above row groups
(Settings, Manage Categories, Detail view).

### 3.7 `KeyValueRow`

Mono key on the left in `textSecondary`, value on the right in
`textPrimary`. Used in Settings, Detail "Notable" section, etc.

### 3.8 `PipelineStepList`

Vertical list of steps with state per row (`done`, `active`, `todo`),
each row being a glowing dot + mono-caps label + tiny duration. Lives
inside an `bgSunken` panel with hairline border.

## 4. Screen-by-screen direction

### 4.1 Tab bar (ContentView)

Custom appearance, not the SwiftUI default:

- Background: `bgBase`, top hairline `borderHairline`.
- Each tab: 18pt outlined icon + `metaTiny` mono-caps label below.
- Inactive tint: `textDisabled`. Active tint: `accent`.
- Review tab: badge is a 14pt purple dot with `0E0E10` numeral
  inside, top-right of the icon.

### 4.2 Saved (ItemListView) — **Media-forward**

- Title bar: `screenTitle` "Saved" left-aligned; right side shows
  count in `metaCaps` ("24 ITEMS"). Right-aligned to baseline.
- Filter row: horizontally scrolling mono pills ("all", "eat", ...).
  Active pill uses `accentTint` + `accentBright` text +
  `accentTint` border at 0.4 opacity.
- Rows (~5 per screen):
  - 64pt rounded thumbnail (`radius 12`).
  - Right column: `MetaLabel` (with pulse if nearby) →
    `rowTitle` → mono `metaSmall` subline.
  - Hairline divider between rows.
- Search bar uses native `.searchable`, retinted.
- Empty state and search-empty state retain `ContentUnavailableView`
  but with the new color palette.

### 4.3 Map (RestaurantsMapView) — **Glyph pins + atmospheric**

- MapKit `mapStyle(.standard(elevation: .realistic))` in dark mode.
- **Floating header** overlay (top of map, never opaque):
  pulse + `metaCaps` "NEAR YOU · N SAVED" left, `screenTitle` "Map"
  underneath, recenter chip on the right.
- **Annotations**:
  - Default pin: 10pt white dot with 2pt `bgBase` ring, mono caps
    label below.
  - Selected pin: 18pt `accent` filled circle with 34pt
    `accentTint` halo, label in `accent`.
- **Bottom selection sheet** (only when a pin is selected):
  attached to the bottom of the screen above the tab bar, hairline
  top border. Contains `MetaLabel` (pulse + distance + bearing),
  `cardTitle`, mono subline (address), and a row of
  `PrimaryButton` (Open in Maps) + 48pt `GhostButton` (Details).
- No bottom drawer of nearby places. Trust the map.

### 4.4 Detail (ItemDetailView) — **Hero + stacked sections**

- 240pt **hero**: thumbnail painted full width with a vertical
  gradient that dissolves into `bgBase` at the bottom. The
  `MetaLabel` and `heroTitle` sit at the bottom of the hero, on the
  thumbnail.
- Below hero: chip row (top chip is category-tinted purple, others
  are neutral).
- Sections, each separated by a hairline `borderHairline`:
  - **Address** — `SectionLabel` + body address + tiny mono
    "verified · web search ✓" caption when applicable. Mini-map
    inline if the restaurant has coordinates (existing iOS 18 Map).
  - **Notable / Where to watch / Genre / etc.** — `SectionLabel`
    + `KeyValueRow`s.
  - **Notes** (editable) and **Tags** (editable, using
    `TagEditor` retinted) keep their existing functionality.
  - **Source** — mono purple URL.
- Pinned bottom: `PrimaryButton` "Open in Maps" + 48pt
  `GhostButton` (share). Only shown for restaurants with coords.

### 4.5 Add (CaptureView) — **Three-state flow**

- **Idle**: `screenTitle` "Add" + `metaCaps` "01 · IDLE". Big
  `bgRaised` input card with `metaCaps` "Paste URL" label. Helper
  copy below in `textTertiary` mono. Disabled `PrimaryButton`
  pinned bottom.
- **Processing**: state changes to "02 · PROCESSING" in `accent`.
  Title becomes "Saving…". Input card is dimmed. Below it:
  `PipelineStepList` with steps:
  1. Fetched oEmbed
  2. Saved thumbnail
  3. Asking Claude…
  4. Verify address (restaurants only)
  5. Geocode (restaurants only) / Lookup metadata (movies/shows)
  Each row shows real elapsed seconds in mono.
- **Saved**: state "03 · SAVED" in `accent`, title "Got it.". Row
  showing the saved item (mini thumbnail + meta + title), plus a
  `ConfidenceBar` panel showing confidence as a percentage. Bottom
  has two buttons: `GhostButton` "Add another" (resets) +
  `PrimaryButton` "View →" (navigates to detail).

### 4.6 Review (ReviewQueueView) — **Confidence-bar list**

- `screenTitle` "Review", count in mono ("3 ITEMS") in `accent`.
- Helper subline: "Items where Claude wasn't sure. Edit and clear,
  or skip."
- Rows: 48pt thumbnail + `MetaLabel` + `rowTitle` (often "Untitled
  · address missing" or similar) + a `ConfidenceBar` with the
  numeric value to the right in mono.
- Tab bar shows the badge described in 4.1.

### 4.7 Review item edit (ReviewItemEditView)

Cosmetic-only refactor: re-uses the same form but with new
`SectionLabel`s, mono key labels, purple toggles, hairline rows.
Re-run extraction button is a `GhostButton`. Done is a
`PrimaryButton`.

### 4.8 Settings (SettingsView)

- Section grouping via `SectionLabel`s ("Claude API",
  "Proximity", "Status").
- API Key row shows masked key in mono with an "EDIT" affordance
  in `accent`.
- Toggles use the standard SwiftUI `Toggle` with a
  `.tint(accent)` modifier.
- Status section shows monitored count and last refresh in mono
  values right-aligned.
- Footer: "L8TER · vX.Y.Z · BUILD N" in `metaTiny` `textDisabled`.

### 4.9 Manage Categories (ManageCategoriesView)

- Title with "+ ADD" affordance in `accent` mono on the right.
- Sections "Built-in (N)" and "Custom (N)".
- Built-ins: row title + mono description. Restaurants row shows
  an inline `metaCaps` "RESTAURANT" tag in `accent` to indicate it
  has structured fields.
- Customs: row title + inline "CUSTOM" pill (`accentTint`
  background, `accent` text) + description.

### 4.10 Tag editor + chip row visuals

`TagEditor` keeps its current `FlowLayout` mechanics. Visual changes
only:
- Chips become `Chip` components with hairline border.
- Add field uses the same `bgRaised` input style as Add tab.

## 5. Implementation map

New files:

- `Views/DesignSystem/Color+Tokens.swift`
- `Views/DesignSystem/Typography.swift`
- `Views/DesignSystem/Components/MetaLabel.swift`
- `Views/DesignSystem/Components/Chip.swift`
- `Views/DesignSystem/Components/Pulse.swift`
- `Views/DesignSystem/Components/ConfidenceBar.swift`
- `Views/DesignSystem/Components/PrimaryButton.swift`
- `Views/DesignSystem/Components/GhostButton.swift`
- `Views/DesignSystem/Components/SectionLabel.swift`
- `Views/DesignSystem/Components/KeyValueRow.swift`
- `Views/DesignSystem/Components/PipelineStepList.swift`

Modified files (cosmetic-only — no logic changes):

- `ContentView.swift` (custom tab bar styling, badge)
- `Views/ItemListView.swift`
- `Views/ItemRowView.swift`
- `Views/ItemDetailView.swift`
- `Views/RestaurantsMapView.swift`
- `Views/CaptureView.swift` (re-introduces a step-by-step status
  view; today's view collapses statuses into a single label)
- `Views/ReviewQueueView.swift`
- `Views/ReviewItemEditView.swift`
- `Views/SettingsView.swift`
- `Views/ManageCategoriesView.swift`
- `Views/TagEditor.swift`
- `l8terApp.swift` (force `.preferredColorScheme(.dark)` for v1;
  light mode comes later)

## 6. Out of scope

- Custom font bundling (sticks to system SF Pro / SF Mono).
- Animation polish beyond the listed pulse/glow.
- Light mode rollout (tokens are defined; switch is deferred).
- Onboarding screens (none today; not adding them).
- Data model or API changes.
- Phase 4 share extension visuals (separate spec when that lands).

## 7. Risks

- **MapKit dark style**: pin overlay rendering must not get clipped
  by Apple's POI labels. Verify on device + simulator with
  realistic and standard map styles.
- **CaptureView pipeline steps**: today the saving flow doesn't
  expose granular step status. Implementation will need a
  `CaptureProgress` enum / observable state in `ItemSaver` (cosmetic
  internals, no behavior change).
- **Tab bar customization** in SwiftUI is constrained. If a fully
  custom `TabView` proves fragile, fallback is to use the default
  `TabView` with `UITabBarAppearance` tokens applied — accept the
  loss of custom mono labels rather than rebuild the tab system.

# l8ter

A personal iOS inbox for things I see in TikTok reels. Save a reel → Claude
categorizes it and extracts the interesting fields → it shows up in a
searchable list, on a map (for restaurants), or nudges me when I walk
past a saved spot.

## Demo

End-to-end: paste a TikTok URL, Claude classifies and extracts, the entry
lands in the saved list with a verified address, a map preview, and a
hand-off to Apple Maps.

### 1 · Paste a TikTok URL

<p align="center">
  <img src="docs/screenshots/Simulator%20Screenshot%20-%20iPhone%2017%20Pro%20-%202026-04-25%20at%2022.05.37.png" width="380" />
</p>

&nbsp;

### 2 · oEmbed → Claude

<p align="center">
  <img src="docs/screenshots/Simulator%20Screenshot%20-%20iPhone%2017%20Pro%20-%202026-04-25%20at%2022.05.47.png" width="380" />
</p>

&nbsp;

### 3 · Web-verify the address

<p align="center">
  <img src="docs/screenshots/Simulator%20Screenshot%20-%20iPhone%2017%20Pro%20-%202026-04-25%20at%2022.05.50.png" width="380" />
</p>

&nbsp;

### 4 · Saved · 0.95 confidence

<p align="center">
  <img src="docs/screenshots/Simulator%20Screenshot%20-%20iPhone%2017%20Pro%20-%202026-04-25%20at%2022.05.55.png" width="380" />
</p>

&nbsp;

### 5 · Saved list, filterable

<p align="center">
  <img src="docs/screenshots/Simulator%20Screenshot%20-%20iPhone%2017%20Pro%20-%202026-04-25%20at%2022.06.10.png" width="380" />
</p>

&nbsp;

### 6 · Detail · address + map

<p align="center">
  <img src="docs/screenshots/Simulator%20Screenshot%20-%20iPhone%2017%20Pro%20-%202026-04-25%20at%2022.06.24.png" width="380" />
</p>

&nbsp;

### 7 · Notable dishes, tags

<p align="center">
  <img src="docs/screenshots/Simulator%20Screenshot%20-%20iPhone%2017%20Pro%20-%202026-04-25%20at%2022.06.39.png" width="380" />
</p>

&nbsp;

### 8 · Open in Apple Maps

<p align="center">
  <img src="docs/screenshots/Simulator%20Screenshot%20-%20iPhone%2017%20Pro%20-%202026-04-25%20at%2022.07.01.png" width="380" />
</p>

## What it does today

- **Capture**: paste a TikTok URL (a silent share-sheet extension is on
  the roadmap as Phase 4 once the Apple Developer account lands)
- **Categorize**: Claude Haiku 4.5 picks one of 9 built-in categories
  (restaurant, movie, show, activity, recipe, place, book, product,
  uncategorized) or one you've defined yourself with a description
- **Enrich**: separate Claude calls with `web_search` look up the
  canonical restaurant address, movie year/director, show creator, etc.
- **Map**: restaurants show up on a MapKit view, tap-to-open in Apple Maps
- **Proximity**: up to 20 saved restaurants are monitored as low-power
  geofences; get a local notification when you walk within 150m
- **Review**: anything Claude wasn't confident about (or marked
  uncategorized) lands in a review queue where you can edit or re-run
- **Organize**: free-text search, manual tags, archive (not delete)

## Stack

- Native iOS, Swift + SwiftUI, **iOS 18+**
- SwiftData for persistence
- Claude API direct from device (Haiku 4.5, multimodal, prompt caching
  on the system prompt, web_search tool for verification)
- CoreLocation region monitoring, UserNotifications, MapKit, CLGeocoder
- No backend

## Running locally

1. Open `l8ter/l8ter.xcodeproj` in Xcode 16+
2. Select the `l8ter` scheme, pick an iPhone 18+ simulator
3. Build and run (⌘R)
4. On first launch, go to the **Debug** tab → **Settings** and paste a
   Claude API key. It's stored in the iOS Keychain.
5. Use the **Add** tab to paste a TikTok URL and save your first reel.

For proximity notifications to fire on the simulator, use
*Features → Location → Custom Location…* after enabling the toggle in
Settings.

## Phase status

Phases 0–3 and 5–8 complete; Phase 4 (silent share extension with
App Group queue) pending a paid Apple Developer account.

## Notes

- The Claude API key lives in the device Keychain for v1. Flagged as
  tech debt — must move server-side before any public distribution.
- Personal use only; no App Store submission planned.

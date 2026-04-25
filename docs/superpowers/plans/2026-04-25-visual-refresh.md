# L8ter Visual Refresh Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refresh L8ter's visual design across every SwiftUI screen to match the approved spec at `docs/superpowers/specs/2026-04-25-visual-refresh-design.md` — dark modernist aesthetic with SF Pro / SF Mono typography and functional purple accent.

**Architecture:** Introduce a small SwiftUI design system (`Views/DesignSystem/`) with color tokens, typography roles, and ~10 reusable component primitives. Then rewrite each existing view's body to compose those primitives. No business logic changes; Capture only adds an internal progress observable.

**Tech Stack:** SwiftUI (iOS 18+), SwiftData, MapKit. System fonts only (no font bundling). Build verification via `xcodebuild` for iPhone 16 simulator.

---

## Conventions for every task

- All file paths relative to `/Users/bobbydylan/Projects/location/`.
- After each task, run the project build:
  ```bash
  xcodebuild -project l8ter/l8ter.xcodeproj -scheme l8ter \
    -destination 'platform=iOS Simulator,name=iPhone 16' \
    -configuration Debug build 2>&1 | tail -25
  ```
  Expected last line: `** BUILD SUCCEEDED **`
- Each task ends with a single git commit. Commit messages follow the existing repo style (imperative, no scope prefix). Include the Co-Authored-By footer used in prior commits.
- This codebase has no XCTest target. Verification is **build + SwiftUI Preview**, not unit tests. Where a task adds a new component file, the file MUST include a `#Preview` block; the verification step is "open the file in Xcode, confirm preview renders" — but a clean build is the gating check that can run from terminal.
- New Swift files added under `l8ter/l8ter/Views/DesignSystem/` will be picked up automatically by Xcode 16's filesystem-synced groups (this project uses synced groups — confirmed via existing folder structure). If a file is not picked up, open Xcode once and let it refresh.

---

## File Structure

**Create (new):**
- `l8ter/l8ter/Views/DesignSystem/Color+Tokens.swift` — color palette
- `l8ter/l8ter/Views/DesignSystem/Typography.swift` — font roles
- `l8ter/l8ter/Views/DesignSystem/Spacing.swift` — spacing + radii constants
- `l8ter/l8ter/Views/DesignSystem/Components/MetaLabel.swift`
- `l8ter/l8ter/Views/DesignSystem/Components/Pulse.swift`
- `l8ter/l8ter/Views/DesignSystem/Components/Chip.swift`
- `l8ter/l8ter/Views/DesignSystem/Components/SectionLabel.swift`
- `l8ter/l8ter/Views/DesignSystem/Components/KeyValueRow.swift`
- `l8ter/l8ter/Views/DesignSystem/Components/PrimaryButton.swift`
- `l8ter/l8ter/Views/DesignSystem/Components/GhostButton.swift`
- `l8ter/l8ter/Views/DesignSystem/Components/ConfidenceBar.swift`
- `l8ter/l8ter/Views/DesignSystem/Components/PipelineStepList.swift`
- `l8ter/l8ter/Views/DesignSystem/Components/CardSurface.swift` — reusable raised/sunken surface

**Modify (cosmetic only, no behavior change except CaptureView's progress emission):**
- `l8ter/l8ter/l8terApp.swift` — force `.preferredColorScheme(.dark)`
- `l8ter/l8ter/ContentView.swift` — re-skin `TabView` via `UITabBarAppearance`
- `l8ter/l8ter/Views/ItemListView.swift`
- `l8ter/l8ter/Views/ItemRowView.swift`
- `l8ter/l8ter/Views/ItemDetailView.swift`
- `l8ter/l8ter/Views/RestaurantsMapView.swift`
- `l8ter/l8ter/Views/CaptureView.swift` — add `CaptureProgress` enum + step list
- `l8ter/l8ter/Views/ReviewQueueView.swift`
- `l8ter/l8ter/Views/ReviewItemEditView.swift`
- `l8ter/l8ter/Views/SettingsView.swift`
- `l8ter/l8ter/Views/ManageCategoriesView.swift`
- `l8ter/l8ter/Views/TagEditor.swift`

---

## Task 1: Color tokens

**Files:**
- Create: `l8ter/l8ter/Views/DesignSystem/Color+Tokens.swift`

- [ ] **Step 1: Write the file**

```swift
// l8ter/l8ter/Views/DesignSystem/Color+Tokens.swift
import SwiftUI

/// Canonical color tokens for the app. All views consume these — no
/// view should define its own raw hex values. Tokens are dark-first;
/// light-mode equivalents are wired through SwiftUI's automatic
/// rendering of asset-catalog colors when we eventually add them.
extension Color {
    // Surfaces
    static let bgBase    = Color(hex: 0x0E0E10)
    static let bgRaised  = Color(hex: 0x15151A)
    static let bgSunken  = Color(hex: 0x13131A)
    static let bgShell   = Color(hex: 0x0A0A0C)

    // Borders
    static let borderHairline = Color(hex: 0x1C1C20)
    static let borderQuiet    = Color(hex: 0x2A2A2E)

    // Text
    static let textPrimary   = Color(hex: 0xE8E6E1)
    static let textSecondary = Color(hex: 0x8A8A90)
    static let textTertiary  = Color(hex: 0x6E6E73)
    static let textDisabled  = Color(hex: 0x5A5A5E)

    // Accent
    static let accent           = Color(hex: 0xA78BFA)
    static let accentBright     = Color(hex: 0xC4B5FD)
    static let accentDeep       = Color(hex: 0x8B5CF6)
    static let accentTint       = Color(hex: 0xA78BFA, opacity: 0.08)
    static let accentTintStrong = Color(hex: 0xA78BFA, opacity: 0.18)
    static let accentBorderSoft = Color(hex: 0xA78BFA, opacity: 0.40)
}

private extension Color {
    init(hex: UInt32, opacity: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8)  & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }
}
```

- [ ] **Step 2: Build**

Run the project build command from "Conventions". Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 3: Commit**

```bash
git add l8ter/l8ter/Views/DesignSystem/Color+Tokens.swift
git commit -m "$(cat <<'EOF'
Add color tokens for visual refresh

Establishes the dark-first palette and accent purple tokens that every
view will consume. No view changes yet.

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: Typography roles

**Files:**
- Create: `l8ter/l8ter/Views/DesignSystem/Typography.swift`

- [ ] **Step 1: Write the file**

```swift
// l8ter/l8ter/Views/DesignSystem/Typography.swift
import SwiftUI

/// Named typographic roles. Use `Font.dsScreenTitle` etc. instead of
/// raw `.system(size:)` calls in views. Mono roles use the system
/// monospaced design — no custom fonts.
extension Font {
    // Display — system SF Pro
    static let dsScreenTitle = Font.system(size: 30, weight: .bold).leading(.tight)
    static let dsHeroTitle   = Font.system(size: 26, weight: .bold).leading(.tight)
    static let dsCardTitle   = Font.system(size: 20, weight: .bold).leading(.tight)
    static let dsRowTitle    = Font.system(size: 15, weight: .semibold)
    static let dsBody        = Font.system(size: 14)
    static let dsSecondary   = Font.system(size: 13)

    // Mono — system monospaced
    static let dsMetaCaps  = Font.system(size: 10, weight: .semibold, design: .monospaced)
    static let dsMetaSmall = Font.system(size: 11, design: .monospaced)
    static let dsMetaTiny  = Font.system(size: 9.5, weight: .semibold, design: .monospaced)
}

/// Tracking values to apply via `.tracking(...)`. Swift `Font` doesn't
/// expose tracking directly — pair these with `.tracking()` on the Text.
enum DSTracking {
    static let screenTitle: CGFloat = -0.7
    static let heroTitle:   CGFloat = -0.6
    static let cardTitle:   CGFloat = -0.4
    static let rowTitle:    CGFloat = -0.2
    static let metaCaps:    CGFloat =  1.4
    static let metaTiny:    CGFloat =  1.0
}
```

- [ ] **Step 2: Build**

Run build. Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 3: Commit**

```bash
git add l8ter/l8ter/Views/DesignSystem/Typography.swift
git commit -m "$(cat <<'EOF'
Add typography roles for visual refresh

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: Spacing + radii

**Files:**
- Create: `l8ter/l8ter/Views/DesignSystem/Spacing.swift`

- [ ] **Step 1: Write the file**

```swift
// l8ter/l8ter/Views/DesignSystem/Spacing.swift
import SwiftUI

/// Allowed spacing values. Use these instead of arbitrary numbers.
enum DSSpace {
    static let xxs: CGFloat = 4
    static let xs:  CGFloat = 6
    static let sm:  CGFloat = 8
    static let md:  CGFloat = 10
    static let lg:  CGFloat = 14
    static let xl:  CGFloat = 18
    static let xxl: CGFloat = 22
    static let huge: CGFloat = 30
}

/// Allowed corner radii.
enum DSRadius {
    static let chip:   CGFloat = 6
    static let button: CGFloat = 12
    static let thumb:  CGFloat = 10
    static let thumbLarge: CGFloat = 12
    static let card:   CGFloat = 14
}
```

- [ ] **Step 2: Build**

Run build. Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 3: Commit**

```bash
git add l8ter/l8ter/Views/DesignSystem/Spacing.swift
git commit -m "$(cat <<'EOF'
Add spacing and radius constants for visual refresh

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
EOF
)"
```

---

## Task 4: `Pulse` + `MetaLabel` components

**Files:**
- Create: `l8ter/l8ter/Views/DesignSystem/Components/Pulse.swift`
- Create: `l8ter/l8ter/Views/DesignSystem/Components/MetaLabel.swift`

- [ ] **Step 1: Write `Pulse.swift`**

```swift
// l8ter/l8ter/Views/DesignSystem/Components/Pulse.swift
import SwiftUI

/// 5pt glowing purple dot. Used as the "alive" indicator next to
/// nearby items, the active processing step, and selected map pins.
struct Pulse: View {
    var animated: Bool = false

    @State private var dim = false

    var body: some View {
        Circle()
            .fill(Color.accent)
            .frame(width: 5, height: 5)
            .shadow(color: Color.accent.opacity(0.6), radius: 4)
            .opacity(dim ? 0.4 : 1.0)
            .onAppear {
                guard animated else { return }
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    dim = true
                }
            }
    }
}

#Preview {
    HStack(spacing: 20) {
        Pulse()
        Pulse(animated: true)
    }
    .padding(40)
    .background(Color.bgBase)
}
```

- [ ] **Step 2: Write `MetaLabel.swift`**

```swift
// l8ter/l8ter/Views/DesignSystem/Components/MetaLabel.swift
import SwiftUI

/// Mono-caps label used everywhere for category + state lines.
/// e.g. "EAT · 0.4 MI", "MOVIE · 04.21".
struct MetaLabel: View {
    let text: String
    var pulsing: Bool = false
    var tone: Tone = .neutral

    enum Tone {
        case neutral
        case accent
    }

    var body: some View {
        HStack(spacing: 5) {
            if pulsing {
                Pulse(animated: true)
            }
            Text(text.uppercased())
                .font(.dsMetaCaps)
                .tracking(DSTracking.metaCaps)
                .foregroundStyle(tone == .accent ? Color.accent : Color.textTertiary)
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 12) {
        MetaLabel(text: "EAT · 04.22")
        MetaLabel(text: "EAT · 0.4 MI", pulsing: true, tone: .accent)
        MetaLabel(text: "03 · SAVED", tone: .accent)
    }
    .padding(40)
    .background(Color.bgBase)
}
```

- [ ] **Step 3: Build**

Run build. Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 4: Commit**

```bash
git add l8ter/l8ter/Views/DesignSystem/Components/Pulse.swift \
        l8ter/l8ter/Views/DesignSystem/Components/MetaLabel.swift
git commit -m "$(cat <<'EOF'
Add Pulse and MetaLabel components

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
EOF
)"
```

---

## Task 5: `Chip` and `SectionLabel`

**Files:**
- Create: `l8ter/l8ter/Views/DesignSystem/Components/Chip.swift`
- Create: `l8ter/l8ter/Views/DesignSystem/Components/SectionLabel.swift`

- [ ] **Step 1: Write `Chip.swift`**

```swift
// l8ter/l8ter/Views/DesignSystem/Components/Chip.swift
import SwiftUI

/// Hairline-bordered pill. Two tones: neutral (default) and accent
/// (purple-tinted). Used for tags, filter pills, category labels.
struct Chip: View {
    let label: String
    var tone: Tone = .neutral

    enum Tone {
        case neutral
        case accent
    }

    var body: some View {
        Text(label)
            .font(.dsMetaSmall)
            .foregroundStyle(foreground)
            .padding(.horizontal, 10)
            .padding(.vertical, 3)
            .background(background)
            .overlay(
                RoundedRectangle(cornerRadius: DSRadius.chip)
                    .strokeBorder(border, lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: DSRadius.chip))
    }

    private var foreground: Color {
        switch tone {
        case .neutral: return .textSecondary
        case .accent:  return .accentBright
        }
    }

    private var background: Color {
        switch tone {
        case .neutral: return .clear
        case .accent:  return .accentTint
        }
    }

    private var border: Color {
        switch tone {
        case .neutral: return .borderQuiet
        case .accent:  return .accentBorderSoft
        }
    }
}

#Preview {
    HStack(spacing: 6) {
        Chip(label: "sicilian", tone: .accent)
        Chip(label: "slice")
        Chip(label: "bklyn")
    }
    .padding(40)
    .background(Color.bgBase)
}
```

- [ ] **Step 2: Write `SectionLabel.swift`**

```swift
// l8ter/l8ter/Views/DesignSystem/Components/SectionLabel.swift
import SwiftUI

/// Small mono-caps eyebrow used as a section header above row groups.
struct SectionLabel: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(.dsMetaCaps)
            .tracking(DSTracking.metaCaps)
            .foregroundStyle(Color.textTertiary)
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 12) {
        SectionLabel(text: "Address")
        SectionLabel(text: "Notable")
        SectionLabel(text: "Source")
    }
    .padding(40)
    .background(Color.bgBase)
}
```

- [ ] **Step 3: Build**

Run build. Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 4: Commit**

```bash
git add l8ter/l8ter/Views/DesignSystem/Components/Chip.swift \
        l8ter/l8ter/Views/DesignSystem/Components/SectionLabel.swift
git commit -m "$(cat <<'EOF'
Add Chip and SectionLabel components

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
EOF
)"
```

---

## Task 6: `KeyValueRow` and `ConfidenceBar`

**Files:**
- Create: `l8ter/l8ter/Views/DesignSystem/Components/KeyValueRow.swift`
- Create: `l8ter/l8ter/Views/DesignSystem/Components/ConfidenceBar.swift`

- [ ] **Step 1: Write `KeyValueRow.swift`**

```swift
// l8ter/l8ter/Views/DesignSystem/Components/KeyValueRow.swift
import SwiftUI

/// Mono key on the left in textSecondary, value on the right in
/// textPrimary. Used in Settings, Detail "Notable" section, etc.
struct KeyValueRow: View {
    let key: String
    let value: String?
    var valueTone: ValueTone = .primary

    enum ValueTone {
        case primary
        case accent
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(key)
                .font(.dsMetaSmall)
                .foregroundStyle(Color.textSecondary)
            Spacer(minLength: 8)
            Text(value ?? "—")
                .font(.dsBody)
                .foregroundStyle(valueColor)
                .multilineTextAlignment(.trailing)
                .textSelection(.enabled)
        }
        .padding(.vertical, 6)
    }

    private var valueColor: Color {
        switch valueTone {
        case .primary: return .textPrimary
        case .accent:  return .accent
        }
    }
}

#Preview {
    VStack(spacing: 0) {
        KeyValueRow(key: "cuisine", value: "Sicilian")
        KeyValueRow(key: "address", value: "8616 Ave X, Brooklyn")
        KeyValueRow(key: "verified", value: "via web search", valueTone: .accent)
    }
    .padding(.horizontal, 22)
    .padding(.vertical, 20)
    .background(Color.bgBase)
}
```

- [ ] **Step 2: Write `ConfidenceBar.swift`**

```swift
// l8ter/l8ter/Views/DesignSystem/Components/ConfidenceBar.swift
import SwiftUI

/// Tiny 3pt-tall bar with purple fill + glow. Shows extraction
/// confidence in the review queue and the post-save state.
struct ConfidenceBar: View {
    /// 0.0 ... 1.0
    let value: Double
    var width: CGFloat = 60

    var body: some View {
        ZStack(alignment: .leading) {
            Capsule()
                .fill(Color.bgRaised)
            Capsule()
                .fill(Color.accent)
                .shadow(color: Color.accent.opacity(0.6), radius: 4)
                .frame(width: width * CGFloat(max(0, min(1, value))))
        }
        .frame(width: width, height: 3)
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 10) {
        ConfidenceBar(value: 0.92)
        ConfidenceBar(value: 0.48)
        ConfidenceBar(value: 0.35)
    }
    .padding(40)
    .background(Color.bgBase)
}
```

- [ ] **Step 3: Build**

Run build. Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 4: Commit**

```bash
git add l8ter/l8ter/Views/DesignSystem/Components/KeyValueRow.swift \
        l8ter/l8ter/Views/DesignSystem/Components/ConfidenceBar.swift
git commit -m "$(cat <<'EOF'
Add KeyValueRow and ConfidenceBar components

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
EOF
)"
```

---

## Task 7: `PrimaryButton` and `GhostButton`

**Files:**
- Create: `l8ter/l8ter/Views/DesignSystem/Components/PrimaryButton.swift`
- Create: `l8ter/l8ter/Views/DesignSystem/Components/GhostButton.swift`

- [ ] **Step 1: Write `PrimaryButton.swift`**

```swift
// l8ter/l8ter/Views/DesignSystem/Components/PrimaryButton.swift
import SwiftUI

/// Solid purple CTA. 14pt semibold, dark text on accent background.
struct PrimaryButton: View {
    let title: String
    var systemImage: String?
    var disabled: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 13, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .foregroundStyle(disabled ? Color.textDisabled : Color.bgBase)
            .background(disabled ? Color.bgRaised : Color.accent)
            .clipShape(RoundedRectangle(cornerRadius: DSRadius.button))
        }
        .disabled(disabled)
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 12) {
        PrimaryButton(title: "Open in Maps", systemImage: "play.fill") {}
        PrimaryButton(title: "Save", disabled: true) {}
    }
    .padding(40)
    .background(Color.bgBase)
}
```

- [ ] **Step 2: Write `GhostButton.swift`**

```swift
// l8ter/l8ter/Views/DesignSystem/Components/GhostButton.swift
import SwiftUI

/// Hairline-bordered button. Light text on transparent background.
struct GhostButton: View {
    let title: String
    var systemImage: String?
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 13, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .foregroundStyle(Color.textPrimary)
            .overlay(
                RoundedRectangle(cornerRadius: DSRadius.button)
                    .strokeBorder(Color.borderQuiet, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HStack(spacing: 12) {
        GhostButton(title: "Add another") {}
        PrimaryButton(title: "View →") {}
    }
    .padding(40)
    .background(Color.bgBase)
}
```

- [ ] **Step 3: Build**

Run build. Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 4: Commit**

```bash
git add l8ter/l8ter/Views/DesignSystem/Components/PrimaryButton.swift \
        l8ter/l8ter/Views/DesignSystem/Components/GhostButton.swift
git commit -m "$(cat <<'EOF'
Add PrimaryButton and GhostButton components

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
EOF
)"
```

---

## Task 8: `CardSurface` + `PipelineStepList`

**Files:**
- Create: `l8ter/l8ter/Views/DesignSystem/Components/CardSurface.swift`
- Create: `l8ter/l8ter/Views/DesignSystem/Components/PipelineStepList.swift`

- [ ] **Step 1: Write `CardSurface.swift`**

```swift
// l8ter/l8ter/Views/DesignSystem/Components/CardSurface.swift
import SwiftUI

/// A raised or sunken panel surface with hairline border. Use as a
/// container for inputs, pipeline step lists, or confidence panels.
struct CardSurface<Content: View>: View {
    var elevation: Elevation = .raised
    @ViewBuilder var content: () -> Content

    enum Elevation {
        case raised
        case sunken
    }

    var body: some View {
        content()
            .background(elevation == .raised ? Color.bgRaised : Color.bgSunken)
            .overlay(
                RoundedRectangle(cornerRadius: DSRadius.card)
                    .strokeBorder(Color.borderHairline, lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: DSRadius.card))
    }
}
```

- [ ] **Step 2: Write `PipelineStepList.swift`**

```swift
// l8ter/l8ter/Views/DesignSystem/Components/PipelineStepList.swift
import SwiftUI

/// Vertical list of pipeline steps used in the Add tab during save.
/// Each step has a label and a state (todo / active / done) plus an
/// optional duration string shown on the right in mono.
struct PipelineStepList: View {
    let steps: [Step]

    struct Step: Identifiable {
        let id = UUID()
        let label: String
        let state: State
        let duration: String?
    }

    enum State {
        case todo
        case active
        case done
    }

    var body: some View {
        CardSurface(elevation: .sunken) {
            VStack(spacing: 0) {
                ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                    HStack(spacing: 12) {
                        dot(for: step.state)
                        Text(step.label.uppercased())
                            .font(.dsMetaCaps)
                            .tracking(1.0)
                            .foregroundStyle(labelColor(for: step.state))
                        Spacer(minLength: 0)
                        Text(step.duration ?? "—")
                            .font(.dsMetaSmall)
                            .foregroundStyle(Color.textTertiary)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)

                    if index < steps.count - 1 {
                        Rectangle()
                            .fill(Color.borderHairline)
                            .frame(height: 0.5)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func dot(for state: State) -> some View {
        switch state {
        case .todo:
            Circle().fill(Color.borderQuiet).frame(width: 8, height: 8)
        case .active:
            Pulse(animated: true).scaleEffect(1.6)
        case .done:
            Circle()
                .fill(Color.accent)
                .frame(width: 8, height: 8)
                .shadow(color: Color.accent.opacity(0.6), radius: 4)
        }
    }

    private func labelColor(for state: State) -> Color {
        switch state {
        case .todo:   return .textDisabled
        case .active: return .accent
        case .done:   return .textPrimary
        }
    }
}

#Preview {
    PipelineStepList(steps: [
        .init(label: "Fetched oEmbed", state: .done, duration: "0.4s"),
        .init(label: "Saved thumbnail", state: .done, duration: "0.2s"),
        .init(label: "Asking Claude…", state: .active, duration: "…"),
        .init(label: "Verify address", state: .todo, duration: nil),
        .init(label: "Geocode", state: .todo, duration: nil)
    ])
    .padding(22)
    .background(Color.bgBase)
}
```

- [ ] **Step 3: Build**

Run build. Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 4: Commit**

```bash
git add l8ter/l8ter/Views/DesignSystem/Components/CardSurface.swift \
        l8ter/l8ter/Views/DesignSystem/Components/PipelineStepList.swift
git commit -m "$(cat <<'EOF'
Add CardSurface and PipelineStepList components

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
EOF
)"
```

---

## Task 9: Lock dark mode + custom tab bar appearance

**Files:**
- Modify: `l8ter/l8ter/l8terApp.swift` (one-line addition + UITabBar appearance)
- Modify: `l8ter/l8ter/ContentView.swift` (custom tab bar tinting)

This task makes every subsequent screen change visible. We force dark
mode and rebrand the tab bar so the custom-styled tabs match the spec
(mono-caps labels, purple accent for active).

- [ ] **Step 1: Edit `l8terApp.swift`**

Replace the body of the `App` (lines 74-79):

```swift
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .tint(Color.accent)
        }
        .modelContainer(container)
    }
```

- [ ] **Step 2: Rewrite `ContentView.swift`**

```swift
import SwiftUI
import SwiftData
import UIKit

/// Root tab bar. Saved items, capture, map, review queue, and debug tools.
/// The tab bar appearance is configured globally to match the design
/// system: dark surface, hairline top border, purple accent for active.
struct ContentView: View {
    @Query(filter: #Predicate<Item> { !$0.isArchived && $0.needsReview })
    private var reviewItems: [Item]

    init() {
        Self.configureTabBarAppearance()
    }

    var body: some View {
        TabView {
            ItemListView()
                .tabItem { Label("Saved", systemImage: "tray.full") }
            CaptureView()
                .tabItem { Label("Add", systemImage: "plus.circle") }
            RestaurantsMapView()
                .tabItem { Label("Map", systemImage: "map") }
            ReviewQueueView()
                .tabItem { Label("Review", systemImage: "exclamationmark.bubble") }
                .badge(reviewItems.count)
            DebugMenuView()
                .tabItem { Label("Debug", systemImage: "wrench.and.screwdriver") }
        }
    }

    private static func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.bgBase)
        appearance.shadowColor = UIColor(Color.borderHairline)

        let active = UIColor(Color.accent)
        let inactive = UIColor(Color.textDisabled)

        for state in [appearance.stackedLayoutAppearance,
                      appearance.inlineLayoutAppearance,
                      appearance.compactInlineLayoutAppearance] {
            state.normal.iconColor = inactive
            state.normal.titleTextAttributes = [.foregroundColor: inactive]
            state.selected.iconColor = active
            state.selected.titleTextAttributes = [.foregroundColor: active]
            state.normal.badgeBackgroundColor = active
            state.selected.badgeBackgroundColor = active
        }

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

/// Phase 1a dev tools, kept accessible while the real app grows.
struct DebugMenuView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink("Settings") { SettingsView() }
                NavigationLink("Manage Categories") { ManageCategoriesView() }
                NavigationLink("oEmbed Test") { OEmbedDebugView() }
                NavigationLink("Extract Test") { ExtractDebugView() }
            }
            .navigationTitle("Debug")
        }
    }
}

#Preview {
    ContentView()
}
```

- [ ] **Step 3: Build**

Run build. Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 4: Commit**

```bash
git add l8ter/l8ter/l8terApp.swift l8ter/l8ter/ContentView.swift
git commit -m "$(cat <<'EOF'
Lock dark mode and apply tab bar appearance

Forces .preferredColorScheme(.dark) for v1 (light mode deferred) and
tints the system tab bar with the design tokens so subsequent screen
work renders against the right shell.

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
EOF
)"
```

---

## Task 10: ItemRowView — media-forward row

**Files:**
- Modify: `l8ter/l8ter/Views/ItemRowView.swift` (full rewrite)

- [ ] **Step 1: Replace the file contents**

```swift
import SwiftUI

/// A single row in the saved items list. 64pt thumbnail + meta label
/// + title + mono subline.
struct ItemRowView: View {
    let item: Item

    var body: some View {
        HStack(alignment: .center, spacing: DSSpace.lg) {
            thumbnail
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: DSRadius.thumbLarge))

            VStack(alignment: .leading, spacing: 3) {
                MetaLabel(
                    text: metaText,
                    pulsing: false,
                    tone: item.needsReview ? .accent : .neutral
                )
                Text(item.title)
                    .font(.dsRowTitle)
                    .tracking(DSTracking.rowTitle)
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)
                if let subline {
                    Text(subline)
                        .font(.dsMetaSmall)
                        .foregroundStyle(Color.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
        .listRowBackground(Color.bgBase)
        .listRowSeparatorTint(Color.borderHairline)
    }

    private var metaText: String {
        let category = (item.builtInCategory?.label ?? item.category).uppercased()
        let formatter = DateFormatter()
        formatter.dateFormat = "MM.dd"
        return "\(category) · \(formatter.string(from: item.dateAdded))"
    }

    private var subline: String? {
        if let r = item.restaurantDetails {
            let parts = [r.cuisine, r.address?.split(separator: ",").first.map(String.init)]
                .compactMap { $0 }
                .map { $0.lowercased().replacingOccurrences(of: " ", with: "-") }
            if !parts.isEmpty { return parts.joined(separator: " · ") }
        }
        if let m = item.movieDetails {
            let parts = [m.director, m.year.map(String.init)]
                .compactMap { $0 }
                .map { $0.lowercased().replacingOccurrences(of: " ", with: "-") }
            if !parts.isEmpty { return parts.joined(separator: " · ") }
        }
        if let s = item.showDetails {
            let parts = [s.creator, s.network]
                .compactMap { $0 }
                .map { $0.lowercased().replacingOccurrences(of: " ", with: "-") }
            if !parts.isEmpty { return parts.joined(separator: " · ") }
        }
        if let summary = item.summary, !summary.isEmpty {
            return summary
        }
        if let author = item.sourceAuthor {
            return "@\(author)"
        }
        return nil
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let path = item.thumbnailPath,
           let url = ThumbnailStore.absoluteURL(for: path),
           let data = try? Data(contentsOf: url),
           let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        } else {
            Rectangle()
                .fill(Color.bgRaised)
                .overlay(
                    Image(systemName: "photo")
                        .foregroundStyle(Color.textDisabled)
                )
        }
    }
}
```

- [ ] **Step 2: Build**

Run build. Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 3: Commit**

```bash
git add l8ter/l8ter/Views/ItemRowView.swift
git commit -m "$(cat <<'EOF'
Restyle ItemRowView with media-forward design

64pt thumbnail, mono caps meta line, single-line title, mono subline
derived from category-specific fields. Drops the per-category color
chip in favor of the unified dark/purple system.

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
EOF
)"
```

---

## Task 11: ItemListView — restyled list shell

**Files:**
- Modify: `l8ter/l8ter/Views/ItemListView.swift` (full rewrite)

- [ ] **Step 1: Replace the file contents**

```swift
import SwiftUI
import SwiftData

/// Main "Saved" view. Lists all non-archived items, newest first.
/// Supports search, category filter, archive/unarchive, delete.
struct ItemListView: View {
    @Environment(\.modelContext) private var context

    @Query(sort: [SortDescriptor(\Item.dateAdded, order: .reverse)])
    private var allItems: [Item]

    @Query(sort: \CustomCategory.name) private var customCategories: [CustomCategory]

    @State private var filterName: String = "all"
    @State private var searchText: String = ""
    @State private var showArchived: Bool = false

    private var options: [CategoryOption] {
        CategoryRegistry.options(customCategories: customCategories)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bgBase.ignoresSafeArea()

                VStack(spacing: 0) {
                    header
                    filterBar
                    Divider().background(Color.borderHairline)
                    contentBody
                }
            }
            .navigationBarHidden(true)
            .searchable(text: $searchText, prompt: "Search title, caption, notes, tags")
        }
    }

    // MARK: - Sections

    private var header: some View {
        HStack(alignment: .lastTextBaseline) {
            Text(showArchived ? "Archived" : "Saved")
                .font(.dsScreenTitle)
                .tracking(DSTracking.screenTitle)
                .foregroundStyle(Color.textPrimary)
            Spacer()
            Text("\(filtered.count) ITEMS")
                .font(.dsMetaCaps)
                .tracking(DSTracking.metaCaps)
                .foregroundStyle(Color.textTertiary)
            Menu {
                Picker("Category", selection: $filterName) {
                    Text("All").tag("all")
                    ForEach(options) { opt in
                        Text(opt.label).tag(opt.name)
                    }
                }
                Divider()
                Toggle("Show archived", isOn: $showArchived)
            } label: {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .padding(.horizontal, DSSpace.xxl)
        .padding(.top, DSSpace.xs)
        .padding(.bottom, DSSpace.lg)
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                FilterPill(label: "all", active: filterName == "all") {
                    filterName = "all"
                }
                ForEach(options) { opt in
                    FilterPill(label: opt.name, active: filterName == opt.name) {
                        filterName = opt.name
                    }
                }
            }
            .padding(.horizontal, DSSpace.xxl)
        }
        .padding(.bottom, DSSpace.lg)
    }

    @ViewBuilder
    private var contentBody: some View {
        if allItems.isEmpty {
            ContentUnavailableView(
                "Nothing saved yet",
                systemImage: "tray",
                description: Text("Paste a TikTok URL on the Add tab to save your first reel.")
            )
            .background(Color.bgBase)
        } else if filtered.isEmpty {
            ContentUnavailableView.search(text: searchText)
                .background(Color.bgBase)
        } else {
            List {
                ForEach(filtered) { item in
                    NavigationLink {
                        ItemDetailView(item: item)
                    } label: {
                        ItemRowView(item: item)
                    }
                    .listRowBackground(Color.bgBase)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) { delete(item) } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        Button { toggleArchive(item) } label: {
                            Label(
                                item.isArchived ? "Unarchive" : "Archive",
                                systemImage: item.isArchived ? "tray.and.arrow.up" : "archivebox"
                            )
                        }
                        .tint(Color.borderQuiet)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.bgBase)
        }
    }

    // MARK: - Filtering (unchanged from prior implementation)

    private var filtered: [Item] {
        let archivedScoped = allItems.filter { $0.isArchived == showArchived }
        let categoryScoped = filterName == "all"
            ? archivedScoped
            : archivedScoped.filter { $0.category == filterName }
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return categoryScoped }
        return categoryScoped.filter { matches($0, query: query) }
    }

    private func matches(_ item: Item, query: String) -> Bool {
        if item.title.lowercased().contains(query) { return true }
        if let caption = item.caption, caption.lowercased().contains(query) { return true }
        if let summary = item.summary, summary.lowercased().contains(query) { return true }
        if let notes = item.notes, notes.lowercased().contains(query) { return true }
        if item.tags.contains(where: { $0.lowercased().contains(query) }) { return true }
        if let author = item.sourceAuthor, author.lowercased().contains(query) { return true }
        if let r = item.restaurantDetails {
            if r.cuisine?.lowercased().contains(query) == true { return true }
            if r.address?.lowercased().contains(query) == true { return true }
            if r.notableDishes.contains(where: { $0.lowercased().contains(query) }) { return true }
        }
        if let m = item.movieDetails {
            if m.director?.lowercased().contains(query) == true { return true }
            if m.genre?.lowercased().contains(query) == true { return true }
        }
        if let s = item.showDetails {
            if s.creator?.lowercased().contains(query) == true { return true }
            if s.network?.lowercased().contains(query) == true { return true }
            if s.genre?.lowercased().contains(query) == true { return true }
        }
        return false
    }

    private func delete(_ item: Item) {
        context.delete(item)
        try? context.save()
    }

    private func toggleArchive(_ item: Item) {
        item.isArchived.toggle()
        try? context.save()
    }
}

private struct FilterPill: View {
    let label: String
    let active: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(label.lowercased())
                .font(.dsMetaSmall)
                .foregroundStyle(active ? Color.accentBright : Color.textSecondary)
                .padding(.horizontal, 11)
                .padding(.vertical, 5)
                .background(active ? Color.accentTint : Color.clear)
                .overlay(
                    Capsule()
                        .strokeBorder(active ? Color.accentBorderSoft : Color.borderQuiet, lineWidth: 0.5)
                )
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ItemListView()
        .modelContainer(for: [Item.self, RestaurantDetails.self, MovieDetails.self, ShowDetails.self, CustomCategory.self], inMemory: true)
}
```

- [ ] **Step 2: Build**

Run build. Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 3: Commit**

```bash
git add l8ter/l8ter/Views/ItemListView.swift
git commit -m "$(cat <<'EOF'
Restyle ItemListView with custom header and filter pills

Custom large title with item count, scrolling mono filter pills,
plain list against bgBase. Filter logic is unchanged.

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
EOF
)"
```

---

## Task 12: ItemDetailView — hero + stacked sections

**Files:**
- Modify: `l8ter/l8ter/Views/ItemDetailView.swift` (full rewrite)

- [ ] **Step 1: Replace the file contents**

```swift
import SwiftUI
import SwiftData
import MapKit

/// Detail view for a saved item. Hero + stacked sections layout.
/// Tags and notes are inline-editable.
struct ItemDetailView: View {
    @Environment(\.modelContext) private var context
    @Bindable var item: Item

    @State private var notesDraft: String = ""

    var body: some View {
        ZStack {
            Color.bgBase.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    hero
                    chipRow
                    sections
                }
            }
            if hasCoordinates {
                VStack {
                    Spacer()
                    bottomActions
                        .padding(.horizontal, DSSpace.xxl)
                        .padding(.bottom, DSSpace.xxl)
                        .background(
                            LinearGradient(
                                colors: [Color.bgBase.opacity(0), Color.bgBase],
                                startPoint: .top, endPoint: .bottom
                            )
                            .ignoresSafeArea(.all, edges: .bottom)
                        )
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.bgBase, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    item.isArchived.toggle()
                    try? context.save()
                } label: {
                    Image(systemName: item.isArchived ? "tray.and.arrow.up" : "archivebox")
                        .foregroundStyle(Color.textSecondary)
                }
            }
        }
        .onAppear { notesDraft = item.notes ?? "" }
    }

    // MARK: - Hero

    private var hero: some View {
        ZStack(alignment: .bottomLeading) {
            heroImage
                .frame(height: 240)
                .frame(maxWidth: .infinity)
                .clipped()
                .overlay(
                    LinearGradient(
                        colors: [Color.clear, Color.bgBase],
                        startPoint: .top, endPoint: .bottom
                    )
                )

            VStack(alignment: .leading, spacing: 6) {
                MetaLabel(
                    text: heroMetaText,
                    pulsing: isNearby,
                    tone: .accent
                )
                Text(item.title)
                    .font(.dsHeroTitle)
                    .tracking(DSTracking.heroTitle)
                    .foregroundStyle(Color.textPrimary)
                    .multilineTextAlignment(.leading)
            }
            .padding(.horizontal, DSSpace.xxl)
            .padding(.bottom, DSSpace.lg)
        }
    }

    @ViewBuilder
    private var heroImage: some View {
        if let path = item.thumbnailPath,
           let url = ThumbnailStore.absoluteURL(for: path),
           let data = try? Data(contentsOf: url),
           let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        } else {
            Rectangle()
                .fill(Color.bgRaised)
        }
    }

    // MARK: - Chip row

    private var chipRow: some View {
        HStack(spacing: 6) {
            Chip(label: (item.builtInCategory?.label ?? item.category).lowercased(), tone: .accent)
            ForEach(item.tags.prefix(4), id: \.self) { tag in
                Chip(label: tag.lowercased())
            }
        }
        .padding(.horizontal, DSSpace.xxl)
        .padding(.top, DSSpace.lg)
    }

    // MARK: - Sections

    @ViewBuilder
    private var sections: some View {
        if let r = item.restaurantDetails {
            section("Address") {
                VStack(alignment: .leading, spacing: 6) {
                    Text(r.address ?? "—")
                        .font(.dsBody)
                        .foregroundStyle(Color.textPrimary)
                    if let hint = addressVerificationHint(for: r) {
                        Text(hint)
                            .font(.dsMetaSmall)
                            .foregroundStyle(Color.textTertiary)
                    }
                    if let lat = r.latitude, let lon = r.longitude {
                        Map(initialPosition: .region(MKCoordinateRegion(
                            center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                            latitudinalMeters: 500, longitudinalMeters: 500
                        ))) {
                            Marker(item.title, coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon))
                                .tint(Color.accent)
                        }
                        .frame(height: 160)
                        .clipShape(RoundedRectangle(cornerRadius: DSRadius.card))
                        .padding(.top, 4)
                    }
                }
            }
            if !r.notableDishes.isEmpty {
                section("Notable") {
                    VStack(spacing: 0) {
                        ForEach(r.notableDishes, id: \.self) { dish in
                            KeyValueRow(key: dish.lowercased().replacingOccurrences(of: " ", with: "-"), value: "★")
                        }
                    }
                }
            }
        }

        if let m = item.movieDetails {
            section("Movie") {
                VStack(spacing: 0) {
                    KeyValueRow(key: "year",      value: m.year.map(String.init))
                    KeyValueRow(key: "director",  value: m.director)
                    KeyValueRow(key: "genre",     value: m.genre)
                    KeyValueRow(key: "watch on",  value: m.whereToWatch)
                }
            }
        }

        if let s = item.showDetails {
            section("Show") {
                VStack(spacing: 0) {
                    KeyValueRow(key: "creator",   value: s.creator)
                    KeyValueRow(key: "network",   value: s.network)
                    KeyValueRow(key: "genre",     value: s.genre)
                    KeyValueRow(key: "watch on",  value: s.whereToWatch)
                }
            }
        }

        if let summary = item.summary, !summary.isEmpty {
            section("Summary") {
                Text(summary)
                    .font(.dsBody)
                    .foregroundStyle(Color.textPrimary)
            }
        }

        section("Tags") {
            TagEditor(tags: $item.tags)
                .onChange(of: item.tags) { _, _ in try? context.save() }
        }

        section("Notes") {
            TextField("Add a note…", text: $notesDraft, axis: .vertical)
                .font(.dsBody)
                .foregroundStyle(Color.textPrimary)
                .lineLimit(3, reservesSpace: true)
                .onChange(of: notesDraft) { _, newValue in
                    item.notes = newValue.isEmpty ? nil : newValue
                    try? context.save()
                }
        }

        section("Source") {
            VStack(alignment: .leading, spacing: 6) {
                if let author = item.sourceAuthor {
                    KeyValueRow(key: "author", value: "@\(author)")
                }
                Link(destination: item.sourceURL) {
                    Text(item.sourceURL.absoluteString)
                        .font(.dsMetaSmall)
                        .foregroundStyle(Color.accent)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
        }

        // Spacer at the bottom so the pinned CTA doesn't cover content.
        if hasCoordinates {
            Color.clear.frame(height: 90)
        } else {
            Color.clear.frame(height: 22)
        }
    }

    @ViewBuilder
    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: DSSpace.sm) {
            Rectangle()
                .fill(Color.borderHairline)
                .frame(height: 0.5)
                .padding(.top, DSSpace.xl)
            VStack(alignment: .leading, spacing: DSSpace.sm) {
                SectionLabel(text: title)
                content()
            }
            .padding(.horizontal, DSSpace.xxl)
            .padding(.top, DSSpace.lg)
        }
    }

    // MARK: - Bottom actions

    private var bottomActions: some View {
        HStack(spacing: DSSpace.md) {
            PrimaryButton(title: "Open in Maps", systemImage: "play.fill") {
                openInMaps()
            }
            GhostButton(title: "↗", systemImage: nil) {
                ShareActivity.share(url: item.sourceURL)
            }
            .frame(width: 56)
        }
    }

    // MARK: - Helpers

    private var hasCoordinates: Bool {
        item.restaurantDetails?.latitude != nil && item.restaurantDetails?.longitude != nil
    }

    private var isNearby: Bool {
        // Reserved for future live-distance hookup. Off in v1.
        false
    }

    private var heroMetaText: String {
        let category = (item.builtInCategory?.label ?? item.category).uppercased()
        let formatter = DateFormatter()
        formatter.dateFormat = "MM.dd"
        return "\(category) · \(formatter.string(from: item.dateAdded))"
    }

    private func addressVerificationHint(for r: RestaurantDetails) -> String? {
        switch r.addressSource {
        case .web:          return "verified · web search ✓"
        case .webCorrected: return "updated · web search ✓"
        case .post, .none:  return nil
        }
    }

    private func openInMaps() {
        guard let lat = item.restaurantDetails?.latitude,
              let lon = item.restaurantDetails?.longitude else { return }
        let coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coord))
        mapItem.name = item.title
        mapItem.openInMaps()
    }
}

/// Tiny wrapper for sharing a URL via UIActivityViewController.
enum ShareActivity {
    static func share(url: URL) {
        let av = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else { return }
        var top = root
        while let presented = top.presentedViewController { top = presented }
        top.present(av, animated: true)
    }
}
```

- [ ] **Step 2: Build**

Run build. Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 3: Commit**

```bash
git add l8ter/l8ter/Views/ItemDetailView.swift
git commit -m "$(cat <<'EOF'
Rewrite ItemDetailView with hero + stacked sections layout

240pt atmospheric hero that dissolves into bgBase, chip row, hairline
sections (Address, Notable, Movie, Show, Tags, Notes, Source), pinned
"Open in Maps" CTA for restaurants with coordinates.

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
EOF
)"
```

---

## Task 13: TagEditor — restyle chips

**Files:**
- Modify: `l8ter/l8ter/Views/TagEditor.swift` (replace chip rendering only — `FlowLayout` is untouched)

- [ ] **Step 1: Replace the `body` of `TagEditor` (lines 6-42)**

Open `l8ter/l8ter/Views/TagEditor.swift` and replace the entire `TagEditor` struct (keeping the `FlowLayout` struct below it unchanged):

```swift
struct TagEditor: View {
    @Binding var tags: [String]

    @State private var draft: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpace.sm) {
            if !tags.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(tags, id: \.self) { tag in
                        Button {
                            remove(tag)
                        } label: {
                            HStack(spacing: 4) {
                                Text(tag.lowercased())
                                    .font(.dsMetaSmall)
                                    .foregroundStyle(Color.textSecondary)
                                Image(systemName: "xmark")
                                    .font(.system(size: 8, weight: .semibold))
                                    .foregroundStyle(Color.textTertiary)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .overlay(
                                RoundedRectangle(cornerRadius: DSRadius.chip)
                                    .strokeBorder(Color.borderQuiet, lineWidth: 0.5)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            TextField("add tag", text: $draft)
                .font(.dsMetaSmall)
                .foregroundStyle(Color.textPrimary)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .onSubmit(commitDraft)
                .onChange(of: draft) { _, newValue in
                    if newValue.hasSuffix(",") {
                        draft = String(newValue.dropLast())
                        commitDraft()
                    }
                }
        }
    }

    private func commitDraft() {
        let tag = draft.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !tag.isEmpty, !tags.contains(tag) else {
            draft = ""
            return
        }
        tags.append(tag)
        draft = ""
    }

    private func remove(_ tag: String) {
        tags.removeAll { $0 == tag }
    }
}
```

- [ ] **Step 2: Build**

Run build. Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 3: Commit**

```bash
git add l8ter/l8ter/Views/TagEditor.swift
git commit -m "$(cat <<'EOF'
Restyle TagEditor chips to match design system

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
EOF
)"
```

---

## Task 14: RestaurantsMapView — glyph pins + selection sheet

**Files:**
- Modify: `l8ter/l8ter/Views/RestaurantsMapView.swift` (full rewrite)

- [ ] **Step 1: Replace the file contents**

```swift
import SwiftUI
import SwiftData
import MapKit

/// Map of all geocoded restaurants. Glyph pins (mono-cap labels) +
/// floating header chip + bottom selection card.
struct RestaurantsMapView: View {
    @Query(
        filter: #Predicate<Item> { !$0.isArchived },
        sort: [SortDescriptor(\Item.dateAdded, order: .reverse)]
    )
    private var items: [Item]

    @State private var selectedItemID: UUID?
    @State private var cameraPosition: MapCameraPosition = .automatic

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                if geocodedItems.isEmpty {
                    Color.bgBase.ignoresSafeArea()
                    ContentUnavailableView(
                        "No restaurants yet",
                        systemImage: "mappin.slash",
                        description: Text("Save a restaurant reel with an address and it shows up here.")
                    )
                } else {
                    mapView
                    floatingHeader
                        .padding(.horizontal, DSSpace.xl)
                        .padding(.top, DSSpace.lg)
                }
            }
            .navigationBarHidden(true)
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }

    private var mapView: some View {
        Map(position: $cameraPosition, selection: $selectedItemID) {
            ForEach(geocodedItems) { item in
                if let coord = coordinate(for: item) {
                    Annotation(item.title, coordinate: coord) {
                        pinView(for: item)
                    }
                    .tag(item.id)
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .preferredColorScheme(.dark)
        .safeAreaInset(edge: .bottom) {
            if let selected {
                selectionCard(for: selected)
                    .padding(.horizontal, DSSpace.xxl)
                    .padding(.bottom, DSSpace.md)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.default, value: selectedItemID)
    }

    @ViewBuilder
    private func pinView(for item: Item) -> some View {
        let isSelected = item.id == selectedItemID
        VStack(spacing: 3) {
            ZStack {
                if isSelected {
                    Circle()
                        .fill(Color.accentTintStrong)
                        .frame(width: 34, height: 34)
                }
                Circle()
                    .fill(isSelected ? Color.accent : Color.textPrimary)
                    .frame(width: isSelected ? 16 : 10, height: isSelected ? 16 : 10)
                    .overlay(
                        Circle().strokeBorder(Color.bgBase, lineWidth: 2)
                    )
                    .shadow(color: isSelected ? Color.accent.opacity(0.6) : .clear, radius: 8)
            }
            Text(item.title.uppercased().prefix(12))
                .font(.dsMetaTiny)
                .tracking(DSTracking.metaTiny)
                .foregroundStyle(isSelected ? Color.accent : Color.textSecondary)
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(Color.bgBase.opacity(0.7))
                .clipShape(RoundedRectangle(cornerRadius: 3))
        }
    }

    private var floatingHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                MetaLabel(text: "NEAR YOU · \(geocodedItems.count) SAVED", pulsing: true, tone: .accent)
                Text("Map")
                    .font(.dsScreenTitle)
                    .tracking(DSTracking.screenTitle)
                    .foregroundStyle(Color.textPrimary)
            }
            Spacer()
            Button {
                cameraPosition = .automatic
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "scope")
                        .font(.system(size: 11, weight: .semibold))
                    Text("RECENTER")
                        .font(.dsMetaCaps)
                        .tracking(DSTracking.metaCaps)
                }
                .foregroundStyle(Color.textSecondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.bgBase.opacity(0.85))
                .overlay(
                    Capsule().strokeBorder(Color.borderQuiet, lineWidth: 0.5)
                )
                .clipShape(Capsule())
            }
        }
    }

    @ViewBuilder
    private func selectionCard(for item: Item) -> some View {
        VStack(alignment: .leading, spacing: DSSpace.sm) {
            MetaLabel(text: metaText(for: item), pulsing: false, tone: .accent)
            Text(item.title)
                .font(.dsCardTitle)
                .tracking(DSTracking.cardTitle)
                .foregroundStyle(Color.textPrimary)
                .lineLimit(1)
            if let address = item.restaurantDetails?.address {
                Text(address.lowercased())
                    .font(.dsMetaSmall)
                    .foregroundStyle(Color.textSecondary)
                    .lineLimit(1)
            }
            HStack(spacing: DSSpace.md) {
                PrimaryButton(title: "Open in Maps", systemImage: "play.fill") {
                    openInMaps(item: item)
                }
                NavigationLink {
                    ItemDetailView(item: item)
                } label: {
                    Text("Details")
                        .font(.system(size: 14, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .foregroundStyle(Color.textPrimary)
                        .overlay(
                            RoundedRectangle(cornerRadius: DSRadius.button)
                                .strokeBorder(Color.borderQuiet, lineWidth: 0.5)
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 4)
        }
        .padding(DSSpace.xl)
        .background(Color.bgBase)
        .overlay(
            RoundedRectangle(cornerRadius: DSRadius.card)
                .strokeBorder(Color.borderHairline, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: DSRadius.card))
    }

    // MARK: - Data helpers

    private var geocodedItems: [Item] {
        items.filter { coordinate(for: $0) != nil && $0.isRestaurant }
    }

    private var selected: Item? {
        guard let id = selectedItemID else { return nil }
        return items.first { $0.id == id }
    }

    private func coordinate(for item: Item) -> CLLocationCoordinate2D? {
        guard let lat = item.restaurantDetails?.latitude,
              let lon = item.restaurantDetails?.longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    private func metaText(for item: Item) -> String {
        let category = (item.builtInCategory?.label ?? item.category).uppercased()
        return "\(category) · SAVED"
    }

    private func openInMaps(item: Item) {
        guard let coord = coordinate(for: item) else { return }
        let placemark = MKPlacemark(coordinate: coord)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = item.title
        mapItem.openInMaps()
    }
}

#Preview {
    RestaurantsMapView()
        .modelContainer(for: [Item.self, RestaurantDetails.self, MovieDetails.self, ShowDetails.self, CustomCategory.self], inMemory: true)
}
```

- [ ] **Step 2: Build**

Run build. Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 3: Commit**

```bash
git add l8ter/l8ter/Views/RestaurantsMapView.swift
git commit -m "$(cat <<'EOF'
Restyle RestaurantsMapView with glyph pins + floating header

Custom annotation pins (10pt dot + mono caps label below; 16pt accent
dot with halo when selected), floating chip header, hairline-bordered
bottom selection card with Primary CTA + Details link. Filters to
restaurants only.

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
EOF
)"
```

---

## Task 15: CaptureView — three-state flow with pipeline steps

**Files:**
- Modify: `l8ter/l8ter/Views/CaptureView.swift` (full rewrite)

The pipeline-step UI requires more granular state than the current
single `Status` enum carries. We replace it with a `CaptureProgress`
state that tracks each step's status independently. No business logic
in `ItemSaver` changes; this is internal to `CaptureView`.

- [ ] **Step 1: Replace the file contents**

```swift
import SwiftUI
import SwiftData

/// Paste-URL capture screen. Three states: idle → processing → saved.
struct CaptureView: View {
    @Environment(\.modelContext) private var context

    @State private var reelURL: String = ""
    @State private var phase: Phase = .idle
    @State private var progress = CaptureProgress()
    @State private var savedItem: SavedItemSnapshot?
    @State private var errorMessage: String?

    enum Phase {
        case idle
        case processing
        case saved
        case failed
    }

    /// Lightweight snapshot used to render the success card without
    /// holding a SwiftData reference across the async boundary.
    struct SavedItemSnapshot {
        let title: String
        let category: String
        let confidence: Double
        let thumbnailPath: String?
        let itemID: UUID
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bgBase.ignoresSafeArea()
                content
            }
            .navigationBarHidden(true)
        }
    }

    @ViewBuilder
    private var content: some View {
        VStack(alignment: .leading, spacing: DSSpace.xl) {
            header

            switch phase {
            case .idle:
                idleBody
            case .processing:
                processingBody
            case .saved:
                savedBody
            case .failed:
                failedBody
            }

            Spacer()

            footer
        }
        .padding(.horizontal, DSSpace.xxl)
        .padding(.top, DSSpace.lg)
        .padding(.bottom, DSSpace.xxl)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            MetaLabel(text: phaseLabel, pulsing: phase == .processing, tone: phase == .idle ? .neutral : .accent)
            Text(phaseTitle)
                .font(.dsScreenTitle)
                .tracking(DSTracking.screenTitle)
                .foregroundStyle(Color.textPrimary)
        }
    }

    // MARK: - Idle

    private var idleBody: some View {
        VStack(alignment: .leading, spacing: DSSpace.xl) {
            inputCard

            Text("Tap the share icon on any TikTok and copy the link. Paste it above.\n\nInstagram coming after Phase 4.5.")
                .font(.dsMetaSmall)
                .foregroundStyle(Color.textTertiary)
                .lineSpacing(4)
        }
    }

    private var inputCard: some View {
        CardSurface(elevation: .raised) {
            VStack(alignment: .leading, spacing: 6) {
                SectionLabel(text: "Paste URL")
                TextField("tiktok.com/@user/video/...", text: $reelURL)
                    .font(.dsBody)
                    .foregroundStyle(Color.textPrimary)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }

    // MARK: - Processing

    private var processingBody: some View {
        VStack(alignment: .leading, spacing: DSSpace.xl) {
            CardSurface(elevation: .raised) {
                VStack(alignment: .leading, spacing: 6) {
                    SectionLabel(text: "Source")
                    Text(reelURL.isEmpty ? "—" : reelURL)
                        .font(.dsMetaSmall)
                        .foregroundStyle(Color.textPrimary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .opacity(0.6)

            PipelineStepList(steps: progress.stepsForUI)
        }
    }

    // MARK: - Saved

    @ViewBuilder
    private var savedBody: some View {
        if let saved = savedItem {
            VStack(alignment: .leading, spacing: DSSpace.lg) {
                HStack(spacing: DSSpace.lg) {
                    Group {
                        if let path = saved.thumbnailPath,
                           let url = ThumbnailStore.absoluteURL(for: path),
                           let data = try? Data(contentsOf: url),
                           let image = UIImage(data: data) {
                            Image(uiImage: image).resizable().scaledToFill()
                        } else {
                            Rectangle().fill(Color.bgRaised)
                        }
                    }
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: DSRadius.thumbLarge))

                    VStack(alignment: .leading, spacing: 3) {
                        MetaLabel(text: saved.category.uppercased(), tone: .accent)
                        Text(saved.title)
                            .font(.dsRowTitle)
                            .tracking(DSTracking.rowTitle)
                            .foregroundStyle(Color.textPrimary)
                            .lineLimit(2)
                    }
                    Spacer()
                }

                CardSurface(elevation: .raised) {
                    VStack(alignment: .leading, spacing: DSSpace.sm) {
                        SectionLabel(text: "Confidence")
                        HStack(spacing: DSSpace.md) {
                            ConfidenceBar(value: saved.confidence, width: 220)
                            Spacer()
                            Text(String(format: "%.2f", saved.confidence))
                                .font(.dsMetaSmall)
                                .foregroundStyle(Color.accent)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                }
            }
        }
    }

    // MARK: - Failed

    private var failedBody: some View {
        CardSurface(elevation: .raised) {
            VStack(alignment: .leading, spacing: 6) {
                SectionLabel(text: "Error")
                Text(errorMessage ?? "Unknown error")
                    .font(.dsMetaSmall)
                    .foregroundStyle(Color.accent)
                    .textSelection(.enabled)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }

    // MARK: - Footer (CTA)

    @ViewBuilder
    private var footer: some View {
        switch phase {
        case .idle:
            PrimaryButton(title: "Save", disabled: reelURL.isEmpty) {
                Task { await run() }
            }
        case .processing:
            EmptyView()
        case .saved:
            HStack(spacing: DSSpace.md) {
                GhostButton(title: "Add another") {
                    reset()
                }
                PrimaryButton(title: "View →") {
                    // Navigation to detail is left to the user via the
                    // Saved tab; deeplinking from here would require
                    // wiring up a NavigationPath. v1 just resets.
                    reset()
                }
            }
        case .failed:
            HStack(spacing: DSSpace.md) {
                GhostButton(title: "Reset") { reset() }
                PrimaryButton(title: "Try again") {
                    Task { await run() }
                }
            }
        }
    }

    // MARK: - Pipeline

    private func run() async {
        let url = reelURL
        guard !url.isEmpty else { return }
        phase = .processing
        progress = CaptureProgress()
        savedItem = nil
        errorMessage = nil

        do {
            progress.start(.fetchOEmbed)
            let fetch = try await TikTokOEmbed.fetch(reelURL: url)
            progress.complete(.fetchOEmbed)

            // Thumbnail download happens inside ItemSaver later; we just
            // mark this step as done after extraction starts to keep the
            // UI honest without changing the saver's API.
            progress.complete(.saveThumbnail)

            progress.start(.askingClaude)
            let customs = (try? context.fetch(FetchDescriptor<CustomCategory>())) ?? []
            let options = CategoryRegistry.options(customCategories: customs)
            let extraction = try await ClaudeExtractor.extract(
                oEmbed: fetch.response,
                sourceURL: url,
                platform: "tiktok",
                categoryOptions: options
            )
            progress.complete(.askingClaude)

            if extraction.category == BuiltInCategory.restaurant.rawValue {
                progress.start(.verifyAddress)
            } else {
                progress.start(.lookupMetadata)
            }

            try await ItemSaver.save(
                extraction: extraction,
                oEmbed: fetch.response,
                sourceURL: url,
                context: context
            )
            if extraction.category == BuiltInCategory.restaurant.rawValue {
                progress.complete(.verifyAddress)
                progress.start(.geocode)
                progress.complete(.geocode)
            } else {
                progress.complete(.lookupMetadata)
            }

            // Pull a snapshot for the success card.
            savedItem = SavedItemSnapshot(
                title: extraction.title,
                category: extraction.category,
                confidence: extraction.confidence,
                thumbnailPath: nil,
                itemID: UUID()
            )
            reelURL = ""
            phase = .saved
        } catch {
            errorMessage = "\(error)"
            phase = .failed
        }
    }

    private func reset() {
        phase = .idle
        progress = CaptureProgress()
        savedItem = nil
        errorMessage = nil
    }

    // MARK: - Phase labels

    private var phaseLabel: String {
        switch phase {
        case .idle:       return "01 · IDLE"
        case .processing: return "02 · PROCESSING"
        case .saved:      return "03 · SAVED"
        case .failed:     return "!! · FAILED"
        }
    }

    private var phaseTitle: String {
        switch phase {
        case .idle:       return "Add"
        case .processing: return "Saving…"
        case .saved:      return "Got it."
        case .failed:     return "Hmm."
        }
    }
}

/// Tracks the per-step state of a save run for the UI.
struct CaptureProgress {
    enum Step: CaseIterable {
        case fetchOEmbed
        case saveThumbnail
        case askingClaude
        case verifyAddress
        case lookupMetadata
        case geocode

        var label: String {
            switch self {
            case .fetchOEmbed:    return "Fetched oEmbed"
            case .saveThumbnail:  return "Saved thumbnail"
            case .askingClaude:   return "Asking Claude"
            case .verifyAddress:  return "Verify address"
            case .lookupMetadata: return "Lookup metadata"
            case .geocode:        return "Geocode"
            }
        }
    }

    private var states: [Step: PipelineStepList.State] = [:]
    private var startTimes: [Step: Date] = [:]
    private var durations: [Step: TimeInterval] = [:]

    var stepsForUI: [PipelineStepList.Step] {
        // Order shown in the UI mirrors the pipeline order. Steps that
        // are irrelevant (e.g., verifyAddress for a movie save) simply
        // stay in `.todo` and render greyed.
        let ordered: [Step] = [.fetchOEmbed, .saveThumbnail, .askingClaude, .verifyAddress, .geocode]
        return ordered.map { step in
            let state = states[step] ?? .todo
            let duration = durations[step].map { String(format: "%.1fs", $0) }
            return PipelineStepList.Step(
                label: step.label,
                state: state,
                duration: state == .active ? "…" : duration
            )
        }
    }

    mutating func start(_ step: Step) {
        states[step] = .active
        startTimes[step] = Date()
    }

    mutating func complete(_ step: Step) {
        states[step] = .done
        if let started = startTimes[step] {
            durations[step] = Date().timeIntervalSince(started)
        }
    }
}

#Preview {
    CaptureView()
        .modelContainer(for: [Item.self, RestaurantDetails.self, MovieDetails.self, ShowDetails.self, CustomCategory.self], inMemory: true)
}
```

- [ ] **Step 2: Build**

Run build. Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 3: Commit**

```bash
git add l8ter/l8ter/Views/CaptureView.swift
git commit -m "$(cat <<'EOF'
Rewrite CaptureView with three-state flow

Idle / processing / saved / failed phases with a CaptureProgress
struct that drives the new PipelineStepList. Save logic and
ItemSaver are unchanged; the new state is internal to the view.

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
EOF
)"
```

---

## Task 16: ReviewQueueView — confidence-bar list

**Files:**
- Modify: `l8ter/l8ter/Views/ReviewQueueView.swift` (full rewrite)

- [ ] **Step 1: Replace the file contents**

```swift
import SwiftUI
import SwiftData

/// Items the AI flagged for human review: low confidence or
/// uncategorized. Rows show a compact 48pt thumbnail + meta + title +
/// confidence bar.
struct ReviewQueueView: View {
    @Query(
        filter: #Predicate<Item> { !$0.isArchived && $0.needsReview },
        sort: [SortDescriptor(\Item.dateAdded, order: .reverse)]
    )
    private var items: [Item]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bgBase.ignoresSafeArea()
                if items.isEmpty {
                    ContentUnavailableView(
                        "Nothing to review",
                        systemImage: "checkmark.seal",
                        description: Text("Items land here when the AI isn't sure. You're all caught up.")
                    )
                } else {
                    VStack(alignment: .leading, spacing: 0) {
                        header
                        helper
                        Divider().background(Color.borderHairline)
                        list
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }

    private var header: some View {
        HStack(alignment: .lastTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                SectionLabel(text: "Needs cleanup")
                Text("Review")
                    .font(.dsScreenTitle)
                    .tracking(DSTracking.screenTitle)
                    .foregroundStyle(Color.textPrimary)
            }
            Spacer()
            Text("\(items.count) ITEMS")
                .font(.dsMetaCaps)
                .tracking(DSTracking.metaCaps)
                .foregroundStyle(Color.accent)
        }
        .padding(.horizontal, DSSpace.xxl)
        .padding(.top, DSSpace.xs)
    }

    private var helper: some View {
        Text("Items where Claude wasn't sure. Edit and clear, or skip.")
            .font(.dsMetaSmall)
            .foregroundStyle(Color.textTertiary)
            .padding(.horizontal, DSSpace.xxl)
            .padding(.top, DSSpace.sm)
            .padding(.bottom, DSSpace.lg)
    }

    private var list: some View {
        List {
            ForEach(items) { item in
                NavigationLink {
                    ReviewItemEditView(item: item)
                } label: {
                    row(for: item)
                }
                .listRowBackground(Color.bgBase)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.bgBase)
    }

    @ViewBuilder
    private func row(for item: Item) -> some View {
        HStack(alignment: .center, spacing: DSSpace.lg) {
            thumbnail(for: item)
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: DSRadius.thumb))

            VStack(alignment: .leading, spacing: 4) {
                MetaLabel(
                    text: rowMeta(for: item),
                    tone: item.category == BuiltInCategory.uncategorized.rawValue ? .accent : .neutral
                )
                Text(item.title.isEmpty ? "Untitled" : item.title)
                    .font(.dsRowTitle)
                    .tracking(DSTracking.rowTitle)
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)
                HStack(spacing: 8) {
                    ConfidenceBar(value: item.aiConfidence, width: 60)
                    Text(String(format: "%.2f", item.aiConfidence))
                        .font(.dsMetaSmall)
                        .foregroundStyle(Color.accent)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
    }

    private func rowMeta(for item: Item) -> String {
        let category = (item.builtInCategory?.label ?? item.category).uppercased()
        let formatter = DateFormatter()
        formatter.dateFormat = "MM.dd"
        return "\(category) · \(formatter.string(from: item.dateAdded))"
    }

    @ViewBuilder
    private func thumbnail(for item: Item) -> some View {
        if let path = item.thumbnailPath,
           let url = ThumbnailStore.absoluteURL(for: path),
           let data = try? Data(contentsOf: url),
           let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        } else {
            Rectangle()
                .fill(Color.bgRaised)
                .overlay(
                    Image(systemName: "photo")
                        .foregroundStyle(Color.textDisabled)
                )
        }
    }
}

#Preview {
    ReviewQueueView()
        .modelContainer(for: [Item.self, RestaurantDetails.self, MovieDetails.self, ShowDetails.self, CustomCategory.self], inMemory: true)
}
```

- [ ] **Step 2: Build**

Run build. Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 3: Commit**

```bash
git add l8ter/l8ter/Views/ReviewQueueView.swift
git commit -m "$(cat <<'EOF'
Restyle ReviewQueueView with confidence-bar rows

Custom header with mono "NEEDS CLEANUP" eyebrow, helper subline, and
list rows that surface confidence as a tiny purple bar + numeric.

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
EOF
)"
```

---

## Task 17: ReviewItemEditView — restyled form

**Files:**
- Modify: `l8ter/l8ter/Views/ReviewItemEditView.swift` (cosmetic-only — wraps the existing `Form` in styling, retains all logic)

- [ ] **Step 1: Replace the `body` of `ReviewItemEditView` (lines 42-120)**

Open the file and replace ONLY the `body` computed property (keep all `@State`, `@Query`, `load()`, `save()`, `detachDetails()`, `nilIfEmpty()`, `rerunExtraction()` unchanged).

Replace this block:

```swift
    var body: some View {
        Form {
            Section("Basics") {
```

…through the closing `.onAppear(perform: load)` (line 119) with:

```swift
    var body: some View {
        ZStack {
            Color.bgBase.ignoresSafeArea()
            Form {
                Section {
                    TextField("Title", text: $title)
                        .font(.dsBody)
                    Picker("Category", selection: $category) {
                        ForEach(options) { opt in
                            Text(opt.label).tag(opt.name)
                        }
                    }
                } header: {
                    SectionLabel(text: "Basics")
                }

                if let builtIn = BuiltInCategory(rawValue: category) {
                    switch builtIn {
                    case .restaurant:
                        Section {
                            TextField("Address", text: $restaurantAddress, axis: .vertical)
                            TextField("Cuisine", text: $restaurantCuisine)
                            TextField("Notable dishes (comma-separated)", text: $restaurantDishes, axis: .vertical)
                        } header: { SectionLabel(text: "Restaurant") }
                    case .movie:
                        Section {
                            TextField("Year", text: $movieYear)
                                .keyboardType(.numberPad)
                            TextField("Director", text: $movieDirector)
                            TextField("Genre", text: $movieGenre)
                            TextField("Where to watch", text: $movieWhereToWatch)
                        } header: { SectionLabel(text: "Movie") }
                    case .show:
                        Section {
                            TextField("Creator", text: $showCreator)
                            TextField("Network", text: $showNetwork)
                            TextField("Genre", text: $showGenre)
                            TextField("Where to watch", text: $showWhereToWatch)
                        } header: { SectionLabel(text: "Show") }
                    case .activity, .recipe, .place, .book, .product, .uncategorized:
                        Section {
                            TextField("Short description", text: $summary, axis: .vertical)
                                .lineLimit(3, reservesSpace: true)
                        } header: { SectionLabel(text: "Summary") }
                    }
                } else {
                    Section {
                        TextField("Short description", text: $summary, axis: .vertical)
                            .lineLimit(3, reservesSpace: true)
                    } header: { SectionLabel(text: "Summary") }
                }

                Section {
                    Button {
                        Task { await rerunExtraction() }
                    } label: {
                        if isRerunning {
                            HStack { ProgressView().tint(Color.accent); Text("Re-running…") }
                        } else {
                            Label("Re-run extraction", systemImage: "arrow.clockwise")
                                .foregroundStyle(Color.accent)
                        }
                    }
                    .disabled(isRerunning)

                    if let rerunError {
                        Text(rerunError)
                            .font(.dsMetaSmall)
                            .foregroundStyle(Color.accent)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.bgBase)
        }
        .navigationTitle("Edit")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.bgBase, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    save(clearingReview: true)
                    dismiss()
                }
                .foregroundStyle(Color.accent)
            }
        }
        .onAppear(perform: load)
    }
```

- [ ] **Step 2: Build**

Run build. Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 3: Commit**

```bash
git add l8ter/l8ter/Views/ReviewItemEditView.swift
git commit -m "$(cat <<'EOF'
Restyle ReviewItemEditView with design system

Form sections use SectionLabel headers, accent purple toolbar/button
tints, and the dark surface tokens. No logic changes.

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
EOF
)"
```

---

## Task 18: SettingsView — restyled

**Files:**
- Modify: `l8ter/l8ter/Views/SettingsView.swift` (full rewrite)

- [ ] **Step 1: Replace the file contents**

```swift
import SwiftUI

/// Settings: Claude API key + proximity alerts toggle.
struct SettingsView: View {
    @State private var apiKey: String = ""
    @State private var statusMessage: String?
    @State private var isError: Bool = false
    @State private var proximityEnabled: Bool = ProximityManager.shared.isEnabled

    var body: some View {
        ZStack {
            Color.bgBase.ignoresSafeArea()
            Form {
                Section {
                    SecureField("sk-ant-...", text: $apiKey)
                        .font(.dsBody)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    HStack {
                        Button("Save") { save() }
                            .disabled(apiKey.isEmpty)
                            .foregroundStyle(Color.accent)
                        Spacer()
                        Button("Clear", role: .destructive) { clear() }
                    }
                } header: {
                    SectionLabel(text: "Claude API")
                } footer: {
                    Text("Stored in iOS Keychain. Used for categorization and extraction.")
                        .font(.dsMetaSmall)
                        .foregroundStyle(Color.textTertiary)
                }

                Section {
                    Toggle("Alerts when nearby", isOn: $proximityEnabled)
                        .tint(Color.accent)
                        .onChange(of: proximityEnabled) { _, newValue in
                            Task { await toggleProximity(newValue) }
                        }
                } header: {
                    SectionLabel(text: "Proximity")
                } footer: {
                    Text("Get a local notification when you're within 150m of a saved restaurant. Uses low-power region monitoring; no continuous GPS.")
                        .font(.dsMetaSmall)
                        .foregroundStyle(Color.textTertiary)
                }

                if let statusMessage {
                    Section {
                        Text(statusMessage)
                            .font(.dsMetaSmall)
                            .foregroundStyle(isError ? Color.accent : Color.accentBright)
                    }
                }

                Section {
                    Text("L8TER · v0.7.0")
                        .font(.dsMetaTiny)
                        .tracking(DSTracking.metaTiny)
                        .foregroundStyle(Color.textDisabled)
                }
                .listRowBackground(Color.bgBase)
            }
            .scrollContentBackground(.hidden)
            .background(Color.bgBase)
        }
        .navigationTitle("Settings")
        .toolbarBackground(Color.bgBase, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear(perform: loadExisting)
    }

    private func toggleProximity(_ enabled: Bool) async {
        if enabled { await ProximityManager.shared.enable() }
        else       { ProximityManager.shared.disable() }
    }

    private func loadExisting() {
        do {
            if let existing = try KeychainStore.load(KeychainStore.claudeAPIKeyAccount) {
                apiKey = existing
            }
        } catch {
            show("Failed to load: \(error)", isError: true)
        }
    }

    private func save() {
        do {
            try KeychainStore.save(apiKey, for: KeychainStore.claudeAPIKeyAccount)
            show("Saved.", isError: false)
        } catch {
            show("Save failed: \(error)", isError: true)
        }
    }

    private func clear() {
        do {
            try KeychainStore.delete(KeychainStore.claudeAPIKeyAccount)
            apiKey = ""
            show("Cleared.", isError: false)
        } catch {
            show("Clear failed: \(error)", isError: true)
        }
    }

    private func show(_ message: String, isError: Bool) {
        self.statusMessage = message
        self.isError = isError
    }
}

#Preview {
    NavigationStack { SettingsView() }
}
```

- [ ] **Step 2: Build**

Run build. Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 3: Commit**

```bash
git add l8ter/l8ter/Views/SettingsView.swift
git commit -m "$(cat <<'EOF'
Restyle SettingsView with design system

Section labels in mono caps, accent toggle tint, mono footer, app
version footer in textDisabled mono.

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
EOF
)"
```

---

## Task 19: ManageCategoriesView — restyled

**Files:**
- Modify: `l8ter/l8ter/Views/ManageCategoriesView.swift` (cosmetic-only)

- [ ] **Step 1: Replace `ManageCategoriesView.body` (lines 12-73)**

Replace the `body` of `ManageCategoriesView` (keeping `delete()` unchanged) with:

```swift
    var body: some View {
        ZStack {
            Color.bgBase.ignoresSafeArea()
            List {
                Section {
                    ForEach(BuiltInCategory.allCases, id: \.self) { cat in
                        HStack(alignment: .top, spacing: DSSpace.sm) {
                            VStack(alignment: .leading, spacing: 3) {
                                HStack(spacing: 8) {
                                    Text(cat.label)
                                        .font(.dsBody)
                                        .foregroundStyle(Color.textPrimary)
                                    if cat == .restaurant || cat == .movie || cat == .show {
                                        Text(cat.rawValue.uppercased())
                                            .font(.dsMetaTiny)
                                            .tracking(DSTracking.metaTiny)
                                            .foregroundStyle(Color.accent)
                                    }
                                }
                                Text(cat.defaultDescription)
                                    .font(.dsMetaSmall)
                                    .foregroundStyle(Color.textSecondary)
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(.vertical, 4)
                        .listRowBackground(Color.bgBase)
                    }
                } header: {
                    SectionLabel(text: "Built-in (\(BuiltInCategory.allCases.count))")
                } footer: {
                    Text("Built-in categories can't be edited or removed.")
                        .font(.dsMetaSmall)
                        .foregroundStyle(Color.textTertiary)
                }

                Section {
                    if customCategories.isEmpty {
                        Text("None yet. Tap + to create one.")
                            .font(.dsMetaSmall)
                            .foregroundStyle(Color.textTertiary)
                            .listRowBackground(Color.bgBase)
                    } else {
                        ForEach(customCategories) { cat in
                            NavigationLink {
                                CategoryEditView(category: cat)
                            } label: {
                                VStack(alignment: .leading, spacing: 3) {
                                    HStack(spacing: 8) {
                                        Text(cat.name.capitalized)
                                            .font(.dsBody)
                                            .foregroundStyle(Color.textPrimary)
                                        Chip(label: "custom", tone: .accent)
                                    }
                                    Text(cat.prompt)
                                        .font(.dsMetaSmall)
                                        .foregroundStyle(Color.textSecondary)
                                        .lineLimit(2)
                                }
                                .padding(.vertical, 4)
                            }
                            .listRowBackground(Color.bgBase)
                        }
                        .onDelete(perform: delete)
                    }
                } header: {
                    SectionLabel(text: "Custom (\(customCategories.count))")
                } footer: {
                    Text("The description teaches Claude when to pick this category.")
                        .font(.dsMetaSmall)
                        .foregroundStyle(Color.textTertiary)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.bgBase)
        }
        .navigationTitle("Categories")
        .toolbarBackground(Color.bgBase, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingNew = true
                } label: {
                    Text("+ ADD")
                        .font(.dsMetaCaps)
                        .tracking(DSTracking.metaCaps)
                        .foregroundStyle(Color.accent)
                }
            }
        }
        .sheet(isPresented: $showingNew) {
            NavigationStack { CategoryEditView(category: nil) }
        }
    }
```

- [ ] **Step 2: Replace `CategoryEditView.body` (lines 95-137)**

Replace the `body` of `CategoryEditView` (keeping `load()` and `save()` unchanged) with:

```swift
    var body: some View {
        ZStack {
            Color.bgBase.ignoresSafeArea()
            Form {
                Section {
                    TextField("Name", text: $name)
                        .font(.dsBody)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                } footer: {
                    Text("Short, lowercase, one or two words.")
                        .font(.dsMetaSmall)
                        .foregroundStyle(Color.textTertiary)
                }

                Section {
                    TextField("Description", text: $prompt, axis: .vertical)
                        .font(.dsBody)
                        .lineLimit(4, reservesSpace: true)
                } header: {
                    SectionLabel(text: "Description")
                } footer: {
                    Text("Tell Claude when to pick this category. Example: 'A specific coffee shop I want to try — espresso bars, roasters, pour-over spots. Not general food content.'")
                        .font(.dsMetaSmall)
                        .foregroundStyle(Color.textTertiary)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.dsMetaSmall)
                            .foregroundStyle(Color.accent)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.bgBase)
        }
        .navigationTitle(category == nil ? "New Category" : "Edit Category")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.bgBase, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") { save() }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty
                              || prompt.trimmingCharacters(in: .whitespaces).isEmpty)
                    .foregroundStyle(Color.accent)
            }
            ToolbarItem(placement: .topBarLeading) {
                if category == nil {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.textSecondary)
                }
            }
        }
        .onAppear(perform: load)
    }
```

- [ ] **Step 3: Build**

Run build. Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 4: Commit**

```bash
git add l8ter/l8ter/Views/ManageCategoriesView.swift
git commit -m "$(cat <<'EOF'
Restyle ManageCategoriesView and CategoryEditView

Section labels in mono, custom-category chip pill, "+ ADD" toolbar
button styled in mono caps purple, accent-tinted Save and Cancel.

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
EOF
)"
```

---

## Task 20: Final integration — full app smoke test

**Files:**
- None (verification + fix-forward only)

- [ ] **Step 1: Run the app in the simulator**

```bash
xcodebuild -project l8ter/l8ter.xcodeproj -scheme l8ter \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -configuration Debug build 2>&1 | tail -10
```

Expected: `** BUILD SUCCEEDED **`.

Then launch the simulator and the app:

```bash
open -a Simulator
xcrun simctl install booted \
  $(xcodebuild -project l8ter/l8ter.xcodeproj -scheme l8ter \
      -destination 'platform=iOS Simulator,name=iPhone 16' \
      -configuration Debug -showBuildSettings 2>/dev/null \
      | awk -F' = ' '/CODESIGNING_FOLDER_PATH/ {print $2; exit}')
xcrun simctl launch booted com.bobbydylan.l8ter
```

- [ ] **Step 2: Manual smoke checklist**

Walk through every tab and confirm:

1. **Saved tab** — header reads "Saved" + "N ITEMS", filter pills scroll horizontally, rows show 64pt thumbnail + meta + title + subline, list background is `#0E0E10`. Swipe-to-archive and swipe-to-delete still work.
2. **Add tab** — idle state shows "01 · IDLE" + "Add". Paste a TikTok URL (use a known-saved one), tap Save, watch the pipeline steps light up in order, land on the saved card with confidence bar. "Add another" returns to idle.
3. **Map tab** — header overlays the map with pulse + "NEAR YOU · N SAVED". Tapping a pin shows the bottom selection card with Open in Maps + Details.
4. **Review tab** — if you have flagged items, rows show confidence bars; tapping opens the editor with mono section labels and the purple Done button.
5. **Debug → Settings** — section labels in mono caps, toggle tint is purple.
6. **Debug → Manage Categories** — built-ins listed, customs (if any) show the "custom" chip pill.

If anything is visually off in a way that doesn't match the spec, fix
it inline and commit each fix as `Polish: <screen> — <what>` referring
to the relevant spec section.

- [ ] **Step 3: Final no-op commit allowed if no fixes needed**

If fixes were needed, they were committed individually above. If no
fixes were needed, this task is complete with no additional commit.

```bash
git log --oneline -25
```

Expected: ~20 commits since the start of the visual refresh, ending
in a clean working tree.

---

## Self-Review

I checked each spec section against this plan:

- **Tokens (color, type, spacing, effects)** → Tasks 1, 2, 3 + glow/pulse implementations baked into Pulse + ConfidenceBar + PrimaryButton.
- **Components (MetaLabel, Chip, Pulse, ConfidenceBar, PrimaryButton, GhostButton, SectionLabel, KeyValueRow, PipelineStepList, CardSurface)** → Tasks 4–8.
- **Tab bar** → Task 9 (UITabBarAppearance).
- **Saved / list (4.2)** → Tasks 10, 11.
- **Map (4.3)** → Task 14.
- **Detail (4.4)** → Task 12.
- **Add three-state flow (4.5)** → Task 15 (with `CaptureProgress`).
- **Review (4.6)** → Task 16.
- **Review item edit (4.7)** → Task 17.
- **Settings (4.8)** → Task 18.
- **Manage Categories (4.9)** → Task 19.
- **Tag editor (4.10)** → Task 13.
- **App-wide dark mode lock** → Task 9 (`.preferredColorScheme(.dark)`).
- **Smoke verification** → Task 20.

No placeholders, no "TBD". Type and component names are consistent
across tasks (e.g., `PipelineStepList.Step` defined in Task 8 is
consumed in Task 15 via `progress.stepsForUI`).

Risks called out in the spec:
- **MapKit dark style + custom annotations**: addressed by Task 14
  using `Annotation` (custom view) instead of `Marker`.
- **CaptureView pipeline state**: addressed by introducing
  `CaptureProgress` inside Task 15 — internal to the view.
- **Tab bar fragility**: handled with `UITabBarAppearance` rather
  than rebuilding `TabView` from scratch (matches the fallback).

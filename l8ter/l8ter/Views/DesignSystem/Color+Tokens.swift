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

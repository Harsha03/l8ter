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

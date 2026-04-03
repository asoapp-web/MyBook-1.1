//
//  Theme.swift
//  MyBookShelf
//

import SwiftUI

enum AppTheme {
    // MARK: - Backgrounds (warm ink, not pure black)
    static let background = Color(hex: "#0E0B14") ?? Color(red: 0.055, green: 0.043, blue: 0.078)
    static let backgroundSecondary = Color(hex: "#1A1612") ?? Color(red: 0.1, green: 0.086, blue: 0.071)
    static let backgroundTertiary = Color(hex: "#251F1A") ?? Color(red: 0.145, green: 0.122, blue: 0.102)
    static let backgroundElevated = Color(hex: "#1E1915") ?? Color(red: 0.118, green: 0.098, blue: 0.082)

    // MARK: - Accent: lantern / amber glow
    static let accentLamp = Color(hex: "#D4A04C") ?? Color(red: 0.831, green: 0.627, blue: 0.298)
    static let accentLampLight = Color(hex: "#E2B96A") ?? Color(red: 0.886, green: 0.725, blue: 0.416)
    static let accentLampDark = Color(hex: "#B8882E") ?? Color(red: 0.722, green: 0.533, blue: 0.180)

    /// Legacy alias kept so existing callsites that reference orange still compile.
    static let accentOrange = accentLamp
    static let accentOrangeLight = accentLampLight
    static let accentOrangeDark = accentLampDark

    // MARK: - Text (cream / warm)
    static let textPrimary = Color(hex: "#F0E8D8") ?? Color(red: 0.941, green: 0.910, blue: 0.847)
    static let textSecondary = Color(hex: "#A89B8A") ?? Color(red: 0.659, green: 0.608, blue: 0.541)
    static let textMuted = Color(hex: "#6B5E50") ?? Color(red: 0.420, green: 0.369, blue: 0.314)

    // MARK: - Chrome
    static let divider = Color(hex: "#2C2420") ?? Color(red: 0.173, green: 0.141, blue: 0.125)
    static let outlineLamp = Color(hex: "#3D3225") ?? Color(red: 0.239, green: 0.196, blue: 0.145)
    static let shadow = Color.black.opacity(0.55)

    // MARK: - Shelf / cabinet wood (unchanged — 3D compatibility)
    static let shelfWood = Color(hex: "#2C1F12") ?? Color(red: 0.17, green: 0.12, blue: 0.07)
    static let shelfWoodLight = Color(hex: "#4A3520") ?? Color(red: 0.29, green: 0.2, blue: 0.13)

    // MARK: - Tab bar
    static let tabBarFill = Color(hex: "#141010") ?? Color(red: 0.078, green: 0.063, blue: 0.063)
    static let tabBarEdge = Color(hex: "#2E2520") ?? Color(red: 0.18, green: 0.145, blue: 0.125)
}

// MARK: - Typography helpers

extension Font {
    static func mbsDisplay(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
    static func mbsBody(_ size: CGFloat = 15, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
    static func mbsCaption(_ size: CGFloat = 12) -> Font {
        .system(size: size, weight: .medium, design: .default)
    }
    static let mbsTabLabel = Font.system(size: 10, weight: .medium)
    static let mbsDialogTitle = Font.system(size: 18, weight: .semibold, design: .serif)
}

// MARK: - Gradient presets

extension LinearGradient {
    static let mbsLampAccent = LinearGradient(
        colors: [AppTheme.accentLamp, AppTheme.accentLampDark],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let mbsTabBarGradient = LinearGradient(
        colors: [AppTheme.tabBarFill.opacity(0.96), AppTheme.tabBarFill],
        startPoint: .top, endPoint: .bottom
    )
}

// MARK: - Card system

struct MBSCardModifier: ViewModifier {
    var elevated: Bool = false

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(elevated ? AppTheme.backgroundElevated : AppTheme.backgroundSecondary)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(AppTheme.accentLamp.opacity(0.28), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.38), radius: 12, x: 0, y: 5)
            .shadow(color: AppTheme.accentLamp.opacity(0.07), radius: 26, x: 0, y: 10)
    }
}

extension View {
    func mbsCard(elevated: Bool = false) -> some View {
        modifier(MBSCardModifier(elevated: elevated))
    }
}

extension Color {
    init?(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let n = UInt32(s, radix: 16) else { return nil }
        let r = Double((n >> 16) & 0xFF) / 255
        let g = Double((n >> 8) & 0xFF) / 255
        let b = Double(n & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

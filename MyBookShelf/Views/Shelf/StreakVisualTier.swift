//
//  StreakVisualTier.swift
//  MyBookShelf
//

import SwiftUI

/// Visual identity for the reading streak — shelf button + streak hub share this.
enum StreakVisualTier: Int, CaseIterable, Comparable {
    case spark = 0
    case ember
    case flame
    case blaze
    case inferno
    case legend

    static func < (lhs: StreakVisualTier, rhs: StreakVisualTier) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    static func tier(for streak: Int) -> StreakVisualTier {
        switch streak {
        case 0: return .spark
        case 1...2: return .ember
        case 3...6: return .flame
        case 7...13: return .blaze
        case 14...29: return .inferno
        default: return .legend
        }
    }

    var title: String {
        switch self {
        case .spark: return "Spark"
        case .ember: return "Ember"
        case .flame: return "Flame"
        case .blaze: return "Blaze"
        case .inferno: return "Inferno"
        case .legend: return "Legend"
        }
    }

    var tagline: String {
        switch self {
        case .spark: return "Light the first spark"
        case .ember: return "The habit is warming up"
        case .flame: return "Steady fire — keep going"
        case .blaze: return "You’re on serious heat"
        case .inferno: return "Unstoppable reader"
        case .legend: return "Shelf legend status"
        }
    }

    var primaryGradient: [Color] {
        switch self {
        case .spark:
            return [Color(red: 0.24, green: 0.24, blue: 0.27), Color(red: 0.16, green: 0.16, blue: 0.19)]
        case .ember:
            return [Color(red: 0.36, green: 0.24, blue: 0.18), Color(red: 0.45, green: 0.28, blue: 0.12)]
        case .flame:
            return [AppTheme.accentOrangeDark, AppTheme.accentOrange]
        case .blaze:
            return [Color(red: 0.91, green: 0.36, blue: 0.02), AppTheme.accentOrange, Color(red: 1.0, green: 0.67, blue: 0.2)]
        case .inferno:
            return [Color(red: 0.62, green: 0.01, blue: 0.03), Color(red: 0.82, green: 0.0, blue: 0.0), AppTheme.accentOrange]
        case .legend:
            return [Color(red: 0.37, green: 0.17, blue: 0.65), Color(red: 0.79, green: 0.09, blue: 0.52), AppTheme.accentOrange]
        }
    }

    var glowColor: Color {
        switch self {
        case .spark: return Color.white.opacity(0.08)
        case .ember: return Color(red: 1.0, green: 0.55, blue: 0.26).opacity(0.28)
        case .flame: return AppTheme.accentOrange.opacity(0.45)
        case .blaze: return Color(red: 1.0, green: 0.58, blue: 0.0).opacity(0.5)
        case .inferno: return Color.red.opacity(0.55)
        case .legend: return Color(red: 0.88, green: 0.25, blue: 0.98).opacity(0.45)
        }
    }

    var iconName: String {
        switch self {
        case .spark: return "flame"
        case .ember: return "flame.fill"
        case .flame: return "flame.fill"
        case .blaze: return "flame.circle.fill"
        case .inferno: return "fire.circle.fill"
        case .legend: return "crown.fill"
        }
    }

    var secondaryIcon: String? {
        switch self {
        case .legend: return "sparkles"
        case .inferno: return "bolt.fill"
        case .blaze: return "wind"
        default: return nil
        }
    }
}

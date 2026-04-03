//
//  GamificationGameViews.swift
//  MyBookShelf
//

import SwiftUI

// MARK: - Quest board

enum QuestBoardKind {
    case daily
    case weekly
    case challenge

    var label: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .challenge: return "Challenge"
        }
    }

    var accent: Color {
        switch self {
        case .daily: return Color(red: 0.45, green: 0.78, blue: 1.0)
        case .weekly: return AppTheme.accentOrange
        case .challenge: return Color(red: 0.72, green: 0.55, blue: 1.0)
        }
    }
}

struct QuestBoardCard: View {
    let quest: Quest
    let kind: QuestBoardKind
    let current: Int
    let total: Int
    let objectiveDone: Bool
    let rewardClaimed: Bool
    /// Fresh payout / progress worth attention (matches tab notification queue).
    var showNewLoot: Bool = false

    private var progress: Double {
        guard total > 0 else { return 0 }
        return min(100, Double(current) / Double(total) * 100)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(kind.accent.opacity(0.18))
                    .frame(width: 52, height: 52)
                Image(systemName: quest.iconName)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(kind.accent)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text(quest.title)
                        .font(.subheadline.bold())
                        .foregroundStyle(AppTheme.textPrimary)
                    Spacer()
                    Text(kind.label.uppercased())
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundStyle(kind.accent.opacity(0.95))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(kind.accent.opacity(0.2)))
                }

                Text(quest.description)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                ProgressBarView(progress: progress)
                    .frame(height: 7)

                HStack {
                    Text("\(current)/\(total)")
                        .font(.caption.monospacedDigit().weight(.medium))
                        .foregroundStyle(AppTheme.textMuted)
                    Spacer()
                    if rewardClaimed {
                        Label("+\(quest.xpReward) XP", systemImage: "sparkles")
                            .font(.caption.bold())
                            .foregroundStyle(AppTheme.accentOrange)
                    } else {
                        Text(objectiveDone ? "Finishing up reward…" : "Reward: \(quest.xpReward) XP")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(objectiveDone ? AppTheme.textMuted : kind.accent.opacity(0.9))
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppTheme.backgroundSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    kind.accent.opacity(objectiveDone ? 0.45 : 0.15),
                                    Color.white.opacity(0.06),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: objectiveDone ? 1.5 : 1
                        )
                )
        )
        .shadow(color: objectiveDone ? kind.accent.opacity(0.12) : .clear, radius: 12, y: 4)
        .overlay(alignment: .topTrailing) {
            if showNewLoot {
                Text("NEW")
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.red))
                    .padding(.top, 8)
                    .padding(.trailing, 10)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.red.opacity(showNewLoot ? 0.9 : 0), lineWidth: showNewLoot ? 2 : 0)
        )
        .animation(.spring(response: 0.45, dampingFraction: 0.72), value: showNewLoot)
    }
}

// MARK: - Achievements

enum AchievementTierStyle {
    case bronze
    case silver
    case gold
    case mythic

    static func forXP(_ xp: Int) -> AchievementTierStyle {
        switch xp {
        case ..<25: return .bronze
        case ..<80: return .silver
        case ..<200: return .gold
        default: return .mythic
        }
    }

    var label: String {
        switch self {
        case .bronze: return "Bronze"
        case .silver: return "Silver"
        case .gold: return "Gold"
        case .mythic: return "Mythic"
        }
    }

    var gradient: [Color] {
        switch self {
        case .bronze:
            return [Color(red: 0.62, green: 0.42, blue: 0.28), Color(red: 0.4, green: 0.28, blue: 0.2)]
        case .silver:
            return [Color(red: 0.75, green: 0.78, blue: 0.82), Color(red: 0.45, green: 0.48, blue: 0.52)]
        case .gold:
            return [Color(red: 1.0, green: 0.82, blue: 0.35), Color(red: 0.85, green: 0.55, blue: 0.15)]
        case .mythic:
            return [Color(red: 0.65, green: 0.45, blue: 1.0), Color(red: 0.35, green: 0.2, blue: 0.75)]
        }
    }
}

struct AchievementGameCard: View {
    let achievement: Achievement
    let unlocked: Bool
    let progress: (current: Int, total: Int)?
    var showNewLoot: Bool = false

    private var tier: AchievementTierStyle {
        AchievementTierStyle.forXP(achievement.xpReward)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                ZStack {
                    Circle()
                        .fill(
                            unlocked
                                ? LinearGradient(colors: tier.gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                                : LinearGradient(colors: [AppTheme.backgroundTertiary, AppTheme.backgroundTertiary], startPoint: .top, endPoint: .bottom)
                        )
                        .frame(width: 48, height: 48)
                    ZStack {
                        Image(systemName: achievement.iconName)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(unlocked ? .white : AppTheme.textMuted.opacity(0.22))
                            .shadow(color: unlocked ? .black.opacity(0.25) : .clear, radius: 2, y: 1)
                        if !unlocked {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(AppTheme.textMuted)
                                .offset(y: 10)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(achievement.title)
                            .font(.subheadline.bold())
                            .foregroundStyle(AppTheme.textPrimary)
                            .lineLimit(2)
                        if showNewLoot {
                            Text("NEW")
                                .font(.system(size: 8, weight: .black))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.red))
                        }
                        Spacer(minLength: 4)
                        Text(tier.label)
                            .font(.system(size: 8, weight: .heavy))
                            .foregroundStyle(unlocked ? AppTheme.textSecondary : AppTheme.textMuted)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(AppTheme.backgroundTertiary))
                    }
                    Text(achievement.description)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(3)
                    if unlocked {
                        Text("Unlocked · +\(achievement.xpReward) XP")
                            .font(.caption2.bold())
                            .foregroundStyle(AppTheme.accentOrange)
                    } else if let p = progress {
                        VStack(alignment: .leading, spacing: 4) {
                            ProgressBarView(progress: Double(p.current) / Double(max(1, p.total)) * 100)
                                .frame(height: 5)
                            Text("\(p.current)/\(p.total)")
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(AppTheme.textMuted)
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppTheme.backgroundSecondary.opacity(unlocked ? 1 : 0.72))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(
                            unlocked
                                ? LinearGradient(colors: tier.gradient.map { $0.opacity(0.5) }, startPoint: .topLeading, endPoint: .bottomTrailing)
                                : LinearGradient(colors: [Color.white.opacity(0.06)], startPoint: .top, endPoint: .bottom),
                            lineWidth: unlocked ? 1.5 : 1
                        )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.red.opacity(showNewLoot ? 0.95 : 0), lineWidth: showNewLoot ? 2.5 : 0)
        )
        .animation(.spring(response: 0.45, dampingFraction: 0.72), value: showNewLoot)
    }
}

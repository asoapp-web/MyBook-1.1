//
//  ShelfGamificationStrip.swift
//  MyBookShelf
//

import SwiftUI

struct ShelfGamificationStrip: View {
    @ObservedObject var profileVM: ProfileViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let p = profileVM.profile {
                levelRow(p)
                Text("Quests & trophies live in the Rewards tab.")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textMuted)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppTheme.backgroundSecondary.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    private func levelRow(_ p: UserProfile) -> some View {
        let lvl = Int(p.currentLevel)
        let low = GamificationEngine.shared.xpForLevel(lvl)
        let high = GamificationEngine.shared.xpForLevel(lvl + 1)
        let inLevel = max(0, Int(p.totalXP) - low)
        let span = max(1, high - low)
        let pct = Double(inLevel) / Double(span) * 100

        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Level \(lvl)")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                Text("\(Int(p.totalXP)) XP total")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textMuted)
            }
            ProgressBarView(progress: min(100, pct))
                .frame(height: 6)
            Text("\(inLevel) / \(span) XP to level \(lvl + 1)")
                .font(.caption2)
                .foregroundStyle(AppTheme.textSecondary)
        }
    }
}

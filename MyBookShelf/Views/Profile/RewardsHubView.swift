//
//  RewardsHubView.swift
//  MyBookShelf
//

import CoreData
import SwiftUI

/// Single hub for quests + trophies (own tab). Tab badge + NEW highlights driven by `UserProfile` notification fields.
struct RewardsHubView: View {
    @EnvironmentObject private var gamificationBadges: GamificationBadgeObserver
    @Environment(\.managedObjectContext) private var moc
    @StateObject private var qvm = QuestViewModel()
    @State private var profile: UserProfile?
    @State private var achievementFilter: AchievementCategory?

    private var pendingAchievementIDs: Set<String> {
        Set(profile?.pendingNotifyAchievementIDs ?? [])
    }

    private var pendingQuestKeys: Set<String> {
        Set(profile?.pendingNotifyQuestKeys ?? [])
    }

    private var hasHighlightStrip: Bool {
        !pendingAchievementIDs.isEmpty || !pendingQuestKeys.isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                MBSAtmosphereBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        if hasHighlightStrip {
                            highlightBanner
                        }

                        hubHeader

                        questBoardSection(
                            title: "Daily contracts",
                            subtitle: "Reset at midnight · XP credits automatically",
                            kind: .daily,
                            quests: QuestData.dailyTemplates
                        )

                        questBoardSection(
                            title: "Weekly raids",
                            subtitle: "Tied to your calendar week",
                            kind: .weekly,
                            quests: QuestData.weeklyTemplates
                        )

                        questBoardSection(
                            title: "Milestones",
                            subtitle: "One-time challenges",
                            kind: .challenge,
                            quests: QuestData.challenges
                        )

                        trophiesSection
                    }
                    .padding(16)
                    .padding(.bottom, 28)
                }
                .background(Color.clear)
            }
            .navigationTitle("Rewards")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(AppTheme.background.opacity(0.88), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .onAppear {
            reloadProfile()
            acknowledgeUnreadBadge()
            GamificationEngine.shared.refreshGamificationHooks(context: moc)
            qvm.refresh()
        }
        .onDisappear {
            clearHighlightQueues()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSManagedObjectContext.didSaveObjectsNotification, object: moc)) { _ in
            reloadProfile()
            qvm.refresh()
            acknowledgeUnreadBadge()
            gamificationBadges.refresh()
        }
    }

    private var highlightBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 20))
                .foregroundStyle(Color.red)
                .symbolRenderingMode(.hierarchical)
            VStack(alignment: .leading, spacing: 2) {
                Text("Fresh rewards")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.textPrimary)
                Text("Scroll for cards outlined in red with a NEW tag.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.red.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.red.opacity(0.35), lineWidth: 1)
                )
        )
    }

    private var hubHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Quests & trophies")
                .font(.title2.bold())
                .foregroundStyle(AppTheme.textPrimary)
            Text("Contracts refresh on a schedule; trophies are forever. The tab icon shows how many updates you haven’t opened yet.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func questBoardSection(title: String, subtitle: String, kind: QuestBoardKind, quests: [Quest]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textMuted)
            }

            VStack(spacing: 12) {
                ForEach(quests) { quest in
                    let (cur, total) = qvm.progress(for: quest)
                    let done = qvm.isCompleted(quest)
                    let claimed = qvm.rewardClaimed(quest)
                    let qKey = GamificationEngine.shared.questNotificationKey(for: quest)
                    let isNew = pendingQuestKeys.contains(qKey)
                    QuestBoardCard(
                        quest: quest,
                        kind: kind,
                        current: cur,
                        total: total,
                        objectiveDone: done,
                        rewardClaimed: claimed,
                        showNewLoot: isNew
                    )
                }
            }
        }
    }

    private var trophiesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Trophy hall")
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)
                    if let p = profile {
                        let n = AchievementData.all.filter { p.unlockedAchievementIDs.contains($0.id) }.count
                        Text("\(n)/\(AchievementData.all.count) unlocked")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textMuted)
                    }
                }
                Spacer()
            }

            Picker("Category", selection: $achievementFilter) {
                Text("All").tag(nil as AchievementCategory?)
                ForEach(AchievementCategory.allCases, id: \.self) { c in
                    Text(c.label).tag(c as AchievementCategory?)
                }
            }
            .pickerStyle(.segmented)

            let filtered = achievementFilter == nil
                ? AchievementData.all
                : AchievementData.all.filter { $0.category == achievementFilter }

            LazyVStack(spacing: 12) {
                ForEach(filtered) { ach in
                    let unlocked = profile?.unlockedAchievementIDs.contains(ach.id) ?? false
                    let prog = profile.flatMap { p in
                        GamificationEngine.shared.achievementDisplayProgress(ach, profile: p, context: moc)
                    }
                    let isNew = pendingAchievementIDs.contains(ach.id)
                    AchievementGameCard(
                        achievement: ach,
                        unlocked: unlocked,
                        progress: prog,
                        showNewLoot: isNew && unlocked
                    )
                }
            }
        }
    }

    private func reloadProfile() {
        let req = UserProfile.fetchRequest()
        req.fetchLimit = 1
        profile = try? moc.fetch(req).first
    }

    private func acknowledgeUnreadBadge() {
        let req = UserProfile.fetchRequest()
        req.fetchLimit = 1
        guard let p = try? moc.fetch(req).first, p.unreadGamificationCount > 0 else {
            gamificationBadges.refresh()
            return
        }
        p.unreadGamificationCount = 0
        try? moc.save()
        gamificationBadges.refresh()
    }

    private func clearHighlightQueues() {
        let req = UserProfile.fetchRequest()
        req.fetchLimit = 1
        guard let p = try? moc.fetch(req).first else { return }
        guard !p.pendingNotifyAchievementIDs.isEmpty || !p.pendingNotifyQuestKeys.isEmpty else { return }
        p.pendingNotifyAchievementIDs = []
        p.pendingNotifyQuestKeys = []
        try? moc.save()
        reloadProfile()
    }
}

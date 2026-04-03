//
//  GamificationEngine.swift
//  MyBookShelf
//

import CoreData
import Foundation

final class GamificationEngine {
    static let shared = GamificationEngine()

    private init() {}

    /// Cumulative XP needed to **reach** level `n` (level 1 starts at 0).
    /// Each step *k* → *k*+1 costs `25 + 17*k`, so early levels are quicker than the old flat 100 XP,
    /// and higher levels need noticeably more than the previous tier (no identical bars every time).
    func xpForLevel(_ n: Int) -> Int {
        guard n > 1 else { return 0 }
        var total = 0
        for k in 1..<n {
            total += 25 + 17 * k
        }
        return total
    }

    func level(from totalXP: Int) -> Int {
        var lvl = 1
        while totalXP >= xpForLevel(lvl + 1) {
            lvl += 1
        }
        return lvl
    }

    func xpToNextLevel(currentLevel: Int, totalXP: Int) -> Int {
        let needed = xpForLevel(currentLevel + 1)
        return max(0, needed - totalXP)
    }

    func addXP(_ amount: Int, to profile: UserProfile, context: NSManagedObjectContext) {
        profile.totalXP += Int32(amount)
        syncProfileLevel(profile: profile)
        try? context.save()
    }

    /// Keeps `UserProfile.currentLevel` aligned with `totalXP` (fixes stale level in UI).
    func syncProfileLevel(profile: UserProfile) {
        let lvl = level(from: Int(profile.totalXP))
        profile.currentLevel = Int32(max(1, lvl))
    }

    func processBookAdded(profile: UserProfile, context: NSManagedObjectContext) {
        addXP(5, to: profile, context: context)
        checkAchievements(profile: profile, context: context)
        processPendingQuestRewards(profile: profile, context: context)
    }

    func processProgressUpdate(pagesRead: Int, profile: UserProfile, context: NSManagedObjectContext) {
        let xp = (pagesRead + 9) / 10
        var bonus = 0
        if let last = profile.lastReadingDate {
            let cal = Calendar.current
            let yesterday = cal.date(byAdding: .day, value: -1, to: Date())!
            if cal.isDate(last, inSameDayAs: yesterday) {
                bonus = 2
            }
        }
        addXP(xp + bonus, to: profile, context: context)
        profile.totalPagesRead += Int32(pagesRead)
        profile.lastReadingDate = Date()
        updateStreak(profile: profile)
        try? context.save()
        checkAchievements(profile: profile, context: context)
        processPendingQuestRewards(profile: profile, context: context)
    }

    func processBookFinished(book: Book, profile: UserProfile, context: NSManagedObjectContext) {
        addXP(25, to: profile, context: context)
        profile.totalBooksFinished += 1
        if book.totalPages >= 500 {
            grantAchievement("thick_book", profile: profile, context: context)
        }
        checkAchievements(profile: profile, context: context)
        processPendingQuestRewards(profile: profile, context: context)
    }

    func processRating(profile: UserProfile, context: NSManagedObjectContext) {
        addXP(2, to: profile, context: context)
        checkAchievements(profile: profile, context: context)
        processPendingQuestRewards(profile: profile, context: context)
    }

    func processFavorite(profile: UserProfile, context: NSManagedObjectContext) {
        addXP(2, to: profile, context: context)
        checkAchievements(profile: profile, context: context)
        processPendingQuestRewards(profile: profile, context: context)
    }

    private func updateStreak(profile: UserProfile) {
        let cal = Calendar.current
        let today = Date()
        guard let last = profile.lastReadingDate else {
            profile.currentStreak = 1
            if profile.longestStreak < 1 { profile.longestStreak = 1 }
            return
        }
        if cal.isDate(last, inSameDayAs: today) {
            return
        }
        let yesterday = cal.date(byAdding: .day, value: -1, to: today)!
        if cal.isDate(last, inSameDayAs: yesterday) {
            profile.currentStreak += 1
        } else {
            profile.currentStreak = 1
        }
        if profile.currentStreak > profile.longestStreak {
            profile.longestStreak = profile.currentStreak
        }
    }

    private func checkAchievements(profile: UserProfile, context: NSManagedObjectContext) {
        let books = fetchAllBooks(context: context)
        let finished = books.filter { $0.statusEnum == .finished }
        let favorites = books.filter { $0.isFavorite }
        let rated = books.filter { $0.displayRating != nil }

        for ach in AchievementData.all {
            if AchievementData.manualOnlyAchievementIds.contains(ach.id) { continue }
            if profile.unlockedAchievementIDs.contains(ach.id) { continue }
            var unlocked = false
            switch ach.requirement.type {
            case .totalBooksAdded:
                unlocked = books.count >= ach.requirement.value
            case .booksFinished:
                unlocked = finished.count >= ach.requirement.value
            case .pagesRead:
                unlocked = Int(profile.totalPagesRead) >= ach.requirement.value
            case .streakDays:
                unlocked = profile.currentStreak >= ach.requirement.value
            case .booksInGenre:
                if let g = ach.requirement.genre {
                    unlocked = finished.filter { $0.genre == g }.count >= ach.requirement.value
                }
            case .ratingGiven:
                unlocked = rated.count >= ach.requirement.value
            case .favoriteBooks:
                unlocked = favorites.count >= ach.requirement.value
            }
            if unlocked {
                grantAchievement(ach.id, profile: profile, context: context)
            }
        }
    }

    private func grantAchievement(_ id: String, profile: UserProfile, context: NSManagedObjectContext) {
        guard !profile.unlockedAchievementIDs.contains(id) else { return }
        var ids = profile.unlockedAchievementIDs
        ids.append(id)
        profile.unlockedAchievementIDs = ids
        registerNewAchievementNotice(id: id, profile: profile)
        if let ach = AchievementData.by(id: id) {
            addXP(ach.xpReward, to: profile, context: context)
        }
        try? context.save()
    }

    private func registerNewAchievementNotice(id: String, profile: UserProfile) {
        var pend = profile.pendingNotifyAchievementIDs
        guard !pend.contains(id) else { return }
        pend.append(id)
        profile.pendingNotifyAchievementIDs = pend
        profile.unreadGamificationCount += 1
    }

    private func registerNewQuestNotice(key: String, profile: UserProfile) {
        var pend = profile.pendingNotifyQuestKeys
        guard !pend.contains(key) else { return }
        pend.append(key)
        profile.pendingNotifyQuestKeys = pend
        profile.unreadGamificationCount += 1
    }

    private func fetchAllBooks(context: NSManagedObjectContext) -> [Book] {
        let req = Book.fetchRequest()
        return (try? context.fetch(req)) ?? []
    }

    /// Core Data key for "already claimed XP" — daily/weekly include calendar period so a new day/week can pay out again.
    /// Same key as stored in `completedQuestIDs` / highlight queue for UI.
    func questNotificationKey(for quest: Quest, now: Date = Date()) -> String {
        questRewardClaimKey(for: quest, now: now)
    }

    private func questRewardClaimKey(for quest: Quest, now: Date = Date(), calendar cal: Calendar = .current) -> String {
        switch quest.type {
        case .daily:
            let c = cal.dateComponents([.year, .month, .day], from: now)
            return "\(quest.id)#day:\(c.year ?? 0)-\(c.month ?? 0)-\(c.day ?? 0)"
        case .weekly:
            let c = cal.dateComponents([.calendar, .timeZone, .yearForWeekOfYear, .weekOfYear], from: now)
            return "\(quest.id)#week:\(c.yearForWeekOfYear ?? 0)-\(c.weekOfYear ?? 0)"
        case .challenge:
            return quest.id
        }
    }

    func questProgress(for quest: Quest, profile: UserProfile, context: NSManagedObjectContext) -> (current: Int, total: Int) {
        let total = quest.requirement.value
        let books = fetchAllBooks(context: context)
        let now = Date()
        let cal = Calendar.current

        switch quest.requirement.type {
        case .readPages:
            if quest.type == .daily {
                let todayStart = cal.startOfDay(for: now)
                let sessions = fetchSessions(from: todayStart, to: now, context: context)
                let pages = sessions.reduce(0) { $0 + Int($1.pagesRead) }
                return (min(pages, total), total)
            }
            if quest.type == .weekly {
                let weekStart = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
                let sessions = fetchSessions(from: weekStart, to: now, context: context)
                let pages = sessions.reduce(0) { $0 + Int($1.pagesRead) }
                return (min(pages, total), total)
            }
            if quest.type == .challenge && quest.id == "challenge_marathon" {
                let weekAgo = cal.date(byAdding: .day, value: -7, to: now)!
                let sessions = fetchSessions(from: weekAgo, to: now, context: context)
                let pages = sessions.reduce(0) { $0 + Int($1.pagesRead) }
                return (min(pages, total), total)
            }
            return (Int(profile.totalPagesRead), total)
        case .addBook:
            if quest.type == .daily {
                let todayStart = cal.startOfDay(for: now)
                let added = books.filter { ($0.dateAdded ?? Date.distantPast) >= todayStart }.count
                return (min(added, total), total)
            }
            return (books.count, total)
        case .finishBook:
            if quest.type == .weekly {
                let weekStart = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
                let finished = books.filter { $0.statusEnum == .finished && ($0.dateFinished ?? Date.distantPast) >= weekStart }.count
                return (min(finished, total), total)
            }
            return (Int(profile.totalBooksFinished), total)
        case .readDaysInRow:
            return (min(Int(profile.currentStreak), total), total)
        case .readMinutes:
            return (0, total)
        case .rateBooks:
            let rated = books.filter { $0.displayRating != nil }.count
            return (min(rated, total), total)
        }
    }

    func isQuestCompleted(_ quest: Quest, profile: UserProfile, context: NSManagedObjectContext) -> Bool {
        let (cur, total) = questProgress(for: quest, profile: profile, context: context)
        switch quest.type {
        case .daily, .weekly:
            // Progress is always scoped to "today" / "this week" in `questProgress` — no stale `completedQuestIDs` check.
            return cur >= total
        case .challenge:
            if profile.completedQuestIDs.contains(quest.id) { return true }
            return cur >= total
        }
    }

    func completeQuest(_ quest: Quest, profile: UserProfile, context: NSManagedObjectContext) {
        let (cur, total) = questProgress(for: quest, profile: profile, context: context)
        guard cur >= total else { return }
        let key = questRewardClaimKey(for: quest)
        guard !profile.completedQuestIDs.contains(key) else { return }
        var ids = profile.completedQuestIDs
        ids.append(key)
        profile.completedQuestIDs = ids
        registerNewQuestNotice(key: key, profile: profile)
        addXP(quest.xpReward, to: profile, context: context)
        try? context.save()
    }

    func hasClaimedQuestReward(_ quest: Quest, profile: UserProfile) -> Bool {
        profile.completedQuestIDs.contains(questRewardClaimKey(for: quest))
    }

    /// After a new calendar day/week or returning to the app — catch quests & achievements without a fresh reading event.
    func refreshGamificationHooks(context: NSManagedObjectContext) {
        let req = UserProfile.fetchRequest()
        req.fetchLimit = 1
        guard let p = try? context.fetch(req).first else { return }
        checkAchievements(profile: p, context: context)
        processPendingQuestRewards(profile: p, context: context)
    }

    /// Progress toward a locked achievement (nil if secret / unlocked).
    func achievementDisplayProgress(_ ach: Achievement, profile: UserProfile, context: NSManagedObjectContext) -> (current: Int, total: Int)? {
        if profile.unlockedAchievementIDs.contains(ach.id) { return nil }
        if AchievementData.manualOnlyAchievementIds.contains(ach.id) { return nil }
        let books = fetchAllBooks(context: context)
        let finished = books.filter { $0.statusEnum == .finished }
        let favorites = books.filter { $0.isFavorite }
        let rated = books.filter { $0.displayRating != nil }
        let total = ach.requirement.value
        switch ach.requirement.type {
        case .totalBooksAdded:
            return (min(books.count, total), total)
        case .booksFinished:
            return (min(finished.count, total), total)
        case .pagesRead:
            return (min(Int(profile.totalPagesRead), total), total)
        case .streakDays:
            return (min(Int(profile.currentStreak), total), total)
        case .booksInGenre:
            guard let g = ach.requirement.genre else { return nil }
            let n = finished.filter { $0.genre == g }.count
            return (min(n, total), total)
        case .ratingGiven:
            return (min(rated.count, total), total)
        case .favoriteBooks:
            return (min(favorites.count, total), total)
        }
    }

    /// Awards XP when daily / weekly / challenge goals are met (no separate claim button).
    private func processPendingQuestRewards(profile: UserProfile, context: NSManagedObjectContext) {
        let quests = QuestData.dailyTemplates + QuestData.weeklyTemplates + QuestData.challenges
        let claimedBefore = profile.completedQuestIDs.count
        for quest in quests {
            completeQuest(quest, profile: profile, context: context)
        }
        if profile.completedQuestIDs.count > claimedBefore {
            HapticsService.shared.success()
        }
    }

    private func fetchSessions(from: Date, to: Date, context: NSManagedObjectContext) -> [ReadingSession] {
        let req = ReadingSession.fetchRequest()
        req.predicate = NSPredicate(format: "date >= %@ AND date <= %@", from as NSDate, to as NSDate)
        return (try? context.fetch(req)) ?? []
    }
}

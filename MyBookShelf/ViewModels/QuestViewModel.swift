//
//  QuestViewModel.swift
//  MyBookShelf
//

import Combine
import CoreData
import SwiftUI

extension Notification.Name {
    /// Posted when the calendar day may have changed (midnight, TZ, returning to foreground).
    static let myBookShelfQuestCalendarTick = Notification.Name("myBookShelf.questCalendarTick")
}

@MainActor
final class QuestViewModel: ObservableObject {
    private let context = PersistenceController.shared.container.viewContext
    private var calendarCancellable: AnyCancellable?

    init() {
        calendarCancellable = NotificationCenter.default.publisher(for: .myBookShelfQuestCalendarTick)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                GamificationEngine.shared.refreshGamificationHooks(context: PersistenceController.shared.container.viewContext)
                self?.refresh()
            }
    }

    var profile: UserProfile? {
        let req = UserProfile.fetchRequest()
        req.fetchLimit = 1
        return try? context.fetch(req).first
    }

    func progress(for quest: Quest) -> (current: Int, total: Int) {
        guard let p = profile else { return (0, quest.requirement.value) }
        return GamificationEngine.shared.questProgress(for: quest, profile: p, context: context)
    }

    func isCompleted(_ quest: Quest) -> Bool {
        guard let p = profile else { return false }
        return GamificationEngine.shared.isQuestCompleted(quest, profile: p, context: context)
    }

    func rewardClaimed(_ quest: Quest) -> Bool {
        guard let p = profile else { return false }
        return GamificationEngine.shared.hasClaimedQuestReward(quest, profile: p)
    }

    func complete(_ quest: Quest) {
        guard let p = profile else { return }
        GamificationEngine.shared.completeQuest(quest, profile: p, context: context)
    }

    var activeDaily: [Quest] {
        QuestData.dailyTemplates.prefix(2).map { $0 }
    }

    var activeWeekly: [Quest] {
        QuestData.weeklyTemplates.prefix(2).map { $0 }
    }

    /// Call after Core Data saves so quest progress UI (e.g. shelf strip) updates.
    func refresh() {
        objectWillChange.send()
    }
}

//
//  GamificationBadgeObserver.swift
//  MyBookShelf
//

import Combine
import CoreData
import SwiftUI

/// Drives tab-bar badge count from `UserProfile.unreadGamificationCount`.
@MainActor
final class GamificationBadgeObserver: ObservableObject {
    @Published private(set) var unreadCount: Int = 0

    private let context: NSManagedObjectContext
    private var saveObserver: NSObjectProtocol?

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
        refresh()
        saveObserver = NotificationCenter.default.addObserver(
            forName: NSManagedObjectContext.didSaveObjectsNotification,
            object: context,
            queue: .main
        ) { [weak self] _ in
            self?.refresh()
        }
    }

    deinit {
        if let saveObserver {
            NotificationCenter.default.removeObserver(saveObserver)
        }
    }

    func refresh() {
        let req = UserProfile.fetchRequest()
        req.fetchLimit = 1
        guard let p = try? context.fetch(req).first else {
            unreadCount = 0
            return
        }
        unreadCount = Int(max(0, p.unreadGamificationCount))
    }
}

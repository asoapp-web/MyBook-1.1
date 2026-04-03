//
//  Persistence.swift
//  MyBookShelf
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let ctx = result.container.viewContext
        let profile = UserProfile(context: ctx)
        profile.id = UUID()
        profile.displayName = "Reader"
        profile.totalXP = Int32(150)
        profile.currentLevel = Int32(1)
        profile.currentStreak = 0
        profile.longestStreak = 0
        profile.totalBooksFinished = 0
        profile.totalPagesRead = 0
        profile.dateJoined = Date()
        profile.selectedShelfStyleID = "wood_classic"
        profile.unlockedShelfStyles = ["wood_classic"]
        profile.unlockedAchievementIDs = []
        profile.completedQuestIDs = []
        GamificationEngine.shared.syncProfileLevel(profile: profile)

        for i in 0..<5 {
            let book = Book(context: ctx)
            book.id = UUID()
            book.title = "Sample Book \(i + 1)"
            book.author = "Author \(i + 1)"
            book.totalPages = Int32(300)
            book.currentPage = Int32(i * 50)
            book.genre = "Fiction"
            book.status = Int16(i % 3)
            book.dateAdded = Date()
            book.sourceType = 0
            book.notes = ""
        }
        try? ctx.save()
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "MyBookShelf")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Core Data error: \(error), \(error.userInfo)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    @MainActor
    func ensureUserProfile() {
        let req = UserProfile.fetchRequest()
        req.fetchLimit = 1
        if (try? container.viewContext.fetch(req))?.isEmpty == true {
            let p = UserProfile(context: container.viewContext)
            p.id = UUID()
            p.displayName = "Reader"
            p.totalXP = 0
            p.currentLevel = 1
            p.currentStreak = 0
            p.longestStreak = 0
            p.totalBooksFinished = 0
            p.totalPagesRead = 0
            p.dateJoined = Date()
            p.selectedShelfStyleID = "wood_classic"
            p.unlockedShelfStyles = ["wood_classic"]
            p.unlockedAchievementIDs = []
            p.completedQuestIDs = []
            p.dailyGoalPages = Int32(20)
            p.avatarIndex = 0
            p.unreadGamificationCount = 0
            try? container.viewContext.save()
        }
        // Fix profiles created before level sync existed
        let syncReq = UserProfile.fetchRequest()
        syncReq.fetchLimit = 1
        if let p = try? container.viewContext.fetch(syncReq).first {
            GamificationEngine.shared.syncProfileLevel(profile: p)
            try? container.viewContext.save()
        }
    }
}

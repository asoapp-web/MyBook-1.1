//
//  ShelfViewModel.swift
//  MyBookShelf
//

import Combine
import CoreData
import SwiftUI

enum ShelfFilter: Int, CaseIterable {
    case all = 0
    case reading = 1
    case finished = 2
    case wantToRead = 3

    var label: String {
        switch self {
        case .all: return "All"
        case .reading: return "Reading"
        case .finished: return "Finished"
        case .wantToRead: return "Want to read"
        }
    }
}

enum ShelfSort: Int, CaseIterable {
    case dateAdded = 0
    case title = 1
    case author = 2
    case progress = 3

    var label: String {
        switch self {
        case .dateAdded: return "Date added"
        case .title: return "Title (A–Z)"
        case .author: return "Author (A–Z)"
        case .progress: return "Reading progress"
        }
    }
}

@MainActor
final class ShelfViewModel: ObservableObject {
    @Published var filter: ShelfFilter = .all
    @Published var sort: ShelfSort = .dateAdded
    @Published var books: [Book] = []

    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
        fetch()
    }

    func fetch() {
        Book.normalizeAllWantToReadAgainstProgress(using: context)
        let req = Book.fetchRequest()
        req.sortDescriptors = sortDescriptors
        req.predicate = filterPredicate
        books = (try? context.fetch(req)) ?? []
    }

    private var filterPredicate: NSPredicate? {
        switch filter {
        case .all: return nil
        case .reading: return NSPredicate(format: "status == %d", ReadingStatus.reading.rawValue)
        case .finished: return NSPredicate(format: "status == %d", ReadingStatus.finished.rawValue)
        case .wantToRead: return NSPredicate(format: "status == %d", ReadingStatus.wantToRead.rawValue)
        }
    }

    private var sortDescriptors: [NSSortDescriptor] {
        switch sort {
        case .dateAdded:
            return [NSSortDescriptor(keyPath: \Book.dateAdded, ascending: false)]
        case .title:
            return [NSSortDescriptor(keyPath: \Book.title, ascending: true)]
        case .author:
            return [NSSortDescriptor(keyPath: \Book.author, ascending: true)]
        case .progress:
            return [NSSortDescriptor(keyPath: \Book.currentPage, ascending: false)]
        }
    }

    func setFilter(_ f: ShelfFilter) {
        filter = f
        fetch()
    }

    func setSort(_ s: ShelfSort) {
        sort = s
        fetch()
    }

    func delete(_ book: Book) {
        context.delete(book)
        try? context.save()
        fetch()
    }

    func toggleFavorite(_ book: Book) {
        book.isFavorite.toggle()
        if book.isFavorite {
            GamificationEngine.shared.processFavorite(profile: profile, context: context)
        }
        try? context.save()
    }

    func setStatus(_ book: Book, status: ReadingStatus) {
        let resolved = book.resolvedReadingStatus(for: status)
        let wasFinished = book.statusEnum == .finished
        book.statusEnum = resolved
        if resolved == .reading && book.dateStarted == nil {
            book.dateStarted = Date()
        }
        if resolved == .finished {
            book.dateFinished = Date()
            book.currentPage = book.totalPages
            if !wasFinished {
                GamificationEngine.shared.processBookFinished(book: book, profile: profile, context: context)
            }
        }
        try? context.save()
        fetch()
    }

    private var profile: UserProfile {
        let req = UserProfile.fetchRequest()
        req.fetchLimit = 1
        return (try? context.fetch(req))?.first ?? UserProfile(context: context)
    }
}

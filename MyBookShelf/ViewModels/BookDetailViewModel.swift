//
//  BookDetailViewModel.swift
//  MyBookShelf
//

import Combine
import CoreData
import SwiftUI

@MainActor
final class BookDetailViewModel: ObservableObject {
    let book: Book
    private let context: NSManagedObjectContext

    init(book: Book, context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.book = book
        self.context = context
        book.normalizeWantToReadAgainstProgress(using: context)
    }

    /// Core Data mutates `book` without notifying SwiftUI; call this after any external save (sheets) or use our methods that already ping the view.
    func refreshUI() {
        objectWillChange.send()
    }

    var profile: UserProfile? {
        let req = UserProfile.fetchRequest()
        req.fetchLimit = 1
        return try? context.fetch(req).first
    }

    func updateProgress(to page: Int, durationMinutes: Int?) {
        let start = Int(book.currentPage)
        let pagesRead = max(0, page - start)
        book.currentPage = Int32(pagesRead > 0 ? page : start)
        if book.currentPage > 0, book.statusEnum == .wantToRead {
            book.statusEnum = .reading
            if book.dateStarted == nil { book.dateStarted = Date() }
        }
        if pagesRead > 0 {
            let session = ReadingSession(context: context)
            session.id = UUID()
            session.date = Date()
            session.pagesRead = Int32(pagesRead)
            session.startPage = Int32(start)
            session.endPage = Int32(book.currentPage)
            session.durationMinutes = durationMinutes.map { Int32($0) } ?? Int32(0)
            session.book = book
            if let p = profile {
                GamificationEngine.shared.processProgressUpdate(pagesRead: pagesRead, profile: p, context: context)
            }
        }
        if book.currentPage >= book.totalPages {
            book.statusEnum = .finished
            book.dateFinished = Date()
            if let p = profile {
                GamificationEngine.shared.processBookFinished(book: book, profile: p, context: context)
            }
        }
        try? context.save()
        objectWillChange.send()
    }

    func setRating(_ rating: Int?) {
        let hadRating = book.displayRating != nil
        book.rating = rating.map { Int16($0) } ?? 0
        if rating != nil && !hadRating, let p = profile {
            GamificationEngine.shared.processRating(profile: p, context: context)
        }
        try? context.save()
        objectWillChange.send()
    }

    func setStatus(_ newStatus: ReadingStatus) {
        let resolved = book.resolvedReadingStatus(for: newStatus)
        let previous = book.statusEnum
        book.statusEnum = resolved
        if resolved == .reading, book.dateStarted == nil {
            book.dateStarted = Date()
        }
        if resolved == .finished, previous != .finished {
            book.dateFinished = Date()
            if let p = profile {
                GamificationEngine.shared.processBookFinished(book: book, profile: p, context: context)
            }
        }
        if resolved != .finished {
            book.dateFinished = nil
        }
        try? context.save()
        objectWillChange.send()
    }

    func toggleFavorite() {
        book.isFavorite.toggle()
        if book.isFavorite, let p = profile {
            GamificationEngine.shared.processFavorite(profile: p, context: context)
        }
        try? context.save()
        objectWillChange.send()
    }

    func saveNotes(_ text: String) {
        book.notes = text
        try? context.save()
        objectWillChange.send()
    }

    var sessions: [ReadingSession] {
        let set = book.readingSessions as? Set<ReadingSession> ?? []
        return set.sorted { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }
    }
}

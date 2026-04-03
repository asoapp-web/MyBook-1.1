//
//  Book+Extensions.swift
//  MyBookShelf
//

import CoreData

enum ReadingStatus: Int16, CaseIterable {
    case wantToRead = 0
    case reading = 1
    case finished = 2

    var label: String {
        switch self {
        case .wantToRead: return "Want to read"
        case .reading: return "Reading"
        case .finished: return "Finished"
        }
    }

    /// Picker / context menu: no "Want to read" once any page has been read.
    static func selectableCases(for book: Book) -> [ReadingStatus] {
        if book.currentPage > 0 {
            return allCases.filter { $0 != .wantToRead }
        }
        return Array(allCases)
    }
}

enum BookSourceType: Int16 {
    case openLibrary = 0
    case manual = 1
}

extension Book {
    var statusEnum: ReadingStatus {
        get { ReadingStatus(rawValue: status) ?? .wantToRead }
        set { status = newValue.rawValue }
    }

    var sourceTypeEnum: BookSourceType {
        get { BookSourceType(rawValue: sourceType) ?? .manual }
        set { sourceType = newValue.rawValue }
    }

    var subjectsArray: [String] {
        get {
            guard let s = subjectsData, !s.isEmpty else { return [] }
            return s.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
        }
        set { subjectsData = newValue.isEmpty ? nil : newValue.joined(separator: ",") }
    }

    var progressPercent: Double {
        guard totalPages > 0 else { return 0 }
        return min(100, Double(currentPage) / Double(totalPages) * 100)
    }

    var displayRating: Int? {
        let r = rating
        guard r > 0 else { return nil }
        return Int(r)
    }

    /// If the user (or old data) picks "Want to read" but progress exists, treat as Reading.
    func resolvedReadingStatus(for requested: ReadingStatus) -> ReadingStatus {
        if requested == .wantToRead && currentPage > 0 {
            return .reading
        }
        return requested
    }

    func normalizeWantToReadAgainstProgress(using context: NSManagedObjectContext) {
        guard currentPage > 0, statusEnum == .wantToRead else { return }
        statusEnum = .reading
        if dateStarted == nil { dateStarted = Date() }
        try? context.save()
    }

    static func normalizeAllWantToReadAgainstProgress(using context: NSManagedObjectContext) {
        let req = Book.fetchRequest()
        guard let all = try? context.fetch(req) else { return }
        var changed = false
        for b in all where b.currentPage > 0 && b.statusEnum == .wantToRead {
            b.statusEnum = .reading
            if b.dateStarted == nil { b.dateStarted = Date() }
            changed = true
        }
        if changed { try? context.save() }
    }
}

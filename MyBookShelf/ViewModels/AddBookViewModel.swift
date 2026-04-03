//
//  AddBookViewModel.swift
//  MyBookShelf
//

import Combine
import CoreData
import SwiftUI

/// Limits and rules for the manual “add book” form.
enum ManualAddBookFieldLimits {
    static let titleMax = 200
    static let authorMax = 160
    static let pagesMin = 1
    static let pagesMax = 50_000
    static let customGenreMax = 64
    static let isbnMax = 32
    static let yearMin = 1000
    static var yearMax: Int {
        Calendar.current.component(.year, from: Date()) + 5
    }
}

@MainActor
final class AddBookViewModel: ObservableObject {
    @Published var title = ""
    @Published var author = ""
    @Published var totalPages = 0
    @Published var genre = "Fiction"
    @Published var customGenre = ""
    @Published var publishYear = ""
    @Published var isbn = ""
    @Published var status: ReadingStatus = .wantToRead
    @Published var coverImage: UIImage?
    /// After user taps Add while the form is invalid — show red borders + messages on required fields.
    @Published var showValidationErrors = false

    private let context = PersistenceController.shared.container.viewContext

    var normalizedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var normalizedAuthor: String {
        author.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var normalizedCustomGenre: String {
        customGenre.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var sanitizedIsbn: String {
        isbn.filter { $0.isNumber || $0 == "X" || $0 == "x" || $0 == "-" || $0 == " " }
    }

    /// Shown under the title field (red when non-nil).
    var titleFieldError: String? {
        if normalizedTitle.isEmpty {
            return showValidationErrors ? "Enter a title." : nil
        }
        return nil
    }

    var authorFieldError: String? {
        if normalizedAuthor.isEmpty {
            return showValidationErrors ? "Enter the author." : nil
        }
        return nil
    }

    var pagesFieldError: String? {
        if totalPages < ManualAddBookFieldLimits.pagesMin {
            return showValidationErrors
                ? "Enter a page count from \(ManualAddBookFieldLimits.pagesMin) to \(ManualAddBookFieldLimits.pagesMax)."
                : nil
        }
        if totalPages > ManualAddBookFieldLimits.pagesMax {
            return "Page count cannot exceed \(ManualAddBookFieldLimits.pagesMax)."
        }
        return nil
    }

    var customGenreFieldError: String? {
        guard genre == "Other" else { return nil }
        if normalizedCustomGenre.isEmpty {
            return showValidationErrors ? "Enter a genre name or pick another category." : nil
        }
        return nil
    }

    /// Optional: highlight while the year is incomplete or out of range.
    var yearFieldError: String? {
        guard !publishYear.isEmpty else { return nil }
        if publishYear.count < 4 {
            return "Enter 4 digits · \(ManualAddBookFieldLimits.yearMin)–\(ManualAddBookFieldLimits.yearMax)."
        }
        guard let y = Int(publishYear) else {
            return "Use digits only."
        }
        if y < ManualAddBookFieldLimits.yearMin || y > ManualAddBookFieldLimits.yearMax {
            return "Year must be \(ManualAddBookFieldLimits.yearMin)–\(ManualAddBookFieldLimits.yearMax)."
        }
        return nil
    }

    var isbnFieldError: String? {
        guard !isbn.isEmpty else { return nil }
        if sanitizedIsbn.count > ManualAddBookFieldLimits.isbnMax {
            return "Too long — max \(ManualAddBookFieldLimits.isbnMax) characters."
        }
        let core = sanitizedIsbn.filter { $0.isNumber || $0 == "X" || $0 == "x" }
        if core.count < 10 {
            return "At least 10 digits (or X for ISBN-10). Hyphens/spaces are OK."
        }
        return nil
    }

    var canSave: Bool {
        if normalizedTitle.isEmpty || normalizedAuthor.isEmpty { return false }
        if totalPages < ManualAddBookFieldLimits.pagesMin || totalPages > ManualAddBookFieldLimits.pagesMax { return false }
        if genre == "Other", normalizedCustomGenre.isEmpty { return false }
        if !publishYear.isEmpty {
            guard publishYear.count == 4, let y = Int(publishYear),
                  y >= ManualAddBookFieldLimits.yearMin, y <= ManualAddBookFieldLimits.yearMax else { return false }
        }
        if !isbn.isEmpty {
            if sanitizedIsbn.count > ManualAddBookFieldLimits.isbnMax { return false }
            let core = sanitizedIsbn.filter { $0.isNumber || $0 == "X" || $0 == "x" }
            if core.count < 10 { return false }
        }
        return true
    }

    func noteInvalidSaveAttempt() {
        showValidationErrors = true
    }

    func clearValidationHighlightIfFormValid() {
        if canSave { showValidationErrors = false }
    }

    // MARK: - Bindings with caps / filtering (use from ManualAddBookView)

    func bindingTitle() -> Binding<String> {
        Binding(
            get: { self.title },
            set: { self.title = String($0.prefix(ManualAddBookFieldLimits.titleMax)) }
        )
    }

    func bindingAuthor() -> Binding<String> {
        Binding(
            get: { self.author },
            set: { self.author = String($0.prefix(ManualAddBookFieldLimits.authorMax)) }
        )
    }

    func bindingTotalPages() -> Binding<Int> {
        Binding(
            get: { self.totalPages },
            set: { self.totalPages = min(max(0, $0), ManualAddBookFieldLimits.pagesMax) }
        )
    }

    func bindingCustomGenre() -> Binding<String> {
        Binding(
            get: { self.customGenre },
            set: { self.customGenre = String($0.prefix(ManualAddBookFieldLimits.customGenreMax)) }
        )
    }

    func bindingPublishYear() -> Binding<String> {
        Binding(
            get: { self.publishYear },
            set: { new in
                let digits = new.filter(\.isNumber)
                self.publishYear = String(digits.prefix(4))
            }
        )
    }

    func bindingIsbn() -> Binding<String> {
        Binding(
            get: { self.isbn },
            set: { new in
                let filtered = new.filter { $0.isNumber || $0 == "X" || $0 == "x" || $0 == "-" || $0 == " " }
                self.isbn = String(filtered.prefix(ManualAddBookFieldLimits.isbnMax))
            }
        )
    }

    func save() {
        guard canSave else { return }
        let book = Book(context: context)
        book.id = UUID()
        book.title = normalizedTitle
        book.author = normalizedAuthor
        book.totalPages = Int32(totalPages)
        book.currentPage = 0
        book.genre = genre == "Other" ? normalizedCustomGenre : genre
        if let y = Int(publishYear), y >= ManualAddBookFieldLimits.yearMin, y <= ManualAddBookFieldLimits.yearMax {
            book.publishYear = Int32(y)
        } else {
            book.publishYear = 0
        }
        let isbnStored = sanitizedIsbn.replacingOccurrences(of: " ", with: "")
        book.isbn = isbnStored.isEmpty ? nil : isbnStored
        book.status = status.rawValue
        book.dateAdded = Date()
        book.sourceType = BookSourceType.manual.rawValue
        book.notes = ""
        if status == .reading {
            book.dateStarted = Date()
        }
        if let img = coverImage, let id = book.id {
            if let path = CacheService.shared.saveCover(img, bookId: id) {
                book.localCoverImagePath = path
            }
        }
        let profile = fetchProfile()
        GamificationEngine.shared.processBookAdded(profile: profile, context: context)
        try? context.save()
    }

    private func fetchProfile() -> UserProfile {
        let req = UserProfile.fetchRequest()
        req.fetchLimit = 1
        return (try? context.fetch(req))?.first ?? UserProfile(context: context)
    }
}

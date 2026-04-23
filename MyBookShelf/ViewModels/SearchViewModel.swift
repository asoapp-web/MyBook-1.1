import Combine
import CoreData
import Foundation
import SwiftUI

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var query = ""
    @Published var results: [OpenLibraryDoc] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasSearched = false

    private var task: Task<Void, Never>?
    private let context = PersistenceController.shared.container.viewContext

    func search() {
        task?.cancel()
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            results = []
            hasSearched = false
            return
        }
        hasSearched = true
        isLoading = true
        errorMessage = nil
        let q = query
        task = Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            guard !Task.isCancelled else { return }
            do {
                let resp = try await NetworkService.shared.search(query: q, limit: 20)
                if !Task.isCancelled {
                    results = resp.docs
                }
            } catch {
                if !Task.isCancelled {
                    switch error as? NetworkError {
                    case .noConnection:
                        errorMessage = "No internet connection.\nTry adding a book manually."
                    case .httpError(let code) where code == 503 || code == 502:
                        errorMessage = "Search service is temporarily unavailable.\nPlease try again in a moment."
                    case .httpError:
                        errorMessage = "Search returned an error.\nPlease try again."
                    default:
                        errorMessage = "Request timed out.\nCheck your connection and try again."
                    }
                    results = []
                }
            }
            if !Task.isCancelled {
                isLoading = false
            }
        }
    }

    func addBook(from doc: OpenLibraryDoc, status: ReadingStatus) {
        let book = Book(context: context)
        book.id = UUID()
        book.title = doc.title ?? "Unknown"
        book.author = doc.author_name?.joined(separator: ", ") ?? "Unknown"
        book.totalPages = Int32(doc.number_of_pages_median ?? 0)
        book.currentPage = 0
        book.genre = "Fiction"
        book.status = status.rawValue
        book.isbn = doc.isbn?.first
        if let cid = doc.cover_i {
            book.coverImageURL = NetworkService.coverURL(coverId: cid)
        } else if let isbn = book.isbn, let url = NetworkService.isbnCoverURL(isbn: isbn) {
            book.coverImageURL = url
        }
        book.openLibraryKey = doc.key
        book.publishYear = doc.first_publish_year.map { Int32($0) } ?? 0
        book.dateAdded = Date()
        book.sourceType = BookSourceType.openLibrary.rawValue
        book.notes = ""
        book.subjectsArray = Array((doc.subject ?? []).prefix(5))
        book.statusEnum = status
        if status == .reading {
            book.dateStarted = Date()
        }
        let bookId = book.id!
        Task {
            await resolveAndCacheCovers(forBookId: bookId)
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

    private func resolveAndCacheCovers(forBookId bookId: UUID) async {
        let req = Book.fetchRequest()
        req.fetchLimit = 1
        req.predicate = NSPredicate(format: "id == %@", bookId as CVarArg)
        guard let book = try? context.fetch(req).first else { return }

        var urls: [String] = []
        if let u = book.coverImageURL, !u.isEmpty { urls.append(u) }
        if let isbn = book.isbn, let u = NetworkService.isbnCoverURL(isbn: isbn), !urls.contains(u) {
            urls.append(u)
        }

        for urlStr in urls {
            if let img = await CoverImageLoadService.shared.image(forURLString: urlStr) {
                CacheService.shared.cacheImage(img, for: bookId.uuidString)
                let path = CacheService.shared.path(for: bookId.uuidString).path
                book.localCoverImagePath = path
                try? context.save()
                return
            }
        }
    }
}

import CoreData
import Foundation

enum MBSExportService {

    struct ExportDocument: Codable {
        let exportedAt: String
        let books: [ExportBook]
    }

    struct ExportBook: Codable {
        let title: String
        let author: String
        let genre: String
        let status: String
        let currentPage: Int
        let totalPages: Int
        let rating: Int
        let isFavorite: Bool
        let dateStarted: String?
        let dateFinished: String?
        let notes: String
        let sessions: [ExportSession]
    }

    struct ExportSession: Codable {
        let date: String?
        let pagesRead: Int
        let durationMinutes: Int
    }

    static func buildJSON(context: NSManagedObjectContext) throws -> Data {
        let req = Book.fetchRequest()
        req.sortDescriptors = [NSSortDescriptor(keyPath: \Book.title, ascending: true)]
        let books = try context.fetch(req)

        let iso = ISO8601DateFormatter()
        let doc = ExportDocument(
            exportedAt: iso.string(from: Date()),
            books: books.map { book in
                let sessions = (book.readingSessions as? Set<ReadingSession> ?? [])
                    .sorted { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }
                return ExportBook(
                    title: book.title ?? "",
                    author: book.author ?? "",
                    genre: book.genre ?? "",
                    status: book.statusEnum.label,
                    currentPage: Int(book.currentPage),
                    totalPages: Int(book.totalPages),
                    rating: Int(book.rating),
                    isFavorite: book.isFavorite,
                    dateStarted: book.dateStarted.map { iso.string(from: $0) },
                    dateFinished: book.dateFinished.map { iso.string(from: $0) },
                    notes: book.notes ?? "",
                    sessions: sessions.map {
                        ExportSession(
                            date: $0.date.map { iso.string(from: $0) },
                            pagesRead: Int($0.pagesRead),
                            durationMinutes: Int($0.durationMinutes)
                        )
                    }
                )
            }
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(doc)
    }

    static func buildCSV(context: NSManagedObjectContext) throws -> Data {
        let req = Book.fetchRequest()
        req.sortDescriptors = [NSSortDescriptor(keyPath: \Book.title, ascending: true)]
        let books = try context.fetch(req)

        var csv = "Title,Author,Genre,Status,Current Page,Total Pages,Rating,Favorite,Date Started,Date Finished,Notes\n"
        let iso = ISO8601DateFormatter()
        for book in books {
            let row = [
                escape(book.title ?? ""),
                escape(book.author ?? ""),
                escape(book.genre ?? ""),
                book.statusEnum.label,
                "\(book.currentPage)",
                "\(book.totalPages)",
                "\(book.rating)",
                book.isFavorite ? "Yes" : "No",
                book.dateStarted.map { iso.string(from: $0) } ?? "",
                book.dateFinished.map { iso.string(from: $0) } ?? "",
                escape(book.notes ?? "")
            ].joined(separator: ",")
            csv += row + "\n"
        }
        return Data(csv.utf8)
    }

    static func writeToTemp(data: Data, filename: String) throws -> URL {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try data.write(to: tmp, options: .atomic)
        return tmp
    }

    private static func escape(_ s: String) -> String {
        let escaped = s.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }
}

//
//  NetworkService.swift
//  MyBookShelf
//

import Foundation

struct OpenLibrarySearchResponse: Decodable {
    let numFound: Int
    let start: Int
    let docs: [OpenLibraryDoc]
}

struct OpenLibraryDoc: Decodable {
    let key: String?
    let title: String?
    let subtitle: String?
    let author_name: [String]?
    let cover_i: Int?
    let first_publish_year: Int?
    let number_of_pages_median: Int?
    let subject: [String]?
    let isbn: [String]?
    let publisher: [String]?
    let language: [String]?
    let edition_count: Int?
    let ratings_average: Double?
    let ratings_count: Int?
    let already_read_count: Int?
    let want_to_read_count: Int?
}

enum NetworkError: Error {
    case noConnection
    case invalidURL
    case httpError(Int)
}

final class NetworkService {
    static let shared = NetworkService()
    private let baseURL = "https://openlibrary.org"
    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity = true
        session = URLSession(configuration: config)
    }

    func search(query: String, limit: Int = 20) async throws -> OpenLibrarySearchResponse {
        guard var comp = URLComponents(string: "\(baseURL)/search.json") else {
            Self.log("search: invalid URL components")
            throw NetworkError.invalidURL
        }
        let fields = "key,title,subtitle,author_name,cover_i,first_publish_year,number_of_pages_median,subject,isbn,publisher,language,edition_count,ratings_average,ratings_count,already_read_count,want_to_read_count"
        comp.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "fields", value: fields),
        ]
        guard let url = comp.url else {
            Self.log("search: failed to build URL")
            throw NetworkError.invalidURL
        }

        Self.log("GET \(url.absoluteString)")

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(from: url)
        } catch {
            Self.log("search: transport error — \(error.localizedDescription)")
            throw NetworkError.noConnection
        }

        guard let http = response as? HTTPURLResponse else {
            Self.log("search: response is not HTTP")
            throw NetworkError.noConnection
        }
        Self.log("search: status=\(http.statusCode) bytes=\(data.count)")

        guard (200...299).contains(http.statusCode) else {
            if let body = String(data: data.prefix(1500), encoding: .utf8) {
                Self.log("search: error body prefix — \(body)")
            }
            throw NetworkError.httpError(http.statusCode)
        }

        let decoder = JSONDecoder()
        do {
            let decoded = try decoder.decode(OpenLibrarySearchResponse.self, from: data)
            Self.log("search: OK numFound=\(decoded.numFound) start=\(decoded.start) docs.count=\(decoded.docs.count)")
            if let first = decoded.docs.first {
                Self.log("search: first doc key=\(first.key ?? "nil") title=\(first.title ?? "nil")")
            }
            return decoded
        } catch {
            Self.log("search: JSON decode failed — \(error)")
            if let snippet = String(data: data.prefix(2500), encoding: .utf8) {
                Self.log("search: body prefix — \(snippet)")
            }
            throw error
        }
    }

    static var isLoggingEnabled = true

    private static func log(_ message: String) {
        guard isLoggingEnabled else { return }
        #if DEBUG
        print("[MyBookShelf API] \(message)")
        #endif
    }

    static func coverURL(coverId: Int, size: String = "M") -> String {
        "https://covers.openlibrary.org/b/id/\(coverId)-\(size).jpg"
    }

    /// When `cover_i` is missing, Open Library can still serve a cover by ISBN.
    static func isbnCoverURL(isbn: String, size: String = "M") -> String? {
        let cleaned = isbn.replacingOccurrences(of: "-", with: "").replacingOccurrences(of: " ", with: "")
        guard cleaned.count >= 10 else { return nil }
        return "https://covers.openlibrary.org/b/isbn/\(cleaned)-\(size).jpg"
    }
}

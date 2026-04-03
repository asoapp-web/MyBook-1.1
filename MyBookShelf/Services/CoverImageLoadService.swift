//
//  CoverImageLoadService.swift
//  MyBookShelf
//

import UIKit

private enum CoverDownloadLog {
    static var isEnabled = true
    static func log(_ message: String) {
        guard isEnabled else { return }
        #if DEBUG
        print("[MyBookShelf Cover] \(message)")
        #endif
    }
}

/// Deduplicates in-flight cover downloads, limits host concurrency via URLSession, uses timeouts so rows never spin forever.
private enum CoverImageURLSession {
    static let shared: URLSession = {
        let c = URLSessionConfiguration.default
        c.timeoutIntervalForRequest = 12
        c.timeoutIntervalForResource = 25
        c.httpMaximumConnectionsPerHost = 4
        c.requestCachePolicy = .returnCacheDataElseLoad
        return URLSession(configuration: c)
    }()
}

actor CoverImageLoadService {
    static let shared = CoverImageLoadService()

    private var inFlight: [String: Task<UIImage?, Never>] = [:]

    func image(forURLString urlString: String) async -> UIImage? {
        if let disk = CacheService.shared.getImage(for: urlString) {
            CoverDownloadLog.log("disk cache hit \(urlString.prefix(90))…")
            return disk
        }
        if let existing = inFlight[urlString] {
            return await existing.value
        }
        let task = Task<UIImage?, Never> {
            await Self.download(urlString: urlString)
        }
        inFlight[urlString] = task
        defer { inFlight[urlString] = nil }
        return await task.value
    }

    private nonisolated static func download(urlString: String) async -> UIImage? {
        guard let url = URL(string: urlString) else {
            CoverDownloadLog.log("invalid URL string")
            return nil
        }
        CoverDownloadLog.log("GET cover \(url.absoluteString)")
        do {
            let (data, response) = try await CoverImageURLSession.shared.data(from: url)
            if Task.isCancelled {
                CoverDownloadLog.log("cancelled \(url.lastPathComponent)")
                return nil
            }
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            CoverDownloadLog.log("cover response status=\(status) bytes=\(data.count) \(url.lastPathComponent)")
            guard let img = UIImage(data: data), img.size.width > 1, img.size.height > 1 else {
                CoverDownloadLog.log("cover: not a valid image \(url.lastPathComponent)")
                return nil
            }
            CacheService.shared.cacheImage(img, for: urlString)
            CoverDownloadLog.log("cover cached on disk (\(data.count) bytes) \(url.lastPathComponent)")
            return img
        } catch {
            CoverDownloadLog.log("cover error — \(error.localizedDescription) \(url.lastPathComponent)")
            return nil
        }
    }
}

extension CoverImageLoadService {
    /// Set `false` to silence cover download prints.
    nonisolated static var isCoverLoggingEnabled: Bool {
        get { CoverDownloadLog.isEnabled }
        set { CoverDownloadLog.isEnabled = newValue }
    }
}

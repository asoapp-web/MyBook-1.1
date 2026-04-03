//
//  CacheService.swift
//  MyBookShelf
//

import UIKit

/// Persists cover JPEGs on disk. Library covers live under Application Support so iOS does not wipe them
/// when clearing the temp cache (unlike Caches directory).
final class CacheService {
    static let shared = CacheService()
    private let fileManager = FileManager.default
    /// Durable storage for book covers and URL-keyed thumbnails (survives low-storage cache purge).
    private let coversDir: URL
    private let avatarsDir: URL

    private init() {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        coversDir = appSupport.appendingPathComponent("BookCovers", isDirectory: true)
        avatarsDir = appSupport.appendingPathComponent("ProfileAvatars", isDirectory: true)
        try? fileManager.createDirectory(at: coversDir, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: avatarsDir, withIntermediateDirectories: true)
        #if DEBUG
        print("[MyBookShelf] Covers stored on disk: \(coversDir.path)")
        #endif
    }

    func saveProfileAvatar(_ image: UIImage, profileId: UUID) -> String? {
        let url = avatarsDir.appendingPathComponent("\(profileId.uuidString).jpg")
        let square = image.mb_croppedToSquare(maxPixelSide: 512)
        guard let data = square.jpegData(compressionQuality: 0.88) else { return nil }
        try? data.write(to: url, options: .atomic)
        return url.path
    }

    func deleteProfileAvatarFile(at path: String) {
        let url = URL(fileURLWithPath: path)
        guard url.path.hasPrefix(avatarsDir.path) else { return }
        try? fileManager.removeItem(at: url)
    }

    func path(for key: String) -> URL {
        coversDir.appendingPathComponent("\(stableFileKey(key)).jpg")
    }

    /// UUIDs (book ids) stay readable; URLs get a short stable hash (FNV-1a) — no CryptoKit, not encryption, filenames only.
    private func stableFileKey(_ string: String) -> String {
        if string.count == 36, string.filter({ $0 == "-" }).count == 4 {
            return string
        }
        var hash: UInt64 = 14_695_981_039_346_656_037 // FNV-1a 64-bit offset
        for byte in string.utf8 {
            hash ^= UInt64(byte)
            hash &*= 1_099_511_628_211
        }
        return String(format: "%016llx", hash)
    }

    func getImage(for urlString: String) -> UIImage? {
        let fileURL = path(for: urlString)
        guard fileManager.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL),
              let img = UIImage(data: data) else { return nil }
        return img
    }

    func getImage(path: String) -> UIImage? {
        let url = URL(fileURLWithPath: path)
        guard let data = try? Data(contentsOf: url), let img = UIImage(data: data) else { return nil }
        return img
    }

    func cacheImage(_ image: UIImage, for key: String) {
        let url = path(for: key)
        if let data = image.jpegData(compressionQuality: 0.85) {
            try? data.write(to: url, options: .atomic)
        }
    }

    func saveCover(_ image: UIImage, bookId: UUID) -> String? {
        let key = bookId.uuidString
        let cropped = image.mb_croppedToBookCoverAspect()
        cacheImage(cropped, for: key)
        return path(for: key).path
    }

    func clearCache() {
        try? fileManager.contentsOfDirectory(at: coversDir, includingPropertiesForKeys: nil)
            .forEach { try? fileManager.removeItem(at: $0) }
    }
}

// MARK: - Book cover aspect (2:3)

extension UIImage {
    /// Center-crop to portrait book proportions (width : height = 2 : 3) before persisting.
    func mb_croppedToBookCoverAspect() -> UIImage {
        let upright: UIImage
        if imageOrientation == .up {
            upright = self
        } else {
            let format = UIGraphicsImageRendererFormat()
            format.scale = scale
            upright = UIGraphicsImageRenderer(size: size, format: format).image { _ in
                draw(in: CGRect(origin: .zero, size: size))
            }
        }
        guard let cg = upright.cgImage else { return self }
        let pw = CGFloat(cg.width)
        let ph = CGFloat(cg.height)
        guard pw > 1, ph > 1 else { return self }
        let targetAspect: CGFloat = 2.0 / 3.0
        let imgAspect = pw / ph
        let crop: CGRect
        if imgAspect > targetAspect {
            let newW = floor(ph * targetAspect)
            let x = floor((pw - newW) / 2)
            crop = CGRect(x: x, y: 0, width: newW, height: ph)
        } else {
            let newH = floor(pw / targetAspect)
            let y = floor((ph - newH) / 2)
            crop = CGRect(x: 0, y: y, width: pw, height: newH)
        }
        guard let cropped = cg.cropping(to: crop) else { return self }
        return UIImage(cgImage: cropped, scale: upright.scale, orientation: .up)
    }

    /// Center square crop, then downscale so the longest side is at most `maxPixelSide`.
    func mb_croppedToSquare(maxPixelSide: CGFloat) -> UIImage {
        let upright: UIImage
        if imageOrientation == .up {
            upright = self
        } else {
            let format = UIGraphicsImageRendererFormat()
            format.scale = scale
            upright = UIGraphicsImageRenderer(size: size, format: format).image { _ in
                draw(in: CGRect(origin: .zero, size: size))
            }
        }
        guard let cg = upright.cgImage else { return self }
        let pw = CGFloat(cg.width)
        let ph = CGFloat(cg.height)
        guard pw > 1, ph > 1 else { return self }
        let side = min(pw, ph)
        let x = floor((pw - side) / 2)
        let y = floor((ph - side) / 2)
        let crop = CGRect(x: x, y: y, width: side, height: side)
        guard let cropped = cg.cropping(to: crop) else { return self }
        var img = UIImage(cgImage: cropped, scale: upright.scale, orientation: .up)
        let maxDim = max(img.size.width, img.size.height) * img.scale
        guard maxDim > maxPixelSide, maxPixelSide > 0 else { return img }
        let scale = maxPixelSide / maxDim
        let newSize = CGSize(width: floor(img.size.width * scale), height: floor(img.size.height * scale))
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: newSize, format: format).image { _ in
            img.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

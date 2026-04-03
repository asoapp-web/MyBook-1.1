//
//  BookCoverView.swift
//  MyBookShelf
//

import CoreData
import SwiftUI

struct BookCoverView: View {
    let book: Book
    var size: CGSize = CGSize(width: 80, height: 120)

    var body: some View {
        Group {
            if let path = book.localCoverImagePath, let img = CacheService.shared.getImage(path: path) {
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if let urlStr = book.coverImageURL, !urlStr.isEmpty {
                AsyncBookCover(urlString: urlStr, size: size, book: book)
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(AppTheme.backgroundTertiary)
                    .overlay(
                        Image(systemName: "book.closed.fill")
                            .font(.system(size: size.width * 0.35))
                            .foregroundStyle(AppTheme.textMuted)
                    )
            }
        }
        .frame(width: size.width, height: size.height)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct AsyncBookCover: View {
    let urlString: String
    var size: CGSize = CGSize(width: 80, height: 120)
    /// When set, a successful download is copied to the book’s durable cover file for offline use.
    var book: Book? = nil
    @State private var image: UIImage?
    @State private var loadFailed = false

    var body: some View {
        Group {
            if let img = image ?? CacheService.shared.getImage(for: urlString) {
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if loadFailed {
                RoundedRectangle(cornerRadius: 6)
                    .fill(AppTheme.backgroundTertiary)
                    .overlay(
                        Image(systemName: "photo.badge.exclamationmark")
                            .font(.system(size: size.width * 0.28))
                            .foregroundStyle(AppTheme.textMuted)
                    )
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(AppTheme.backgroundTertiary)
                    .overlay(
                        ProgressView()
                            .tint(AppTheme.textMuted)
                            .scaleEffect(0.85)
                    )
            }
        }
        .frame(width: size.width, height: size.height)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .task(id: urlString) {
            loadFailed = false
            if let cached = CacheService.shared.getImage(for: urlString) {
                image = cached
                await MainActor.run {
                    persistStreamedCoverToLibrary(book: book, image: cached)
                }
                return
            }
            image = nil
            let loaded = await CoverImageLoadService.shared.image(forURLString: urlString)
            guard !Task.isCancelled else { return }
            if let loaded {
                image = loaded
                await MainActor.run {
                    persistStreamedCoverToLibrary(book: book, image: loaded)
                }
            } else {
                loadFailed = true
            }
        }
    }
}

@MainActor
private func persistStreamedCoverToLibrary(book: Book?, image: UIImage) {
    guard let book = book, book.managedObjectContext != nil, let id = book.id else { return }
    if let path = book.localCoverImagePath, FileManager.default.fileExists(atPath: path) { return }
    guard let pathStr = CacheService.shared.saveCover(image, bookId: id) else { return }
    book.localCoverImagePath = pathStr
    try? book.managedObjectContext?.save()
    #if DEBUG
    print("[MyBookShelf] Streamed cover saved for offline id=\(id)")
    #endif
}

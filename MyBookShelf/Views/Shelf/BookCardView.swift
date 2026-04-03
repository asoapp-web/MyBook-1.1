//
//  BookCardView.swift
//  MyBookShelf
//

import CoreData
import SwiftUI

struct BookCardView: View {
    let book: Book
    let onDelete: (Book) -> Void
    var onUpdate: (() -> Void)?
    /// When false: cover + caption only (no frosted card chrome) — e.g. under cabinet glass.
    var usesShelfChrome: Bool = true

    private var readingWarmth: Double {
        guard book.statusEnum == .reading, book.totalPages > 0 else { return 0 }
        return min(0.42, book.progressPercent / 100 * 0.42)
    }

    private var finishedTint: Double {
        book.statusEnum == .finished ? 0.14 : 0
    }

    private var captionBlock: some View {
        VStack(spacing: 6) {
            Text(book.title ?? "")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
            if book.statusEnum == .reading, book.totalPages > 0 {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.1))
                        Capsule()
                            .fill(AppTheme.accentOrange)
                            .frame(width: max(2, geo.size.width * CGFloat(book.progressPercent / 100)))
                    }
                }
                .frame(width: 64, height: 3)
            } else if let stars = book.displayRating {
                HStack(spacing: 1) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(AppTheme.accentOrange)
                    Text("\(stars)")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
        }
    }

    private var coverStack: some View {
        ZStack(alignment: .topTrailing) {
            BookCoverView(book: book, size: CGSize(width: 70, height: 105))
            if book.isFavorite {
                Image(systemName: "heart.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(AppTheme.accentOrange)
                    .padding(4)
                    .shadow(color: .black.opacity(0.6), radius: 2, y: 1)
            }
        }
    }

    private var bareBody: some View {
        VStack(spacing: 6) {
            coverStack
                .shadow(color: .black.opacity(0.5), radius: 10, y: 5)
            captionBlock
        }
        .frame(width: 80)
    }

    private var chromeBody: some View {
        VStack(spacing: 6) {
            coverStack
            captionBlock
        }
        .frame(width: 80)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [
                            AppTheme.accentOrange.opacity(readingWarmth),
                            Color.green.opacity(finishedTint),
                            Color.white.opacity(0.06),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    AppTheme.accentOrange.opacity(readingWarmth > 0 ? 0.55 : 0.2),
                                    Color.white.opacity(0.06),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: readingWarmth > 0 ? 1.5 : 1
                        )
                )
        )
    }

    var body: some View {
        Group {
            if usesShelfChrome {
                chromeBody
            } else {
                bareBody
            }
        }
        .contentShape(Rectangle())
        .contextMenu {
            Button(role: .destructive) {
                onDelete(book)
            } label: {
                Label("Delete", systemImage: "trash")
            }
            Button {
                let ctx = PersistenceController.shared.container.viewContext
                ShelfViewModel(context: ctx).toggleFavorite(book)
                onUpdate?()
            } label: {
                Label(book.isFavorite ? "Remove from favorites" : "Add to favorites", systemImage: book.isFavorite ? "heart.slash" : "heart")
            }
            Divider()
            ForEach(ReadingStatus.selectableCases(for: book).filter { $0 != book.statusEnum }, id: \.rawValue) { status in
                Button {
                    let ctx = PersistenceController.shared.container.viewContext
                    ShelfViewModel(context: ctx).setStatus(book, status: status)
                    onUpdate?()
                } label: {
                    Label(status.label, systemImage: "book")
                }
            }
        }
    }
}

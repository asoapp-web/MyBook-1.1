//
//  FavoriteBooksView.swift
//  MyBookShelf
//

import CoreData
import SwiftUI

struct FavoriteBooksView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Book.dateAdded, ascending: false)],
        predicate: NSPredicate(format: "isFavorite == YES"),
        animation: .default
    )
    private var favoriteBooks: FetchedResults<Book>

    var body: some View {
        Group {
            if favoriteBooks.isEmpty {
                EmptyStateView(
                    icon: "heart",
                    title: "No favorites yet",
                    message: "Tap the heart on a book’s detail screen or use “Add to favorites” on the shelf card."
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(favoriteBooks, id: \.objectID) { book in
                            NavigationLink {
                                BookDetailView(book: book, onDelete: nil)
                            } label: {
                                favoriteRow(book)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(16)
                    .padding(.bottom, 8)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.background)
        .navigationTitle("Favorites")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppTheme.background.opacity(0.95), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private func favoriteRow(_ book: Book) -> some View {
        HStack(spacing: 14) {
            BookCoverView(book: book, size: CGSize(width: 48, height: 72))
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            VStack(alignment: .leading, spacing: 4) {
                Text(book.title ?? "")
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Text(book.author ?? "")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(1)
                Text(book.statusEnum.label)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(AppTheme.textMuted)
            }
            Spacer(minLength: 8)
            Image(systemName: "heart.fill")
                .font(.body.weight(.semibold))
                .foregroundStyle(AppTheme.accentOrange)
        }
        .padding(12)
        .background(AppTheme.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}

/// Profile entry: opens favorites list; count from Core Data (no extra save logic).
struct ProfileFavoritesEntryRow: View {
    @FetchRequest(
        sortDescriptors: [],
        predicate: NSPredicate(format: "isFavorite == YES")
    )
    private var favorites: FetchedResults<Book>

    var body: some View {
        NavigationLink {
            FavoriteBooksView()
        } label: {
            HStack {
                Image(systemName: "heart.fill")
                Text("Favorites")
                Spacer()
                if !favorites.isEmpty {
                    Text("\(favorites.count)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.textMuted)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(AppTheme.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .foregroundStyle(AppTheme.textPrimary)
    }
}

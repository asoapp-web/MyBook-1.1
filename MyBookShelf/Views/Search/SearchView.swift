//
//  SearchView.swift
//  MyBookShelf
//

import SwiftUI

struct SearchView: View {
    @StateObject private var vm = SearchViewModel()
    @State private var mode = 0
    @State private var selectedDoc: OpenLibraryDoc?
    @FocusState private var searchFocused: Bool
    var tabBarHeight: CGFloat = 118

    var body: some View {
        NavigationStack {
            ZStack {
                MBSAtmosphereBackground()
                VStack(spacing: 0) {
                    MBSTextFieldChrome(
                        placeholder: "Search books...",
                        text: $vm.query,
                        onSubmit: { vm.search() }
                    )
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                    MBSSegmentPickerChrome(
                        options: [("Search online", 0), ("Add manually", 1)],
                        selection: $mode
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)

                    if mode == 0 {
                        searchResults
                    } else {
                        ManualAddBookView(tabBarClearance: tabBarHeight + 36)
                    }
                }

                if let doc = selectedDoc {
                    MBSPopupOverlay(isPresented: Binding(
                        get: { selectedDoc != nil },
                        set: { if !$0 { selectedDoc = nil } }
                    ), title: "Add book", maxWidth: 420) {
                        BookPreviewContent(doc: doc, vm: vm, onDismiss: { selectedDoc = nil })
                    }
                    .zIndex(50)
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(AppTheme.background.opacity(0.95), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onChange(of: vm.query) { _ in
                vm.search()
            }
        }
    }

    @ViewBuilder
    private var searchResults: some View {
        if vm.isLoading {
            Spacer()
            ProgressView().tint(AppTheme.accentLamp)
            Spacer()
        } else if let err = vm.errorMessage {
            Spacer()
            EmptyStateView(
                icon: "wifi.slash",
                title: "Could not load results",
                message: err,
                actionTitle: "Try Again",
                onAction: { vm.search() }
            )
            Spacer()
        } else if vm.results.isEmpty && vm.hasSearched {
            Spacer()
            EmptyStateView(icon: "magnifyingglass", title: "No results", message: "Try a different search.")
            Spacer()
        } else if vm.results.isEmpty {
            Spacer()
            Text("Search for books by title or author")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textMuted)
            Spacer()
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(Array(vm.results.enumerated()), id: \.offset) { _, doc in
                        SearchResultRow(doc: doc) { selectedDoc = doc }
                    }
                }
                .padding(16)
                .padding(.bottom, tabBarHeight + 24)
            }
        }
    }
}

struct SearchResultRow: View {
    let doc: OpenLibraryDoc
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                if let coverId = doc.cover_i {
                    AsyncBookCover(
                        urlString: NetworkService.coverURL(coverId: coverId, size: "S"),
                        size: CGSize(width: 50, height: 75)
                    )
                } else {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(AppTheme.backgroundTertiary)
                        .frame(width: 50, height: 75)
                        .overlay(Image(systemName: "book.closed").foregroundStyle(AppTheme.textMuted))
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(doc.title ?? "Unknown")
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)
                        .lineLimit(2)
                    Text(doc.author_name?.joined(separator: ", ") ?? "Unknown")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                    HStack(spacing: 8) {
                        if let year = doc.first_publish_year { Text("\(year)") }
                        if let pages = doc.number_of_pages_median { Text("· \(pages) p.") }
                        if let rating = doc.ratings_average, rating > 0 {
                            HStack(spacing: 2) {
                                Image(systemName: "star.fill")
                                Text(String(format: "%.1f", rating))
                            }
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(AppTheme.textMuted)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(AppTheme.textMuted)
            }
            .padding(12)
            .background(AppTheme.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

extension OpenLibraryDoc: @retroactive Identifiable {
    public var id: String { key ?? UUID().uuidString }
}

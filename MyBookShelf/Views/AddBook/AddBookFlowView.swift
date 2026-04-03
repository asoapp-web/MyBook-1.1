//
//  AddBookFlowView.swift
//  MyBookShelf
//

import SwiftUI

struct AddBookFlowView: View {
    let onDismiss: () -> Void
    @State private var mode = 0
    @StateObject private var searchVm = SearchViewModel()
    @State private var selectedDoc: OpenLibraryDoc?

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                VStack(spacing: 0) {
                    MBSSegmentPickerChrome(
                        options: [("Search online", 0), ("Add manually", 1)],
                        selection: $mode
                    )
                    .padding(16)

                    if mode == 0 {
                        searchContent
                    } else {
                        ManualAddBookView(onBookAdded: onDismiss)
                    }
                }

                if let doc = selectedDoc {
                    MBSPopupOverlay(isPresented: Binding(
                        get: { selectedDoc != nil },
                        set: { if !$0 { selectedDoc = nil } }
                    ), title: "Add book", maxWidth: 420) {
                        BookPreviewContent(doc: doc, vm: searchVm, onDismiss: {
                            selectedDoc = nil
                            onDismiss()
                        })
                    }
                    .zIndex(50)
                }
            }
            .navigationTitle("Add book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { onDismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private var searchContent: some View {
        VStack(spacing: 12) {
            MBSTextFieldChrome(
                placeholder: "Search books...",
                text: $searchVm.query,
                onSubmit: { searchVm.search() }
            )
            .padding(.horizontal, 16)

            if searchVm.isLoading {
                Spacer()
                ProgressView().tint(AppTheme.accentLamp)
                Spacer()
            } else if let err = searchVm.errorMessage {
                Spacer()
                EmptyStateView(icon: "wifi.slash", title: "Error", message: err)
                Spacer()
            } else if searchVm.results.isEmpty && searchVm.hasSearched {
                Spacer()
                EmptyStateView(icon: "magnifyingglass", title: "No results", message: "Try a different search.")
                Spacer()
            } else if searchVm.results.isEmpty {
                Spacer()
                Text("Search for books by title or author")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textMuted)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(Array(searchVm.results.enumerated()), id: \.offset) { _, doc in
                            SearchResultRow(doc: doc) { selectedDoc = doc }
                        }
                    }
                    .padding(16)
                }
            }
        }
        .onChange(of: searchVm.query) { _ in
            searchVm.search()
        }
    }
}

/// Used by both SearchView and AddBookFlowView popup overlays.
struct BookPreviewContent: View {
    let doc: OpenLibraryDoc
    @ObservedObject var vm: SearchViewModel
    let onDismiss: () -> Void
    @State private var status: ReadingStatus = .wantToRead

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let coverId = doc.cover_i {
                    AsyncBookCover(
                        urlString: NetworkService.coverURL(coverId: coverId, size: "L"),
                        size: CGSize(width: 120, height: 180)
                    )
                    .frame(maxWidth: .infinity)
                }

                Text(doc.title ?? "Unknown")
                    .font(.mbsDisplay(20))
                    .foregroundStyle(AppTheme.textPrimary)
                Text(doc.author_name?.joined(separator: ", ") ?? "Unknown")
                    .font(.mbsBody(14))
                    .foregroundStyle(AppTheme.textSecondary)

                HStack(spacing: 12) {
                    if let year = doc.first_publish_year { Label("\(year)", systemImage: "calendar") }
                    if let pages = doc.number_of_pages_median { Label("\(pages) p.", systemImage: "doc.plaintext") }
                }
                .font(.caption)
                .foregroundStyle(AppTheme.textMuted)

                if let rating = doc.ratings_average, let count = doc.ratings_count, count > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill").foregroundStyle(AppTheme.accentLamp).font(.caption)
                        Text(String(format: "%.1f", rating)).font(.subheadline.bold()).foregroundStyle(AppTheme.textPrimary)
                        Text("(\(count))").font(.caption).foregroundStyle(AppTheme.textMuted)
                    }
                }

                if let subjects = doc.subject, !subjects.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(subjects.prefix(6), id: \.self) { s in
                                Text(s)
                                    .font(.system(size: 11))
                                    .foregroundStyle(AppTheme.textSecondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(AppTheme.backgroundTertiary)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }

                Picker("Status", selection: $status) {
                    ForEach(ReadingStatus.allCases, id: \.rawValue) { s in
                        Text(s.label).tag(s)
                    }
                }
                .pickerStyle(.segmented)

                Button {
                    vm.addBook(from: doc, status: status)
                    HapticsService.shared.success()
                    onDismiss()
                } label: {
                    Text("Add to library")
                        .font(.mbsBody(16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(LinearGradient.mbsLampAccent)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
            .padding(20)
        }
        .frame(maxHeight: 520)
    }
}

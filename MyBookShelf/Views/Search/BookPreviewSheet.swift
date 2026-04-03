//
//  BookPreviewSheet.swift
//  MyBookShelf
//

import SwiftUI

struct BookPreviewSheet: View {
    let doc: OpenLibraryDoc
    @ObservedObject var vm: SearchViewModel
    let onDismiss: () -> Void
    @State private var status: ReadingStatus = .wantToRead

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let coverId = doc.cover_i {
                        AsyncBookCover(
                            urlString: NetworkService.coverURL(coverId: coverId, size: "L"),
                            size: CGSize(width: 140, height: 210)
                        )
                        .frame(maxWidth: .infinity)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(doc.title ?? "Unknown")
                            .font(.title2.bold())
                            .foregroundStyle(AppTheme.textPrimary)
                        if let subtitle = doc.subtitle, !subtitle.isEmpty {
                            Text(subtitle)
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                    Text(doc.author_name?.joined(separator: ", ") ?? "Unknown")
                        .font(.body)
                        .foregroundStyle(AppTheme.textSecondary)

                    HStack(spacing: 16) {
                        if let year = doc.first_publish_year {
                            Label("\(year)", systemImage: "calendar")
                        }
                        if let pages = doc.number_of_pages_median {
                            Label("\(pages) p.", systemImage: "doc.plaintext")
                        }
                        if let editions = doc.edition_count {
                            Label("\(editions) ed.", systemImage: "square.stack")
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(AppTheme.textMuted)

                    if let rating = doc.ratings_average, let count = doc.ratings_count, count > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .foregroundStyle(AppTheme.accentOrange)
                                .font(.caption)
                            Text(String(format: "%.1f", rating))
                                .font(.subheadline.bold())
                                .foregroundStyle(AppTheme.textPrimary)
                            Text("(\(count) ratings)")
                                .font(.caption)
                                .foregroundStyle(AppTheme.textMuted)
                        }
                    }

                    if let publishers = doc.publisher, !publishers.isEmpty {
                        Label(publishers.prefix(3).joined(separator: ", "), systemImage: "building.2")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textMuted)
                    }

                    if let languages = doc.language, !languages.isEmpty {
                        Label(languages.prefix(5).joined(separator: ", "), systemImage: "globe")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textMuted)
                    }

                    HStack(spacing: 16) {
                        if let readers = doc.already_read_count, readers > 0 {
                            Label("\(readers) read", systemImage: "checkmark.circle")
                        }
                        if let wtr = doc.want_to_read_count, wtr > 0 {
                            Label("\(wtr) want", systemImage: "bookmark")
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(AppTheme.textMuted)

                    if let subjects = doc.subject, !subjects.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(subjects.prefix(8), id: \.self) { s in
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
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AppTheme.accentOrange)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
                .padding(24)
            }
            .background(AppTheme.background)
            .navigationTitle("Add book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onDismiss() }
                }
            }
        }
    }
}

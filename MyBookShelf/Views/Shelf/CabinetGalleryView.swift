import SwiftUI

struct CabinetGalleryView: View {
    @ObservedObject var shelfVM: ShelfViewModel
    let onDismiss: () -> Void
    let onBooksChanged: () -> Void

    @State private var path = NavigationPath()

    private var paddedSlots: [Book?] {
        let books = shelfVM.books
        let n = books.count
        let rem = n % 3
        let pad = rem == 0 ? 0 : 3 - rem
        return books.map { Optional($0) } + Array(repeating: nil, count: pad)
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                CabinetBookshelfSceneView(slots: paddedSlots, navigationDepth: path.count) { book in
                    guard let id = book.id else { return }
                    path.append(id)
                }
                .ignoresSafeArea()

                if path.isEmpty {
                    VStack {
                        HStack {
                            Button {
                                HapticsService.shared.light()
                                onDismiss()
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "chevron.backward.circle.fill")
                                        .font(.system(size: 26))
                                    Text("Shelf")
                                        .font(.subheadline.weight(.semibold))
                                }
                                .foregroundStyle(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 11)
                                .background(
                                    Capsule()
                                        .fill(AppTheme.backgroundElevated.opacity(0.92))
                                        .overlay(Capsule().stroke(AppTheme.outlineLamp, lineWidth: 1))
                                )
                                .shadow(color: .black.opacity(0.5), radius: 12, y: 4)
                            }
                            .buttonStyle(.plain)
                            Spacer()
                        }
                        .padding(.leading, 16)
                        .padding(.top, 56)
                        Spacer()
                    }
                    .allowsHitTesting(true)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(AppTheme.background.opacity(0.92), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        HapticsService.shared.light()
                        if path.isEmpty {
                            onDismiss()
                        } else {
                            path.removeLast()
                        }
                    } label: {
                        Image(systemName: "chevron.backward.circle.fill")
                            .font(.system(size: 22))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(AppTheme.textPrimary)
                    }
                    .accessibilityLabel(path.isEmpty ? "Close cabinet" : "Back")
                }
                ToolbarItem(placement: .principal) {
                    Text(path.isEmpty ? "Cabinet" : "Book")
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Section("Sort books by") {
                            Picker("Sort", selection: Binding(
                                get: { shelfVM.sort },
                                set: { new in
                                    HapticsService.shared.selection()
                                    shelfVM.setSort(new)
                                }
                            )) {
                                ForEach(ShelfSort.allCases, id: \.rawValue) { option in
                                    Text(option.label).tag(option)
                                }
                            }
                            .pickerStyle(.inline)
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down.circle")
                    }
                    .accessibilityLabel("Sort and order")
                }
            }
            .navigationDestination(for: UUID.self) { id in
                CabinetBookOpenDetailView(bookId: id, onPop: { path.removeLast() }, onBooksChanged: onBooksChanged)
            }
        }
    }
}

import CoreData
import SwiftUI

struct CabinetBookOpenDetailView: View {
    let bookId: UUID
    let onPop: () -> Void
    let onBooksChanged: () -> Void

    @State private var open: CGFloat = 0

    @FetchRequest private var books: FetchedResults<Book>

    init(bookId: UUID, onPop: @escaping () -> Void, onBooksChanged: @escaping () -> Void) {
        self.bookId = bookId
        self.onPop = onPop
        self.onBooksChanged = onBooksChanged
        _books = FetchRequest(
            sortDescriptors: [],
            predicate: NSPredicate(format: "id == %@", bookId as CVarArg)
        )
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            if let b = books.first {
                BookDetailView(book: b, onDelete: onBooksChanged)
                    .opacity(Double(min(1, open * 1.12)))
                    .offset(y: CGFloat(36 * (1 - open)))
                    .scaleEffect(0.86 + 0.14 * open)

                if open < 0.97 {
                    BookCoverView(book: b, size: CGSize(width: 104, height: 156))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.55), radius: 20, y: 10)
                        .rotation3DEffect(
                            .degrees(-Double(88 * (1 - open))),
                            axis: (x: 0, y: 1, z: 0),
                            anchor: .leading,
                            perspective: 0.55
                        )
                        .padding(.leading, 16)
                        .padding(.top, 64)
                        .opacity(Double(1 - open * 0.92))
                        .allowsHitTesting(false)
                }
            } else {
                ProgressView()
                    .tint(AppTheme.accentOrange)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.background)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(AppTheme.background.opacity(0.92), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    HapticsService.shared.light()
                    onPop()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.backward.circle.fill")
                            .font(.system(size: 24))
                        Text("Cabinet")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(AppTheme.textPrimary)
                }
                .accessibilityLabel("Back to cabinet")
            }
        }
        .onAppear {
            open = 0
            withAnimation(.spring(response: 0.52, dampingFraction: 0.78)) {
                open = 1
            }
        }
    }
}

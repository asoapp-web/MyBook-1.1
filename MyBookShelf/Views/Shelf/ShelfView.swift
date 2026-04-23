import SwiftUI
import CoreData

struct ShelfView: View {
    @StateObject private var vm: ShelfViewModel
    @StateObject private var shelfProfileVM = ProfileViewModel()
    @EnvironmentObject private var tabState: MBSTabState
    @State private var showAddBook = false
    @State private var showDeleteConfirm: Book?
    @State private var showCabinetGallery = false
    @State private var showBookTreeComingSoon = false
    @State private var curtainOpacity: Double = 0
    @State private var cabinetContentOpacity: Double = 0
    var tabBarHeight: CGFloat = 118

    init(tabBarHeight: CGFloat = 118) {
        _vm = StateObject(wrappedValue: ShelfViewModel(context: PersistenceController.shared.container.viewContext))
        self.tabBarHeight = tabBarHeight
    }

    var body: some View {
        NavigationStack {
            ZStack {
                MBSAtmosphereBackground()

                VStack(spacing: 0) {
                    ShelfGamificationStrip(profileVM: shelfProfileVM)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 10)

                    NavigationLink {
                        ReadingStreakHubView()
                    } label: {
                        ShelfStreakEntryCard(
                            currentStreak: Int(shelfProfileVM.profile?.currentStreak ?? 0),
                            longestStreak: Int(shelfProfileVM.profile?.longestStreak ?? 0)
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)

                    Picker("", selection: Binding(
                        get: { vm.filter },
                        set: { vm.setFilter($0) }
                    )) {
                        ForEach(ShelfFilter.allCases, id: \.rawValue) { f in
                            Text(f.label).tag(f)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)

                    if vm.books.isEmpty {
                        Spacer()
                        EmptyStateView(
                            icon: "books.vertical",
                            title: "Your shelf is empty",
                            message: "Add your first book to get started. Tap + next to the title to search or add manually."
                        )
                        Spacer()
                    } else {
                        ScrollView(.vertical, showsIndicators: true) {
                            LazyVStack(spacing: 24) {
                                ShelfRow(
                                    books: Array(vm.books.prefix(3)),
                                    onDelete: { showDeleteConfirm = $0 },
                                    onUpdate: { vm.fetch() },
                                    showCabinetEntry: true,
                                    extraHiddenBookCount: max(0, vm.books.count - 3),
                                    onCabinetTap: { openCabinetGallery() }
                                )
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, tabBarHeight + 16)
                        }
                    }
                }
                .navigationTitle("")
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(AppTheme.background.opacity(0.95), for: .navigationBar)
                .toolbarColorScheme(.dark, for: .navigationBar)
                .toolbar(showCabinetGallery ? .hidden : .automatic, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        HStack(spacing: 12) {
                            Text("My Shelf")
                                .font(.mbsDisplay(22))
                                .foregroundStyle(AppTheme.textPrimary)
                            Spacer(minLength: 0)
                            HStack(spacing: 8) {
                                Button {
                                    HapticsService.shared.light()
                                    showBookTreeComingSoon = true
                                } label: {
                                    Image(systemName: "tree.fill")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(AppTheme.shelfWoodLight)
                                        .frame(width: 34, height: 34)
                                        .background(AppTheme.backgroundTertiary)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(AppTheme.divider, lineWidth: 1))
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Book tree")
                                Button {
                                    HapticsService.shared.light()
                                    showAddBook = true
                                } label: {
                                    Image(systemName: "plus")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(.white)
                                        .frame(width: 34, height: 34)
                                        .background(LinearGradient.mbsLampAccent)
                                        .clipShape(Circle())
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Add book")
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .sheet(isPresented: $showAddBook) {
                    AddBookFlowView(onDismiss: {
                        showAddBook = false
                        vm.fetch()
                    })
                }

                if showBookTreeComingSoon {
                    MBSPopupOverlay(isPresented: $showBookTreeComingSoon, title: "Book tree") {
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(AppTheme.shelfWood.opacity(0.35))
                                    .frame(width: 80, height: 80)
                                Image(systemName: "tree.fill")
                                    .font(.system(size: 36, weight: .medium))
                                    .foregroundStyle(AppTheme.shelfWoodLight)
                            }
                            Text("Coming soon")
                                .font(.mbsBody(15, weight: .semibold))
                                .foregroundStyle(AppTheme.accentLamp)
                            Text("The reading tree is coming back. This button will open the full interactive tree in a future release.")
                                .font(.mbsBody(14))
                                .foregroundStyle(AppTheme.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(20)
                    }
                    .zIndex(50)
                }

                if let book = showDeleteConfirm {
                    MBSConfirmationDialog(
                        title: "Delete book?",
                        message: "This cannot be undone.",
                        primaryAction: .init(title: "Delete", isDestructive: true) {
                            vm.delete(book)
                            showDeleteConfirm = nil
                            vm.fetch()
                        },
                        cancelAction: { showDeleteConfirm = nil }
                    )
                    .zIndex(50)
                }

                if showCabinetGallery {
                    CabinetGalleryView(
                        shelfVM: vm,
                        onDismiss: { closeCabinetGallery() },
                        onBooksChanged: { vm.fetch() }
                    )
                    .opacity(cabinetContentOpacity)
                    .transition(.opacity)
                    .zIndex(10)
                    .ignoresSafeArea()
                    .suppressesFloatingTabBar()
                }

                Color.black
                    .opacity(curtainOpacity)
                    .ignoresSafeArea()
                    .allowsHitTesting(curtainOpacity > 0.35)
                    .zIndex(20)
            }
        }
        .onAppear {
            vm.fetch()
            shelfProfileVM.fetch()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSManagedObjectContext.didSaveObjectsNotification, object: PersistenceController.shared.container.viewContext)) { _ in
            vm.fetch()
            shelfProfileVM.fetch()
        }
    }

    private func openCabinetGallery() {
        HapticsService.shared.light()
        cabinetContentOpacity = 0
        withAnimation(.easeIn(duration: 0.24)) { curtainOpacity = 1 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.26) {
            showCabinetGallery = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.04) {
                withAnimation(.easeOut(duration: 0.4)) {
                    curtainOpacity = 0
                    cabinetContentOpacity = 1
                }
            }
        }
    }

    private func closeCabinetGallery() {
        withAnimation(.easeIn(duration: 0.24)) {
            curtainOpacity = 1
            cabinetContentOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.26) {
            showCabinetGallery = false
            withAnimation(.easeOut(duration: 0.28)) { curtainOpacity = 0 }
            cabinetContentOpacity = 0
        }
    }
}

struct ShelfRow: View {
    let books: [Book]
    let onDelete: (Book) -> Void
    var onUpdate: (() -> Void)?
    var showCabinetEntry: Bool = false
    var extraHiddenBookCount: Int = 0
    var onCabinetTap: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(LinearGradient(
                    colors: [AppTheme.shelfWoodLight.opacity(0.9), AppTheme.shelfWood],
                    startPoint: .top, endPoint: .bottom
                ))
                .frame(height: 6)
                .padding(.horizontal, 28)
                .shadow(color: .black.opacity(0.25), radius: 4, y: 2)

            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(AppTheme.backgroundSecondary)

                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(AppTheme.outlineLamp.opacity(0.6), lineWidth: 1)

                HStack(spacing: 0) {
                    ForEach(Array(books.enumerated()), id: \.element.id) { index, book in
                        if index > 0 { shelfVerticalDivider }
                        Group {
                            if showCabinetEntry {
                                BookCardView(book: book, onDelete: onDelete, onUpdate: onUpdate, usesShelfChrome: false)
                                    .id(bookCardIdentity(book))
                            } else {
                                NavigationLink(destination: BookDetailView(book: book, onDelete: onUpdate)) {
                                    BookCardView(book: book, onDelete: onDelete, onUpdate: onUpdate, usesShelfChrome: true)
                                        .id(bookCardIdentity(book))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 14)

                if showCabinetEntry {
                    cabinetEntryOverlay
                }
            }
            .shadow(color: AppTheme.shadow, radius: 16, y: 8)

            if showCabinetEntry {
                Text("Tap to open the cabinet and see your full library.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 4)
            }

            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(LinearGradient(
                    colors: [AppTheme.shelfWoodLight, AppTheme.shelfWood],
                    startPoint: .top, endPoint: .bottom
                ))
                .frame(height: 12)
                .overlay(alignment: .top) {
                    LinearGradient(colors: [Color.white.opacity(0.2), Color.clear], startPoint: .top, endPoint: .bottom)
                        .frame(height: 4)
                }
                .shadow(color: .black.opacity(0.55), radius: 10, y: 5)
                .padding(.horizontal, 10)
                .offset(y: -2)
        }
        .padding(.bottom, 8)
    }

    private var shelfVerticalDivider: some View {
        Rectangle()
            .fill(LinearGradient(
                colors: [AppTheme.divider.opacity(0.6), AppTheme.divider.opacity(0.2), AppTheme.divider.opacity(0.5)],
                startPoint: .top, endPoint: .bottom
            ))
            .frame(width: 1)
            .padding(.vertical, 18)
    }

    private var cabinetEntryOverlay: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(AppTheme.accentLamp.opacity(0.08))
                .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .onTapGesture { onCabinetTap?() }

            if extraHiddenBookCount > 0 {
                Text("+\(extraHiddenBookCount)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(LinearGradient.mbsLampAccent)
                            .shadow(color: .black.opacity(0.35), radius: 4, y: 2)
                    )
                    .padding(12)
                    .allowsHitTesting(false)
            }
        }
    }

    private func bookCardIdentity(_ book: Book) -> String {
        "\(book.objectID)-\(book.currentPage)-\(book.status)-\(book.isFavorite)-\(book.rating)-\(book.progressPercent)"
    }
}

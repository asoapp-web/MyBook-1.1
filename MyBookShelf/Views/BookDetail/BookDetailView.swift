import SwiftUI
import CoreData

struct BookDetailView: View {
    @ObservedObject var vm: BookDetailViewModel
    @EnvironmentObject private var tabState: MBSTabState
    @StateObject private var timerService = ReadingTimerService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showUpdateProgress = false
    @State private var showEditSheet = false
    @State private var showDeleteConfirm = false
    var onDelete: (() -> Void)?

    init(book: Book, onDelete: (() -> Void)? = nil) {
        _vm = ObservedObject(wrappedValue: BookDetailViewModel(book: book))
        self.onDelete = onDelete
    }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerRow
                    statusSection
                    progressSection
                    timerSection
                    ratingSection
                    notesSection
                    sessionsSection
                    deleteButton
                }
                .padding(20)
            }
            .background(AppTheme.background)

            if showUpdateProgress {
                MBSPopupOverlay(isPresented: $showUpdateProgress, title: "Update progress") {
                    UpdateProgressContent(book: vm.book) {
                        showUpdateProgress = false
                        vm.refreshUI()
                        tabState.showToast("Progress saved", icon: "checkmark.circle.fill")
                    }
                }
                .zIndex(50)
            }

            if showDeleteConfirm {
                MBSConfirmationDialog(
                    title: "Delete book?",
                    message: "This cannot be undone.",
                    primaryAction: .init(title: "Delete", isDestructive: true) {
                        PersistenceController.shared.container.viewContext.delete(vm.book)
                        try? PersistenceController.shared.container.viewContext.save()
                        onDelete?()
                        dismiss()
                    },
                    cancelAction: { showDeleteConfirm = false }
                )
                .zIndex(50)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 16) {
                    Button {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.72)) {
                            vm.toggleFavorite()
                        }
                    } label: {
                        Image(systemName: vm.book.isFavorite ? "heart.fill" : "heart")
                            .font(.system(size: 20))
                            .foregroundStyle(vm.book.isFavorite ? AppTheme.accentLamp : AppTheme.textSecondary)
                    }
                    if vm.book.sourceTypeEnum == .manual {
                        Button { showEditSheet = true } label: {
                            Image(systemName: "pencil")
                        }
                        .accessibilityLabel("Edit book details")
                    }
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            EditBookView(book: vm.book, onDismiss: {
                showEditSheet = false
                vm.refreshUI()
            })
        }
        .suppressesFloatingTabBar()
        .toolbar(.hidden, for: .tabBar)
    }

    private var headerRow: some View {
        HStack(alignment: .top, spacing: 20) {
            BookCoverView(book: vm.book, size: CGSize(width: 110, height: 165))
            VStack(alignment: .leading, spacing: 6) {
                Text(vm.book.title ?? "")
                    .font(.mbsDisplay(22))
                    .foregroundStyle(AppTheme.textPrimary)
                Text(vm.book.author ?? "")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                if vm.book.publishYear > 0 {
                    Text("\(vm.book.publishYear)")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textMuted)
                }
                Text(vm.book.genre ?? "")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textMuted)
            }
            Spacer()
        }
    }

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Status")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)
            Picker("Status", selection: Binding(
                get: { vm.book.statusEnum },
                set: { vm.setStatus($0) }
            )) {
                ForEach(ReadingStatus.selectableCases(for: vm.book), id: \.rawValue) { s in
                    Text(s.label).tag(s)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            ProgressBarView(progress: vm.book.progressPercent)
                .frame(height: 10)
            Text("Page \(vm.book.currentPage) of \(max(1, vm.book.totalPages)) (\(Int(vm.book.progressPercent))%)")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)

            Button { showUpdateProgress = true } label: {
                Text("Update progress")
                    .font(.mbsBody(16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(LinearGradient.mbsLampAccent)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
        }
    }

    private var timerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reading timer")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)

            if timerService.isRunning, timerService.activeBook?.id == vm.book.id {
                HStack {
                    Text(timerService.formattedTime)
                        .font(.system(size: 36, weight: .bold, design: .monospaced))
                        .foregroundStyle(AppTheme.accentLamp)
                    Spacer()
                    Button {
                        timerService.isPaused ? timerService.resume() : timerService.pause()
                    } label: {
                        Image(systemName: timerService.isPaused ? "play.fill" : "pause.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(AppTheme.accentLamp)
                            .frame(width: 44, height: 44)
                            .background(AppTheme.accentLamp.opacity(0.15))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)

                    Button {
                        let minutes = timerService.stop()
                        tabState.readingSessionActive = false
                        showUpdateProgress = true
                    } label: {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(Color.red)
                            .frame(width: 44, height: 44)
                            .background(Color.red.opacity(0.15))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            } else if timerService.isRunning {
                Text("Timer running for: \(timerService.activeBook?.title ?? "another book")")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textMuted)
            } else {
                Button {
                    guard let id = vm.book.id else { return }
                    timerService.start(bookID: id, bookTitle: vm.book.title ?? "Book")
                    tabState.readingSessionActive = true
                    HapticsService.shared.light()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "timer")
                        Text("Start reading session")
                    }
                    .font(.mbsBody(15, weight: .semibold))
                    .foregroundStyle(AppTheme.accentLamp)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AppTheme.accentLamp.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(AppTheme.outlineLamp, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(AppTheme.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var ratingSection: some View {
        RatingSection(rating: vm.book.displayRating, onSelect: { vm.setRating($0) })
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)
            TextField("Add notes...", text: Binding(
                get: { vm.book.notes ?? "" },
                set: { vm.saveNotes($0) }
            ), axis: .vertical)
            .lineLimit(1...5)
            .textFieldStyle(.plain)
            .padding(12)
            .background(AppTheme.backgroundTertiary)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .foregroundStyle(AppTheme.textPrimary)
        }
    }

    @ViewBuilder
    private var sessionsSection: some View {
        if !vm.sessions.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Reading sessions")
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)
                ForEach(vm.sessions.prefix(5), id: \.id) { s in
                    HStack {
                        Text(s.date?.formatted(date: .abbreviated, time: .omitted) ?? "")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)
                        Spacer()
                        if s.durationMinutes > 0 {
                            Text("\(s.durationMinutes)m")
                                .font(.caption)
                                .foregroundStyle(AppTheme.textMuted)
                        }
                        Text("\(s.pagesRead) pages")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textPrimary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private var deleteButton: some View {
        Button { showDeleteConfirm = true } label: {
            Text("Delete book")
                .font(.mbsBody(16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.red)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

struct UpdateProgressContent: View {
    let book: Book
    let onDone: () -> Void
    @State private var currentPage: Int
    @State private var durationMinutes: String = ""
    @State private var showCelebration = false

    init(book: Book, onDone: @escaping () -> Void) {
        self.book = book
        self.onDone = onDone
        _currentPage = State(initialValue: Int(book.currentPage))
    }

    private var progressPercent: Double {
        Double(currentPage) / Double(max(1, Int(book.totalPages))) * 100
    }

    var body: some View {
        VStack(spacing: 18) {
            Text("\(Int(progressPercent))%")
                .font(.system(size: 40, weight: .bold))
                .foregroundStyle(AppTheme.accentLamp)

            ProgressBarView(progress: progressPercent)
                .frame(height: 10)

            VStack(alignment: .leading, spacing: 6) {
                Text("Pages: \(currentPage) / \(book.totalPages)")
                    .font(.mbsCaption(13))
                    .foregroundStyle(AppTheme.textSecondary)
                Slider(value: Binding(
                    get: { Double(currentPage) },
                    set: { currentPage = Int($0) }
                ), in: 0...Double(max(1, Int(book.totalPages))), step: 1)
                    .tint(AppTheme.accentLamp)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Reading time (minutes)")
                    .font(.mbsCaption(13))
                    .foregroundStyle(AppTheme.textSecondary)
                TextField("Optional", text: $durationMinutes)
                    .keyboardType(.numberPad)
                    .padding(10)
                    .background(AppTheme.backgroundTertiary)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .foregroundStyle(AppTheme.textPrimary)
            }

            Button {
                save()
            } label: {
                Text("Save")
                    .font(.mbsBody(16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(LinearGradient.mbsLampAccent)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .onChange(of: currentPage) { new in
            currentPage = min(max(0, new), Int(book.totalPages))
        }
    }

    private func save() {
        let dur = Int(durationMinutes)
        let ctx = PersistenceController.shared.container.viewContext
        let bvm = BookDetailViewModel(book: book, context: ctx)
        bvm.updateProgress(to: currentPage, durationMinutes: dur)
        HapticsService.shared.success()
        onDone()
    }
}

struct RatingSection: View {
    let rating: Int?
    let onSelect: (Int?) -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text("Rating")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)
            Spacer()
            ForEach(1...5, id: \.self) { i in
                Button {
                    HapticsService.shared.selection()
                    onSelect(rating == i ? nil : i)
                } label: {
                    Image(systemName: (rating ?? 0) >= i ? "star.fill" : "star")
                        .font(.system(size: 24))
                        .foregroundStyle((rating ?? 0) >= i ? AppTheme.accentLamp : AppTheme.textMuted)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

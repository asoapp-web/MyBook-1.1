//
//  UpdateProgressSheet.swift
//  MyBookShelf
//

import SwiftUI
import CoreData

/// Kept for backward compatibility — the primary progress update is now
/// `UpdateProgressContent` embedded inside an `MBSPopupOverlay` from `BookDetailView`.
/// This wrapper is still referenced if any code path presents it as a `.sheet`.
struct UpdateProgressSheet: View {
    let book: Book
    let onDismiss: () -> Void
    @State private var currentPage: Int
    @State private var durationMinutes: String = ""
    @State private var showFinishedCelebration = false

    init(book: Book, onDismiss: @escaping () -> Void) {
        self.book = book
        self.onDismiss = onDismiss
        _currentPage = State(initialValue: Int(book.currentPage))
    }

    private var progressPercent: Double {
        let total = max(1, Int(book.totalPages))
        return Double(currentPage) / Double(total) * 100
    }

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 24) {
                    Text("\(Int(progressPercent))%")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(AppTheme.accentLamp)

                    ProgressBarView(progress: progressPercent)
                        .frame(height: 12)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Current page")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)
                        TextField("Page", value: $currentPage, format: .number)
                            .keyboardType(.numberPad)
                            .padding(10)
                            .background(AppTheme.backgroundTertiary)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .foregroundStyle(AppTheme.textPrimary)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Pages: \(currentPage) / \(book.totalPages)")
                            .font(.mbsCaption(14))
                            .foregroundStyle(AppTheme.textPrimary)
                        Slider(value: Binding(
                            get: { Double(currentPage) },
                            set: { currentPage = Int($0) }
                        ), in: 0...Double(max(1, Int(book.totalPages))), step: 1)
                            .tint(AppTheme.accentLamp)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reading time (minutes)")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)
                        TextField("Optional", text: $durationMinutes)
                            .keyboardType(.numberPad)
                            .padding(10)
                            .background(AppTheme.backgroundTertiary)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .foregroundStyle(AppTheme.textPrimary)
                    }

                    Spacer()
                }
                .padding(24)

                if showFinishedCelebration {
                    FinishedCelebrationPopup(onDismiss: {
                        showFinishedCelebration = false
                        onDismiss()
                    })
                    .zIndex(50)
                }
            }
            .background(AppTheme.background)
            .navigationTitle("Update progress")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onDismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { save() }.fontWeight(.semibold)
                }
            }
            .onChange(of: currentPage) { new in
                currentPage = min(max(0, new), Int(book.totalPages))
            }
        }
    }

    private func save() {
        let dur = Int(durationMinutes)
        let ctx = PersistenceController.shared.container.viewContext
        let vm = BookDetailViewModel(book: book, context: ctx)
        vm.updateProgress(to: currentPage, durationMinutes: dur)
        HapticsService.shared.success()
        if currentPage >= Int(book.totalPages) {
            showFinishedCelebration = true
        } else {
            onDismiss()
        }
    }
}

struct FinishedCelebrationPopup: View {
    let onDismiss: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(AppTheme.accentLamp)
                Text("Book finished!")
                    .font(.mbsDisplay(24))
                    .foregroundStyle(AppTheme.textPrimary)
                Text("Congratulations on completing another book.")
                    .font(.mbsBody(14))
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                Button { onDismiss() } label: {
                    Text("Done")
                        .font(.mbsBody(18, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(LinearGradient.mbsLampAccent)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
            .padding(32)
            .frame(maxWidth: 340)
            .background(AppTheme.backgroundElevated)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(AppTheme.outlineLamp, lineWidth: 1))
            .shadow(color: AppTheme.shadow, radius: 24, y: 10)
            .scaleEffect(appeared ? 1 : (reduceMotion ? 1 : 0.92))
            .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(reduceMotion ? .easeOut(duration: 0.2) : .spring(response: 0.32, dampingFraction: 0.82)) {
                appeared = true
            }
        }
    }
}

struct FinishedCelebrationView: View {
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(AppTheme.accentLamp)
            Text("Book finished!")
                .font(.mbsDisplay(28))
                .foregroundStyle(AppTheme.textPrimary)
            Text("Congratulations on completing another book.")
                .font(.body)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
            Button("Done") { onDismiss() }
                .font(.mbsBody(18, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(LinearGradient.mbsLampAccent)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 40)
        }
        .padding(40)
        .background(AppTheme.background)
    }
}

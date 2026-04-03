//
//  SettingsView.swift
//  MyBookShelf
//

import CoreData
import SwiftUI

struct SettingsView: View {
    @StateObject private var vm = ProfileViewModel()
    @EnvironmentObject private var tabState: MBSTabState
    @AppStorage(OnboardingUserDefaults.completedKey) private var onboardingCompleted = false
    @State private var dailyGoal: String = "20"
    @State private var showResetConfirm = false

    var body: some View {
        ZStack {
            Form {
                Section("Daily goal") {
                    TextField("Pages per day", text: $dailyGoal)
                        .keyboardType(.numberPad)
                        .onChange(of: dailyGoal) { new in
                            if let n = Int(new), n > 0 {
                                vm.updateDailyGoal(n)
                            }
                        }
                }
                Section {
                    Button {
                        onboardingCompleted = false
                    } label: {
                        Text("Show onboarding again")
                    }
                    Button(role: .destructive) {
                        showResetConfirm = true
                    } label: {
                        Text("Reset all progress")
                    }
                }
                Section("Privacy") {
                    NavigationLink {
                        PrivacyPolicyView()
                    } label: {
                        Text("Privacy policy")
                    }
                }
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.background)

            if showResetConfirm {
                MBSConfirmationDialog(
                    title: "Reset progress?",
                    message: "This will delete all books and progress. This cannot be undone.",
                    primaryAction: .init(title: "Reset", isDestructive: true) {
                        resetProgress()
                        showResetConfirm = false
                        tabState.showToast("Progress reset", icon: "arrow.counterclockwise")
                    },
                    cancelAction: { showResetConfirm = false }
                )
                .zIndex(50)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            dailyGoal = "\(vm.profile?.dailyGoalPages ?? 20)"
            vm.fetch()
        }
        .suppressesFloatingTabBar()
        .toolbar(.hidden, for: .tabBar)
    }

    private func resetProgress() {
        let ctx = PersistenceController.shared.container.viewContext
        let breq = Book.fetchRequest()
        let books = (try? ctx.fetch(breq)) ?? []
        for b in books { ctx.delete(b) }
        let sreq = ReadingSession.fetchRequest()
        let sessions = (try? ctx.fetch(sreq)) ?? []
        for s in sessions { ctx.delete(s) }
        if let p = vm.profile {
            if let path = p.localAvatarPath, !path.isEmpty {
                CacheService.shared.deleteProfileAvatarFile(at: path)
                p.localAvatarPath = nil
            }
            p.totalXP = 0
            p.currentLevel = 1
            p.currentStreak = 0
            p.longestStreak = 0
            p.totalBooksFinished = 0
            p.totalPagesRead = 0
            p.lastReadingDate = nil
            p.unlockedAchievementIDs = []
            p.completedQuestIDs = []
            p.unlockedShelfStyles = ["wood_classic"]
            p.selectedShelfStyleID = "wood_classic"
        }
        try? ctx.save()
        CacheService.shared.clearCache()
    }
}

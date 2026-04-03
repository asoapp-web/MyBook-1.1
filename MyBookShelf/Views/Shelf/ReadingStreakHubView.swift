//
//  ReadingStreakHubView.swift
//  MyBookShelf
//

import CoreData
import SwiftUI

struct ReadingStreakHubView: View {
    @StateObject private var vm = ReadingStreakViewModel()
    @State private var displayedMonth: Date = Date()
    @Environment(\.calendar) private var calendar
    @Environment(\.managedObjectContext) private var moc

    private var displaySnapshot: StreakDisplaySnapshot {
        StreakDisplaySnapshot.from(viewModel: vm, calendar: calendar)
    }

    private var tier: StreakVisualTier {
        StreakVisualTier.tier(for: displaySnapshot.currentStreak)
    }

    private var streakAchievementsSorted: [Achievement] {
        AchievementData.all
            .filter { $0.category == .streak && $0.requirement.type == .streakDays }
            .sorted { $0.requirement.value < $1.requirement.value }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                heroHeader
                statsRow
                calendarCard
                streakMilestonesSection
                legendRow
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .background(
            ZStack {
                AppTheme.background
                RadialGradient(colors: [tier.glowColor.opacity(0.35), Color.clear], center: .top, startRadius: 20, endRadius: 380)
                    .ignoresSafeArea()
            }
        )
        .navigationTitle("Reading streak")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppTheme.background.opacity(0.92), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .suppressesFloatingTabBar()
        .toolbar(.hidden, for: .tabBar)
        .onAppear { vm.refresh() }
        .onReceive(NotificationCenter.default.publisher(for: NSManagedObjectContext.didSaveObjectsNotification, object: PersistenceController.shared.container.viewContext)) { _ in
            vm.refresh()
        }
    }

    private var heroHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(colors: tier.primaryGradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 112, height: 112)
                    .shadow(color: tier.glowColor.opacity(0.65), radius: tier == .spark ? 8 : 24, y: 8)

                Image(systemName: tier.iconName)
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.35), radius: 4, y: 2)

                if let extra = tier.secondaryIcon {
                    Image(systemName: extra)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white.opacity(0.95))
                        .offset(x: 38, y: -36)
                }
            }
            .modifier(StreakIconPulseModifier(active: tier >= .flame))

            VStack(spacing: 6) {
                Text("\(displaySnapshot.currentStreak) days in a row")
                    .font(.title.bold())
                    .foregroundStyle(AppTheme.textPrimary)
                Text(tier.tagline)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                Text("Stage: \(tier.title)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(
                        LinearGradient(colors: tier.primaryGradient, startPoint: .leading, endPoint: .trailing)
                    )
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(AppTheme.backgroundSecondary))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            statPill(title: "Current", value: "\(displaySnapshot.currentStreak)", subtitle: "days")
            statPill(title: "Best ever", value: "\(displaySnapshot.longestStreak)", subtitle: "days")
            statPill(title: "This month", value: "\(readDaysInDisplayedMonth)", subtitle: "sessions")
        }
    }

    private var readDaysInDisplayedMonth: Int {
        guard let interval = calendar.dateInterval(of: .month, for: displayedMonth) else { return 0 }
        var n = 0
        var d = interval.start
        while d < interval.end {
            if displaySnapshot.hasReading(on: d, calendar: calendar) { n += 1 }
            d = calendar.date(byAdding: .day, value: 1, to: d) ?? interval.end
        }
        return n
    }

    private var streakMilestonesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Streak milestones")
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)
                Text("Unlock XP as your consecutive reading days grow.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textMuted)
            }

            LazyVStack(spacing: 12) {
                ForEach(streakAchievementsSorted) { ach in
                    let unlocked = vm.profile?.unlockedAchievementIDs.contains(ach.id) ?? false
                    let prog = vm.profile.flatMap { p in
                        GamificationEngine.shared.achievementDisplayProgress(ach, profile: p, context: moc)
                    }
                    AchievementGameCard(achievement: ach, unlocked: unlocked, progress: prog, showNewLoot: false)
                }
            }
        }
    }

    private func statPill(title: String, value: String, subtitle: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(AppTheme.textMuted)
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(AppTheme.textPrimary)
            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AppTheme.backgroundSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }

    private var calendarCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Button {
                    displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
                } label: {
                    Image(systemName: "chevron.left.circle.fill")
                        .font(.title2)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                Spacer()
                Text(monthYearString(displayedMonth))
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                Button {
                    displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
                } label: {
                    Image(systemName: "chevron.right.circle.fill")
                        .font(.title2)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 8) {
                ForEach(weekdayHeaderSymbols(), id: \.self) { sym in
                    Text(sym)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(AppTheme.textMuted)
                        .frame(maxWidth: .infinity)
                }
                ForEach(Array(monthCells(for: displayedMonth).enumerated()), id: \.offset) { _, cell in
                    if let day = cell {
                        dayCell(day)
                    } else {
                        Color.clear.frame(height: 40)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(AppTheme.backgroundSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(
                            LinearGradient(colors: [tier.glowColor.opacity(0.4), Color.white.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 1
                        )
                )
        )
    }

    private func dayCell(_ day: Date) -> some View {
        let read = displaySnapshot.hasReading(on: day, calendar: calendar)
        let active = displaySnapshot.isInActiveStreak(day, calendar: calendar)
        let today = calendar.isDateInToday(day)

        return Text("\(calendar.component(.day, from: day))")
            .font(.system(size: 14, weight: today ? .bold : .medium))
            .foregroundStyle(read ? Color.white : AppTheme.textMuted.opacity(0.55))
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(
                Group {
                    if active && read {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(
                                LinearGradient(colors: tier.primaryGradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                    } else if read {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(AppTheme.accentOrange.opacity(0.35))
                    } else if today {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(AppTheme.textSecondary.opacity(0.5), lineWidth: 1)
                    } else {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.white.opacity(0.03))
                    }
                }
            )
            .overlay {
                if today && !read {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                }
            }
    }

    private var legendRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Legend")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.textMuted)
            VStack(alignment: .leading, spacing: 8) {
                legendGradientSwatch(label: "Current streak")
                legendSolidSwatch(color: AppTheme.accentOrange.opacity(0.45), label: "Read that day")
                legendSolidSwatch(color: Color.white.opacity(0.08), label: "No pages logged")
            }
            Text("Marked days come from your reading sessions. The gradient cells are your live streak chain.")
                .font(.caption2)
                .foregroundStyle(AppTheme.textMuted)
        }
        .padding(.bottom, 8)
    }

    private func legendGradientSwatch(label: String) -> some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(
                    LinearGradient(colors: tier.primaryGradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .frame(width: 14, height: 14)
            Text(label)
                .font(.caption2)
                .foregroundStyle(AppTheme.textSecondary)
        }
    }

    private func legendSolidSwatch(color: Color, label: String) -> some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(color)
                .frame(width: 14, height: 14)
            Text(label)
                .font(.caption2)
                .foregroundStyle(AppTheme.textSecondary)
        }
    }

    private func monthYearString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "LLLL yyyy"
        return f.string(from: date)
    }

    private func weekdayHeaderSymbols() -> [String] {
        let syms = calendar.shortWeekdaySymbols
        let idx = (calendar.firstWeekday - 1) % 7
        return Array(syms[idx...] + syms[..<idx])
    }

    private func monthCells(for month: Date) -> [Date?] {
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: month)),
              let range = calendar.range(of: .day, in: .month, for: monthStart)
        else { return [] }
        let firstWd = calendar.component(.weekday, from: monthStart)
        let lead = (firstWd - calendar.firstWeekday + 7) % 7
        var cells: [Date?] = Array(repeating: nil, count: lead)
        for day in range {
            if let d = calendar.date(byAdding: .day, value: day - 1, to: monthStart) {
                cells.append(d)
            }
        }
        while cells.count % 7 != 0 {
            cells.append(nil)
        }
        return cells
    }
}

// MARK: - Shelf entry (My Shelf)

struct ShelfStreakEntryCard: View {
    let currentStreak: Int
    let longestStreak: Int

    private var tier: StreakVisualTier {
        StreakVisualTier.tier(for: currentStreak)
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(colors: tier.primaryGradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 52, height: 52)
                    .shadow(color: tier.glowColor.opacity(tier == .spark ? 0.2 : 0.55), radius: tier == .spark ? 4 : 12, y: 4)

                Image(systemName: tier.iconName)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .modifier(StreakIconPulseModifier(active: tier >= .flame))

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Reading streak")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(AppTheme.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppTheme.textMuted)
                }
                if currentStreak == 0 {
                    Text("Open calendar — start your chain")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                } else {
                    Text("\(currentStreak) days in a row · best \(longestStreak)")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                Text(tier.tagline)
                    .font(.caption2)
                    .foregroundStyle(
                        LinearGradient(colors: tier.primaryGradient, startPoint: .leading, endPoint: .trailing)
                    )
                    .lineLimit(1)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppTheme.backgroundSecondary.opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(
                            LinearGradient(colors: [tier.glowColor.opacity(0.55), Color.white.opacity(0.08)], startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: tier == .spark ? 1 : 1.5
                        )
                )
        )
        .shadow(color: tier.glowColor.opacity(tier == .spark ? 0.06 : 0.18), radius: 14, y: 6)
    }
}

// MARK: - Soft pulse on icon orbs (flame tier and up)

private struct StreakIconPulseModifier: ViewModifier {
    let active: Bool

    func body(content: Content) -> some View {
        if active {
            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                let scale = 1.0 + 0.038 * sin(t * 2 * .pi / 2.25)
                content.scaleEffect(scale)
            }
        } else {
            content
        }
    }
}

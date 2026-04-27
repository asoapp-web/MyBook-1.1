import SwiftUI
import CoreData

struct StatsView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \UserProfile.displayName, ascending: true)],
        animation: .none
    )
    private var profiles: FetchedResults<UserProfile>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Book.dateAdded, ascending: false)],
        animation: .none
    )
    private var books: FetchedResults<Book>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ReadingSession.date, ascending: false)],
        animation: .none
    )
    private var sessions: FetchedResults<ReadingSession>

    var tabBarHeight: CGFloat = 80
    private var profile: UserProfile? { profiles.first }

    @State private var appeared = false
    @State private var barsGrown = false

    var body: some View {
        NavigationStack {
            ZStack {

                MBSAtmosphereBackground()

                ScrollView {
                    VStack(spacing: 18) {
                        summarySection
                            .entryAnimation(appeared: appeared, delay: 0.05)
                        chartSection
                            .entryAnimation(appeared: appeared, delay: 0.12)
                        heatmapSection
                            .entryAnimation(appeared: appeared, delay: 0.19)
                        genresSection
                            .entryAnimation(appeared: appeared, delay: 0.26)
                        activeBooksSection
                            .entryAnimation(appeared: appeared, delay: 0.33)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, tabBarHeight + 16)
                }
                .background(Color.clear)
            }
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(AppTheme.background.opacity(0.88), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.78)) {
                appeared = true
            }
            withAnimation(.spring(response: 0.65, dampingFraction: 0.72).delay(0.30)) {
                barsGrown = true
            }
        }
    }

    private var summarySection: some View {
        HStack(spacing: 0) {
            summaryMetric(
                value: "\(profile?.totalBooksFinished ?? 0)",
                label: "Books",
                icon: "books.vertical.fill"
            )
            dividerLine
            summaryMetric(
                value: "\(profile?.totalPagesRead ?? 0)",
                label: "Pages",
                icon: "doc.text.fill"
            )
            dividerLine
            summaryMetric(
                value: "\(profile?.currentStreak ?? 0)",
                label: "Streak",
                icon: "flame.fill",
                accentIcon: true
            )
            dividerLine
            summaryMetric(
                value: "\(avgPagesPerDay)",
                label: "Avg/day",
                icon: "chart.line.uptrend.xyaxis"
            )
        }
        .padding(.vertical, 20)
        .mbsCard()
    }

    private var dividerLine: some View {
        Rectangle()
            .fill(AppTheme.divider)
            .frame(width: 1, height: 44)
    }

    private func summaryMetric(
        value: String,
        label: String,
        icon: String,
        accentIcon: Bool = false
    ) -> some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(accentIcon ? AppTheme.accentLamp : AppTheme.textMuted)
            Text(value)
                .font(.mbsDisplay(28))
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.55)
            Text(label)
                .font(.mbsCaption(11))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Last 7 days", icon: "chart.bar.fill")
            let data = last7DaysData
            let maxVal = max(1, data.map(\.pages).max() ?? 1)
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(Array(data.enumerated()), id: \.offset) { i, d in
                    VStack(spacing: 6) {
                        Text(d.pages > 0 ? "\(d.pages)" : "")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(AppTheme.textSecondary)
                            .frame(height: 14)
                            .opacity(barsGrown ? 1 : 0)

                        RoundedRectangle(cornerRadius: 5)
                            .fill(
                                LinearGradient(
                                    colors: [AppTheme.accentLampLight, AppTheme.accentLamp, AppTheme.accentLampDark],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(height: max(5, CGFloat(d.pages) / CGFloat(maxVal) * 88))
                            .shadow(color: AppTheme.accentLamp.opacity(d.pages > 0 ? 0.50 : 0), radius: 6, y: 3)
                            .scaleEffect(y: barsGrown ? 1.0 : 0.04, anchor: .bottom)
                            .animation(
                                .spring(response: 0.58, dampingFraction: 0.68)
                                    .delay(0.30 + Double(i) * 0.06),
                                value: barsGrown
                            )
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 116)
            HStack(spacing: 6) {
                ForEach(Array(data.enumerated()), id: \.offset) { _, d in
                    Text(d.label)
                        .font(.system(size: 10))
                        .foregroundStyle(AppTheme.textMuted)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(18)
        .mbsCard()
    }

    private var heatmapSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("This month", icon: "calendar")

            HStack(spacing: 4) {
                ForEach(["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"], id: \.self) { d in
                    Text(d)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(AppTheme.textMuted)
                        .frame(maxWidth: .infinity)
                }
            }

            let cal = Calendar.current
            let comp = cal.dateComponents([.year, .month], from: Date())
            let first = cal.date(from: comp)!
            let days = cal.range(of: .day, in: .month, for: Date())!.count
            let pad = cal.component(.weekday, from: first) - 1
            let rows = (pad + days + 6) / 7

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7),
                spacing: 4
            ) {
                ForEach(0 ..< rows * 7, id: \.self) { i in
                    if i < pad || i - pad >= days {
                        Color.clear.aspectRatio(1, contentMode: .fit)
                    } else {
                        let dayNum = i - pad + 1
                        let d = cal.date(byAdding: .day, value: dayNum - 1, to: first)!
                        let start = cal.startOfDay(for: d)
                        let end = cal.date(byAdding: .day, value: 1, to: start)!
                        let p = sessions.filter {
                            ($0.date ?? .distantPast) >= start && ($0.date ?? .distantPast) < end
                        }.reduce(0) { $0 + Int($1.pagesRead) }
                        let isToday = cal.isDateInToday(d)
                        let intensity = min(1.0, Double(p) / 40.0)

                        Group {
                            if isToday {

                                TimelineView(.animation(minimumInterval: 1.0 / 15.0)) { ctx in
                                    let t = ctx.date.timeIntervalSinceReferenceDate
                                    let pulse = 0.55 + 0.45 * CGFloat(abs(sin(t * 1.8)))
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(p > 0
                                                  ? AppTheme.accentLamp.opacity(0.18 + intensity * 0.72)
                                                  : AppTheme.backgroundTertiary)
                                        RoundedRectangle(cornerRadius: 3)
                                            .stroke(AppTheme.accentLamp.opacity(pulse), lineWidth: 1.5)
                                        RoundedRectangle(cornerRadius: 3)
                                            .stroke(AppTheme.accentLampLight.opacity(pulse * 0.4), lineWidth: 3)
                                            .blur(radius: 2)
                                    }
                                }
                            } else {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(p > 0
                                          ? AppTheme.accentLamp.opacity(0.18 + intensity * 0.72)
                                          : AppTheme.backgroundTertiary)
                            }
                        }
                        .aspectRatio(1, contentMode: .fit)
                    }
                }
            }
        }
        .padding(18)
        .mbsCard()
    }

    private var genresSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Top genres", icon: "tag.fill")
            let finished = books.filter { $0.statusEnum == .finished }
            let byGenre = Dictionary(grouping: finished, by: { $0.genre ?? "Other" })
            let sorted = byGenre.sorted { $0.value.count > $1.value.count }.prefix(5)
            let maxCount = max(1, sorted.map(\.value.count).max() ?? 1)

            if sorted.isEmpty {
                emptyHint("Finish some books to see genre breakdown")
            } else {
                ForEach(Array(sorted), id: \.key) { genre, items in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(genre)
                                .font(.mbsBody(14))
                                .foregroundStyle(AppTheme.textPrimary)
                            Spacer()
                            Text("\(items.count)")
                                .font(.mbsCaption(11))
                                .foregroundStyle(AppTheme.accentLamp)
                        }
                        GeometryReader { g in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3).fill(AppTheme.backgroundTertiary)
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(LinearGradient(
                                        colors: [AppTheme.accentLampLight, AppTheme.accentLampDark],
                                        startPoint: .leading, endPoint: .trailing
                                    ))
                                    .frame(width: max(8, g.size.width * CGFloat(items.count) / CGFloat(maxCount)))
                                    .shadow(color: AppTheme.accentLamp.opacity(0.35), radius: 4)
                            }
                        }
                        .frame(height: 6)
                    }
                }
            }
        }
        .padding(18)
        .mbsCard()
    }

    private var activeBooksSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Currently reading", icon: "book.fill")
            let reading = books.filter { $0.statusEnum == .reading }

            if reading.isEmpty {
                emptyHint("No books in progress")
            } else {
                ForEach(reading, id: \.id) { book in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(book.title ?? "")
                            .font(.mbsBody(15, weight: .medium))
                            .foregroundStyle(AppTheme.textPrimary)
                        HStack(spacing: 10) {
                            ProgressBarView(progress: book.progressPercent)
                            Text("\(Int(book.progressPercent))%")
                                .font(.mbsCaption(11))
                                .foregroundStyle(AppTheme.accentLamp)
                                .monospacedDigit()
                        }
                    }
                }
            }
        }
        .padding(18)
        .mbsCard()
    }

    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppTheme.accentLamp)
            Text(title)
                .font(.mbsBody(16, weight: .semibold))
                .foregroundStyle(AppTheme.textPrimary)
            Spacer()
        }
    }

    private func emptyHint(_ text: String) -> some View {
        Text(text)
            .font(.mbsCaption())
            .foregroundStyle(AppTheme.textMuted)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var last7DaysData: [(label: String, pages: Int)] {
        let cal = Calendar.current
        let fmt = DateFormatter()
        fmt.dateFormat = "EEE"
        return (0 ..< 7).reversed().map { offset in
            let d = cal.date(byAdding: .day, value: -offset, to: Date())!
            let start = cal.startOfDay(for: d)
            let end = cal.date(byAdding: .day, value: 1, to: start)!
            let pages = sessions.filter {
                ($0.date ?? .distantPast) >= start && ($0.date ?? .distantPast) < end
            }.reduce(0) { $0 + Int($1.pagesRead) }
            return (fmt.string(from: d), pages)
        }
    }

    private var avgPagesPerDay: Int {
        let cal = Calendar.current
        let monthAgo = cal.date(byAdding: .day, value: -30, to: Date())!
        let relevant = sessions.filter { ($0.date ?? .distantPast) >= monthAgo }
        let total = relevant.reduce(0) { $0 + Int($1.pagesRead) }
        let days = Set(relevant.compactMap { $0.date.map { cal.startOfDay(for: $0) } }).count
        return days > 0 ? total / days : 0
    }
}

private extension View {
    func entryAnimation(appeared: Bool, delay: Double) -> some View {
        self
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 22)
            .animation(
                .spring(response: 0.52, dampingFraction: 0.80).delay(delay),
                value: appeared
            )
    }
}

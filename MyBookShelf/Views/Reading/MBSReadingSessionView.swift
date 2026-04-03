//
//  MBSReadingSessionView.swift
//  MyBookShelf
//

import SwiftUI
import CoreData

// MARK: - Session modes

enum MBSSessionMode: String, CaseIterable {
    case free      = "Free Reading"
    case challenge = "Speed Challenge"

    var icon: String {
        switch self {
        case .free:      "timer"
        case .challenge: "bolt.fill"
        }
    }

    var description: String {
        switch self {
        case .free:      "Read freely — timer tracks your time"
        case .challenge: "Set a time goal and push yourself"
        }
    }
}

// MARK: - Main view

struct MBSReadingSessionView: View {

    @EnvironmentObject private var tabState: MBSTabState
    @ObservedObject private var timer = ReadingTimerService.shared
    @Environment(\.managedObjectContext) private var moc

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Book.dateAdded, ascending: false)],
        predicate: NSPredicate(format: "status == %d", 1),
        animation: .none
    )
    private var readingBooks: FetchedResults<Book>

    @State private var mode: MBSSessionMode = .free
    @State private var targetMinutes: Int = 10
    @State private var selectedBook: Book?
    @State private var showFinish = false
    @State private var pagesInput = ""
    @State private var challengeDone = false
    @State private var challengeHandled = false  // prevents double-fire from elapsedSeconds reset
    @State private var celebrateScale: CGFloat = 0.6
    @State private var celebrateOpacity: Double = 0

    private let durations = [5, 10, 15, 20, 30]

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                MBSAtmosphereBackground()

                VStack(spacing: 0) {
                    // Live indicator pill when running
                    if timer.isRunning {
                        liveBanner
                            .padding(.top, 4)
                            .transition(.opacity.combined(with: .offset(y: -6)))
                    }

                    // Mode picker (hidden while timer runs)
                    if !timer.isRunning {
                        modePicker
                            .padding(.top, 20)
                            .padding(.horizontal, 20)
                            .transition(.opacity.combined(with: .offset(y: -8)))
                    }

                    Spacer()

                    mainTimer
                        .padding(.horizontal, 24)

                    Spacer()

                    if !timer.isRunning || selectedBook != nil {
                        bookPickerRow
                            .padding(.horizontal, 20)
                            .padding(.bottom, 12)
                            .transition(.opacity)
                    }

                    if mode == .challenge && !timer.isRunning && !challengeDone {
                        durationPicker
                            .padding(.horizontal, 20)
                            .padding(.bottom, 16)
                            .transition(.opacity.combined(with: .offset(y: 8)))
                    }

                    controlButtons
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                }
                .animation(.spring(response: 0.42, dampingFraction: 0.80), value: timer.isRunning)
                .animation(.easeInOut(duration: 0.25), value: mode)

                if challengeDone {
                    challengeCompleteOverlay
                        .transition(.opacity.combined(with: .scale(scale: 0.92)))
                }

                if showFinish {
                    finishInputOverlay
                        .transition(.opacity.combined(with: .scale(scale: 0.94)))
                }
            }
            .navigationTitle("Timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.background.opacity(0.92), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .onAppear {
            if selectedBook == nil, let first = readingBooks.first {
                selectedBook = first
            }
            // Sync tab state if timer was pre-started (e.g. mock data)
            tabState.readingSessionActive = timer.isRunning
        }
        .onChange(of: timer.isRunning) { running in
            tabState.readingSessionActive = running
        }
        .onChange(of: timer.elapsedSeconds) { elapsed in
            // Guard prevents re-entry when timer.stop() resets elapsedSeconds = 0 in the same frame
            guard mode == .challenge, timer.isRunning, !timer.isPaused, !challengeHandled else { return }
            if elapsed >= targetMinutes * 60 {
                challengeHandled = true
                handleChallengeComplete()
            }
        }
    }

    // MARK: - Live banner (replaces header close button)

    private var liveBanner: some View {
        HStack(spacing: 8) {
            LiveDot()
            Text("Session in progress")
                .font(.mbsCaption(12))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(
            Capsule()
                .fill(AppTheme.backgroundSecondary)
                .overlay(Capsule().stroke(AppTheme.accentLamp.opacity(0.35), lineWidth: 1))
        )
    }

    // MARK: - Mode picker

    private var modePicker: some View {
        HStack(spacing: 0) {
            ForEach(MBSSessionMode.allCases, id: \.self) { m in
                Button {
                    withAnimation { mode = m }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: m.icon)
                            .font(.system(size: 13, weight: .medium))
                        Text(m.rawValue)
                            .font(.mbsBody(13, weight: .medium))
                    }
                    .foregroundStyle(mode == m ? AppTheme.backgroundSecondary : AppTheme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background {
                        if mode == m {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(AppTheme.accentLamp)
                                .shadow(color: AppTheme.accentLamp.opacity(0.45), radius: 8)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(AppTheme.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.outlineLamp, lineWidth: 1))
    }

    // MARK: - Circular timer (live)

    private var mainTimer: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !timer.isRunning && timer.elapsedSeconds == 0)) { ctx in
            timerFace(ctx: ctx)
        }
    }

    private func timerFace(ctx: TimelineViewDefaultContext) -> some View {
        let elapsed = Double(timer.elapsedSeconds)
        let total = Double(targetMinutes * 60)

        let arcProgress: CGFloat = mode == .challenge
            ? CGFloat(min(1.0, elapsed / max(1, total)))
            : CGFloat(elapsed.truncatingRemainder(dividingBy: 3600.0) / 3600.0)

        let displayMin: Int
        let displaySec: Int
        if mode == .challenge {
            let rem = max(0, Int(total) - Int(elapsed))
            displayMin = rem / 60; displaySec = rem % 60
        } else {
            displayMin = Int(elapsed) / 60; displaySec = Int(elapsed) % 60
        }

        let t = ctx.date.timeIntervalSinceReferenceDate
        let breath: CGFloat = timer.isRunning
            ? (0.90 + 0.10 * CGFloat(abs(sin(t * 1.2))))
            : 1.0

        return ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [AppTheme.accentLamp.opacity(0.18 * breath), Color.clear],
                        center: .center, startRadius: 80, endRadius: 140
                    )
                )
                .frame(width: 280, height: 280)
                .scaleEffect(breath)
                .blur(radius: 14)

            Circle()
                .fill(AppTheme.backgroundSecondary)
                .frame(width: 220, height: 220)
                .overlay(Circle().stroke(AppTheme.outlineLamp, lineWidth: 1))

            Circle()
                .stroke(AppTheme.backgroundTertiary, lineWidth: 10)
                .frame(width: 196, height: 196)

            Circle()
                .trim(from: 0, to: arcProgress)
                .stroke(
                    LinearGradient(
                        colors: [AppTheme.accentLampLight, AppTheme.accentLamp, AppTheme.accentLampDark],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .frame(width: 196, height: 196)
                .rotationEffect(.degrees(-90))
                .shadow(color: AppTheme.accentLamp.opacity(timer.isRunning ? 0.60 : 0.20), radius: 12)

            VStack(spacing: 3) {
                Text(String(format: "%d:%02d", displayMin, displaySec))
                    .font(.system(size: 52, weight: .bold, design: .monospaced))
                    .foregroundStyle(AppTheme.textPrimary)
                    .shadow(color: AppTheme.accentLamp.opacity(0.25 * breath), radius: 10)
                    .monospacedDigit()

                Text(mode == .challenge ? "remaining" : "elapsed")
                    .font(.mbsCaption(12))
                    .foregroundStyle(AppTheme.textSecondary)

                if timer.isRunning, mode == .free, elapsed > 30 {
                    speedHint(elapsed: elapsed)
                }
            }
        }
    }

    @ViewBuilder
    private func speedHint(elapsed: Double) -> some View {
        if let book = selectedBook, book.totalPages > 0 {
            let estimated = Int(elapsed / 3600 * 200)
            Text("≈ \(estimated) pg/h")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(AppTheme.accentLamp.opacity(0.75))
                .padding(.top, 2)
        }
    }

    // MARK: - Book picker

    private var bookPickerRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("BOOK")
                .font(.mbsCaption(11))
                .foregroundStyle(AppTheme.textMuted)
                .padding(.leading, 4)

            if readingBooks.isEmpty {
                HStack {
                    Image(systemName: "book")
                        .foregroundStyle(AppTheme.textMuted)
                    Text("No books in progress")
                        .font(.mbsBody(14))
                        .foregroundStyle(AppTheme.textMuted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .mbsCard()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(readingBooks, id: \.id) { book in
                            let isSelected = selectedBook?.id == book.id
                            Button {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
                                    selectedBook = book
                                }
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(book.title ?? "")
                                        .font(.mbsBody(13, weight: isSelected ? .semibold : .regular))
                                        .foregroundStyle(isSelected ? AppTheme.backgroundSecondary : AppTheme.textPrimary)
                                        .lineLimit(2)
                                    Text(book.author ?? "")
                                        .font(.mbsCaption(11))
                                        .foregroundStyle(isSelected ? AppTheme.backgroundSecondary.opacity(0.75) : AppTheme.textSecondary)
                                        .lineLimit(1)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(isSelected ? AppTheme.accentLamp : AppTheme.backgroundSecondary)
                                }
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            isSelected ? AppTheme.accentLampLight.opacity(0.5) : AppTheme.outlineLamp,
                                            lineWidth: 1
                                        )
                                )
                                .shadow(color: isSelected ? AppTheme.accentLamp.opacity(0.35) : .clear, radius: 8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Duration picker (Speed Challenge only)

    private var durationPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("TARGET")
                .font(.mbsCaption(11))
                .foregroundStyle(AppTheme.textMuted)
                .padding(.leading, 4)

            HStack(spacing: 8) {
                ForEach(durations, id: \.self) { min in
                    let isSelected = targetMinutes == min
                    Button {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.72)) {
                            targetMinutes = min
                        }
                    } label: {
                        Text("\(min)m")
                            .font(.mbsBody(14, weight: isSelected ? .semibold : .regular))
                            .foregroundStyle(isSelected ? AppTheme.backgroundSecondary : AppTheme.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(isSelected ? AppTheme.accentLamp : AppTheme.backgroundSecondary)
                            }
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(isSelected ? Color.clear : AppTheme.outlineLamp, lineWidth: 1)
                            )
                            .shadow(color: isSelected ? AppTheme.accentLamp.opacity(0.35) : .clear, radius: 6)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Control buttons

    private var controlButtons: some View {
        VStack(spacing: 12) {
            if !timer.isRunning && !challengeDone {
                Button { startSession() } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 17, weight: .semibold))
                        Text("Start Session")
                            .font(.mbsBody(17, weight: .semibold))
                    }
                    .foregroundStyle(AppTheme.backgroundSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [AppTheme.accentLampLight, AppTheme.accentLamp, AppTheme.accentLampDark],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AppTheme.accentLampLight.opacity(0.45), lineWidth: 1)
                    )
                    .shadow(color: AppTheme.accentLamp.opacity(0.45), radius: 14, y: 4)
                }
                .buttonStyle(.plain)

            } else if timer.isRunning {
                HStack(spacing: 12) {
                    Button {
                        if timer.isPaused { timer.resume() } else { timer.pause() }
                    } label: {
                        Image(systemName: timer.isPaused ? "play.fill" : "pause.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(AppTheme.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppTheme.backgroundSecondary)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(AppTheme.outlineLamp, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)

                    Button { stopSession() } label: {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(AppTheme.backgroundSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [AppTheme.accentLampLight, AppTheme.accentLamp],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: AppTheme.accentLamp.opacity(0.35), radius: 10, y: 3)
                    }
                    .buttonStyle(.plain)
                }

            } else if challengeDone {
                Button { showFinish = true } label: {
                    Text("Log Pages")
                        .font(.mbsBody(17, weight: .semibold))
                        .foregroundStyle(AppTheme.backgroundSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(LinearGradient.mbsLampAccent)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: AppTheme.accentLamp.opacity(0.45), radius: 14, y: 4)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Challenge complete overlay

    private var challengeCompleteOverlay: some View {
        ZStack {
            Color.black.opacity(0.62).ignoresSafeArea()

            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(AppTheme.accentLamp.opacity(0.18))
                        .frame(width: 110, height: 110)
                        .blur(radius: 12)
                    Circle()
                        .fill(AppTheme.backgroundSecondary)
                        .frame(width: 88, height: 88)
                        .overlay(Circle().stroke(AppTheme.accentLamp.opacity(0.55), lineWidth: 1.5))
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 38, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppTheme.accentLampLight, AppTheme.accentLamp],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .shadow(color: AppTheme.accentLamp.opacity(0.70), radius: 16)
                }
                .scaleEffect(celebrateScale)
                .opacity(celebrateOpacity)

                VStack(spacing: 8) {
                    Text("Challenge Complete!")
                        .font(.mbsDisplay(22))
                        .foregroundStyle(AppTheme.textPrimary)
                        .multilineTextAlignment(.center)

                    Text("\(targetMinutes) minutes done")
                        .font(.mbsBody(15))
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .opacity(celebrateOpacity)

                Button { showFinish = true } label: {
                    Text("Log Pages")
                        .font(.mbsBody(16, weight: .semibold))
                        .foregroundStyle(AppTheme.backgroundSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(LinearGradient.mbsLampAccent)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: AppTheme.accentLamp.opacity(0.45), radius: 12)
                }
                .buttonStyle(.plain)
                .opacity(celebrateOpacity)
                .padding(.horizontal, 32)
            }
            .padding(32)
        }
        .onAppear {
            withAnimation(.spring(response: 0.60, dampingFraction: 0.60)) {
                celebrateScale = 1.0
                celebrateOpacity = 1.0
            }
        }
    }

    // MARK: - Finish / pages input overlay

    private var finishInputOverlay: some View {
        ZStack {
            Color.black.opacity(0.65).ignoresSafeArea()

            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundStyle(AppTheme.accentLamp)
                        .shadow(color: AppTheme.accentLamp.opacity(0.55), radius: 10)

                    Text("How many pages did you read?")
                        .font(.mbsDisplay(20))
                        .foregroundStyle(AppTheme.textPrimary)
                        .multilineTextAlignment(.center)

                    if let book = selectedBook {
                        Text(book.title ?? "")
                            .font(.mbsCaption(13))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }

                VStack(spacing: 10) {
                    TextField("Pages read", text: $pagesInput)
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundStyle(AppTheme.textPrimary)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .padding(16)
                        .background(AppTheme.backgroundTertiary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppTheme.accentLamp.opacity(0.35), lineWidth: 1)
                        )

                    Text("Session time: \(timer.formattedTime)")
                        .font(.mbsCaption(12))
                        .foregroundStyle(AppTheme.textMuted)
                }

                HStack(spacing: 12) {
                    Button {
                        pagesInput = ""
                        showFinish = false
                        if challengeDone { resetSession() }
                    } label: {
                        Text("Skip")
                            .font(.mbsBody(15))
                            .foregroundStyle(AppTheme.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AppTheme.backgroundSecondary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(AppTheme.outlineLamp, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)

                    Button { saveSession() } label: {
                        Text("Save")
                            .font(.mbsBody(15, weight: .semibold))
                            .foregroundStyle(AppTheme.backgroundSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(LinearGradient.mbsLampAccent)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: AppTheme.accentLamp.opacity(0.40), radius: 8)
                    }
                    .buttonStyle(.plain)
                    .disabled(pagesInput.isEmpty)
                    .opacity(pagesInput.isEmpty ? 0.55 : 1)
                }
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(AppTheme.backgroundElevated)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(AppTheme.accentLamp.opacity(0.28), lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.45), radius: 30, y: 10)
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Logic

    private func startSession() {
        let bookID = selectedBook?.id ?? UUID()
        let bookTitle = selectedBook?.title ?? "Unknown"
        let target = mode == .challenge ? targetMinutes * 60 : nil
        timer.start(bookID: bookID, bookTitle: bookTitle, targetSeconds: target)
        tabState.readingSessionActive = true
        challengeDone = false
    }

    private func stopSession() {
        _ = timer.stop()
        tabState.readingSessionActive = false
        showFinish = true
    }

    private func handleChallengeComplete() {
        _ = timer.stop()
        tabState.readingSessionActive = false
        withAnimation(.spring(response: 0.48, dampingFraction: 0.72)) {
            challengeDone = true
        }
    }

    private func saveSession() {
        let pages = Int(pagesInput) ?? 0
        let minutes = timer.elapsedMinutes > 0 ? timer.elapsedMinutes : targetMinutes

        let session = ReadingSession(context: moc)
        session.id = UUID()
        session.date = Date()
        session.pagesRead = Int32(pages)
        session.durationMinutes = Int32(minutes)
        if let book = selectedBook { session.book = book }

        let profileReq = UserProfile.fetchRequest()
        profileReq.fetchLimit = 1
        if let profile = try? moc.fetch(profileReq).first {
            profile.totalPagesRead += Int32(pages)
            if pages > 0 { profile.lastReadingDate = Date() }
        }

        try? moc.save()

        tabState.showToast(
            pages > 0 ? "Session saved · \(pages) pages" : "Session saved",
            icon: "checkmark.circle.fill"
        )

        pagesInput = ""
        showFinish = false
        resetSession()
    }

    private func resetSession() {
        timer.cancel()
        tabState.readingSessionActive = false
        challengeDone = false
        challengeHandled = false
        celebrateScale = 0.6
        celebrateOpacity = 0
    }
}

// MARK: - Live pulsing dot

private struct LiveDot: View {
    @State private var pulse = false

    var body: some View {
        ZStack {
            Circle()
                .fill(AppTheme.accentLamp.opacity(0.30))
                .frame(width: 18, height: 18)
                .scaleEffect(pulse ? 1.7 : 1.0)
                .opacity(pulse ? 0 : 0.8)
            Circle()
                .fill(AppTheme.accentLamp)
                .frame(width: 8, height: 8)
                .shadow(color: AppTheme.accentLamp.opacity(0.8), radius: 5)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: false)) {
                pulse = true
            }
        }
    }
}

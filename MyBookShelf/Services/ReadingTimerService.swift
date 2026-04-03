//
//  ReadingTimerService.swift
//  MyBookShelf
//

import Combine
import SwiftUI

@MainActor
final class ReadingTimerService: ObservableObject {
    static let shared = ReadingTimerService()

    @Published private(set) var isRunning = false
    @Published private(set) var isPaused = false
    @Published private(set) var elapsedSeconds: Int = 0
    @Published private(set) var targetDuration: Int? = nil  // seconds; nil = free mode
    @Published var activeBook: (id: UUID, title: String)?

    private var timer: Timer?
    private var startDate: Date?
    private var accumulatedBeforePause: TimeInterval = 0

    var formattedTime: String {
        let m = elapsedSeconds / 60
        let s = elapsedSeconds % 60
        return String(format: "%d:%02d", m, s)
    }

    var elapsedMinutes: Int { elapsedSeconds / 60 }

    func start(bookID: UUID, bookTitle: String, targetSeconds: Int? = nil) {
        activeBook = (bookID, bookTitle)
        targetDuration = targetSeconds
        accumulatedBeforePause = 0
        elapsedSeconds = 0
        isRunning = true
        isPaused = false
        startDate = Date()
        scheduleTimer()
    }

    func pause() {
        guard isRunning, !isPaused else { return }
        isPaused = true
        accumulatedBeforePause += Date().timeIntervalSince(startDate ?? Date())
        timer?.invalidate()
        timer = nil
    }

    func resume() {
        guard isRunning, isPaused else { return }
        isPaused = false
        startDate = Date()
        scheduleTimer()
    }

    func stop() -> Int {
        let total = totalElapsed()
        timer?.invalidate()
        timer = nil
        isRunning = false
        isPaused = false
        let minutes = Int(ceil(total / 60))
        elapsedSeconds = 0
        targetDuration = nil
        accumulatedBeforePause = 0
        startDate = nil
        return minutes
    }

    func cancel() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        isPaused = false
        elapsedSeconds = 0
        targetDuration = nil
        accumulatedBeforePause = 0
        startDate = nil
        activeBook = nil
    }

    private func totalElapsed() -> TimeInterval {
        if isPaused {
            return accumulatedBeforePause
        }
        return accumulatedBeforePause + Date().timeIntervalSince(startDate ?? Date())
    }

    private func scheduleTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, self.isRunning, !self.isPaused else { return }
                self.elapsedSeconds = Int(self.totalElapsed())
            }
        }
    }
}

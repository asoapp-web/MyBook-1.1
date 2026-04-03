//
//  StreakDisplaySnapshot.swift
//  MyBookShelf
//

import Foundation

/// Streak counts + calendar day set built from `ReadingStreakViewModel`.
struct StreakDisplaySnapshot {
    let currentStreak: Int
    let longestStreak: Int
    let lastReadingDate: Date?
    let readingDayStarts: Set<Date>

    func activeStreakDayStarts(calendar: Calendar) -> Set<Date> {
        guard currentStreak > 0, let last = lastReadingDate else { return [] }
        let end = calendar.startOfDay(for: last)
        var out = Set<Date>()
        for i in 0..<currentStreak {
            guard let day = calendar.date(byAdding: .day, value: -i, to: end) else { break }
            out.insert(calendar.startOfDay(for: day))
        }
        return out
    }

    func hasReading(on day: Date, calendar: Calendar) -> Bool {
        readingDayStarts.contains(calendar.startOfDay(for: day))
    }

    func isInActiveStreak(_ day: Date, calendar: Calendar) -> Bool {
        activeStreakDayStarts(calendar: calendar).contains(calendar.startOfDay(for: day))
    }

    static func from(viewModel: ReadingStreakViewModel, calendar: Calendar) -> StreakDisplaySnapshot {
        let p = viewModel.profile
        return StreakDisplaySnapshot(
            currentStreak: Int(p?.currentStreak ?? 0),
            longestStreak: Int(p?.longestStreak ?? 0),
            lastReadingDate: p?.lastReadingDate,
            readingDayStarts: viewModel.readingDayStarts
        )
    }
}

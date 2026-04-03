//
//  ReadingStreakViewModel.swift
//  MyBookShelf
//

import Combine
import CoreData
import Foundation
import SwiftUI

@MainActor
final class ReadingStreakViewModel: ObservableObject {
    @Published private(set) var readingDayStarts: Set<Date> = []
    @Published private(set) var profile: UserProfile?

    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
        refresh()
    }

    func refresh() {
        let preq = UserProfile.fetchRequest()
        preq.fetchLimit = 1
        profile = try? context.fetch(preq).first

        let sreq = ReadingSession.fetchRequest()
        guard let sessions = try? context.fetch(sreq) else {
            readingDayStarts = []
            return
        }
        let cal = Calendar.current
        var set = Set<Date>()
        for s in sessions {
            guard let d = s.date else { continue }
            set.insert(cal.startOfDay(for: d))
        }
        readingDayStarts = set
    }

    /// Days that belong to the current streak chain (ending on last reading day).
    func activeStreakDayStarts(calendar cal: Calendar = .current) -> Set<Date> {
        guard let p = profile, p.currentStreak > 0, let last = p.lastReadingDate else { return [] }
        let end = cal.startOfDay(for: last)
        var out = Set<Date>()
        for i in 0..<Int(p.currentStreak) {
            guard let day = cal.date(byAdding: .day, value: -i, to: end) else { break }
            out.insert(cal.startOfDay(for: day))
        }
        return out
    }

    func hasReading(on day: Date, calendar cal: Calendar = .current) -> Bool {
        readingDayStarts.contains(cal.startOfDay(for: day))
    }

    func isInActiveStreak(_ day: Date, calendar cal: Calendar = .current) -> Bool {
        activeStreakDayStarts(calendar: cal).contains(cal.startOfDay(for: day))
    }
}

//
//  Quest.swift
//  MyBookShelf
//

import Foundation

enum QuestType: String {
    case daily
    case weekly
    case challenge
}

enum QuestRequirementType: String {
    case readPages
    case readMinutes
    case finishBook
    case addBook
    case readDaysInRow
    case rateBooks
}

struct QuestRequirement {
    let type: QuestRequirementType
    let value: Int
}

struct Quest: Identifiable {
    let id: String
    let title: String
    let description: String
    let xpReward: Int
    let type: QuestType
    let requirement: QuestRequirement
    let iconName: String
}

enum QuestData {
    static let dailyTemplates: [Quest] = [
        Quest(id: "daily_pages_20", title: "Daily Pages I", description: "Read 20 pages today — steady progress.",
              xpReward: 10, type: .daily, requirement: QuestRequirement(type: .readPages, value: 20), iconName: "book.fill"),
        Quest(id: "daily_pages_50", title: "Daily Pages II", description: "Read 50 pages today — go all in.",
              xpReward: 25, type: .daily, requirement: QuestRequirement(type: .readPages, value: 50), iconName: "flame.fill"),
        Quest(id: "daily_add_1", title: "Expand the Shelf", description: "Add a new book to your library today.",
              xpReward: 5, type: .daily, requirement: QuestRequirement(type: .addBook, value: 1), iconName: "plus.circle.fill")
    ]

    static let weeklyTemplates: [Quest] = [
        Quest(id: "weekly_pages_100", title: "Weekly Reader I", description: "Read 100 pages before the week ends.",
              xpReward: 30, type: .weekly, requirement: QuestRequirement(type: .readPages, value: 100), iconName: "book.fill"),
        Quest(id: "weekly_pages_250", title: "Weekly Reader II", description: "Read 250 pages this week — serious mode.",
              xpReward: 75, type: .weekly, requirement: QuestRequirement(type: .readPages, value: 250), iconName: "flame.fill"),
        Quest(id: "weekly_finish_1", title: "Close One Out", description: "Finish at least one book this week.",
              xpReward: 40, type: .weekly, requirement: QuestRequirement(type: .finishBook, value: 1), iconName: "checkmark.circle.fill"),
        Quest(id: "weekly_streak_5", title: "Streak Builder", description: "Keep a reading streak of 5+ days (current streak counts).",
              xpReward: 50, type: .weekly, requirement: QuestRequirement(type: .readDaysInRow, value: 5), iconName: "flame.fill")
    ]

    static let challenges: [Quest] = [
        Quest(id: "challenge_marathon", title: "Sprint Reader", description: "Read 500 pages within any rolling 7-day window.",
              xpReward: 100, type: .challenge, requirement: QuestRequirement(type: .readPages, value: 500), iconName: "figure.run"),
        Quest(id: "challenge_triple", title: "Triple Finish", description: "Finish 3 books in total (lifetime challenge).",
              xpReward: 60, type: .challenge, requirement: QuestRequirement(type: .finishBook, value: 3), iconName: "books.vertical.fill"),
        Quest(id: "challenge_rating", title: "The Critic", description: "Rate 10 books with stars.",
              xpReward: 30, type: .challenge, requirement: QuestRequirement(type: .rateBooks, value: 10), iconName: "star.fill")
    ]
}

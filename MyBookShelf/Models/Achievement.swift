//
//  Achievement.swift
//

import Foundation

enum AchievementCategory: String, CaseIterable {
    case books
    case pages
    case streak
    case genre
    case special

    var label: String {
        switch self {
        case .books: return "Books"
        case .pages: return "Pages"
        case .streak: return "Streaks"
        case .genre: return "Genres"
        case .special: return "Special"
        }
    }
}

enum RequirementType: String {
    case booksFinished
    case pagesRead
    case streakDays
    case booksInGenre
    case totalBooksAdded
    case ratingGiven
    case favoriteBooks
}

struct AchievementRequirement {
    let type: RequirementType
    let value: Int
    let genre: String?
}

struct Achievement: Identifiable {
    let id: String
    let title: String
    let description: String
    let iconName: String
    let xpReward: Int
    let category: AchievementCategory
    let requirement: AchievementRequirement
}

enum AchievementData {
    /// Unlocked only from code paths (e.g. finish a 500+ page book), not from generic `checkAchievements`.
    static let manualOnlyAchievementIds: Set<String> = ["thick_book"]

    static let all: [Achievement] = [
        Achievement(id: "first_book", title: "First Book", description: "Add your first book to the library",
                    iconName: "book.fill", xpReward: 10, category: .special,
                    requirement: AchievementRequirement(type: .totalBooksAdded, value: 1, genre: nil)),
        Achievement(id: "reader_5", title: "Beginner Reader", description: "Finish reading 5 books",
                    iconName: "book.closed.fill", xpReward: 25, category: .books,
                    requirement: AchievementRequirement(type: .booksFinished, value: 5, genre: nil)),
        Achievement(id: "reader_10", title: "Bookworm", description: "Finish reading 10 books",
                    iconName: "books.vertical.fill", xpReward: 50, category: .books,
                    requirement: AchievementRequirement(type: .booksFinished, value: 10, genre: nil)),
        Achievement(id: "reader_25", title: "Bibliophile", description: "Finish reading 25 books",
                    iconName: "text.book.closed.fill", xpReward: 100, category: .books,
                    requirement: AchievementRequirement(type: .booksFinished, value: 25, genre: nil)),
        Achievement(id: "reader_50", title: "Legend", description: "Finish reading 50 books",
                    iconName: "crown.fill", xpReward: 200, category: .books,
                    requirement: AchievementRequirement(type: .booksFinished, value: 50, genre: nil)),
        Achievement(id: "pages_100", title: "Hundred Pages", description: "Read 100 pages total",
                    iconName: "doc.text.fill", xpReward: 15, category: .pages,
                    requirement: AchievementRequirement(type: .pagesRead, value: 100, genre: nil)),
        Achievement(id: "pages_1000", title: "Thousand Pages", description: "Read 1000 pages total",
                    iconName: "doc.on.doc.fill", xpReward: 75, category: .pages,
                    requirement: AchievementRequirement(type: .pagesRead, value: 1000, genre: nil)),
        Achievement(id: "pages_10000", title: "Ten Thousand", description: "Read 10000 pages total",
                    iconName: "infinity", xpReward: 250, category: .pages,
                    requirement: AchievementRequirement(type: .pagesRead, value: 10000, genre: nil)),
        Achievement(id: "streak_3", title: "Three Day Streak", description: "Read 3 days in a row",
                    iconName: "flame.fill", xpReward: 20, category: .streak,
                    requirement: AchievementRequirement(type: .streakDays, value: 3, genre: nil)),
        Achievement(id: "streak_7", title: "Reading Week", description: "Read 7 days in a row",
                    iconName: "flame.fill", xpReward: 50, category: .streak,
                    requirement: AchievementRequirement(type: .streakDays, value: 7, genre: nil)),
        Achievement(id: "streak_14", title: "Fortnight Flame", description: "Read 14 days in a row",
                    iconName: "flame.circle.fill", xpReward: 40, category: .streak,
                    requirement: AchievementRequirement(type: .streakDays, value: 14, genre: nil)),
        Achievement(id: "streak_30", title: "Month of Discipline", description: "Read 30 days in a row",
                    iconName: "flame.fill", xpReward: 150, category: .streak,
                    requirement: AchievementRequirement(type: .streakDays, value: 30, genre: nil)),
        Achievement(id: "streak_60", title: "Two-Month March", description: "Read 60 days in a row",
                    iconName: "fire.circle.fill", xpReward: 180, category: .streak,
                    requirement: AchievementRequirement(type: .streakDays, value: 60, genre: nil)),
        Achievement(id: "streak_100", title: "Century Chain", description: "Read 100 days in a row",
                    iconName: "crown.fill", xpReward: 320, category: .streak,
                    requirement: AchievementRequirement(type: .streakDays, value: 100, genre: nil)),
        Achievement(id: "genre_5", title: "Genre Explorer", description: "Read 5 books in Science Fiction",
                    iconName: "sparkles", xpReward: 30, category: .genre,
                    requirement: AchievementRequirement(type: .booksInGenre, value: 5, genre: "Science Fiction")),
        Achievement(id: "collector_10", title: "Collector", description: "Add 10 books to your library",
                    iconName: "square.stack.3d.up.fill", xpReward: 25, category: .special,
                    requirement: AchievementRequirement(type: .totalBooksAdded, value: 10, genre: nil)),
        Achievement(id: "rater_5", title: "Critic", description: "Rate 5 books",
                    iconName: "star.fill", xpReward: 15, category: .special,
                    requirement: AchievementRequirement(type: .ratingGiven, value: 5, genre: nil)),
        Achievement(id: "favorite_5", title: "Favorites", description: "Add 5 books to favorites",
                    iconName: "heart.fill", xpReward: 20, category: .special,
                    requirement: AchievementRequirement(type: .favoriteBooks, value: 5, genre: nil)),
        Achievement(id: "thick_book", title: "Tome Slayer", description: "Finish a book of 500+ pages",
                    iconName: "book.closed.fill", xpReward: 35, category: .special,
                    requirement: AchievementRequirement(type: .booksFinished, value: 1, genre: nil)),
    ]

    static func by(id: String) -> Achievement? {
        all.first { $0.id == id }
    }
}

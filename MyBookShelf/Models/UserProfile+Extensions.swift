//
//  UserProfile+Extensions.swift
//  MyBookShelf
//

import CoreData

extension UserProfile {
    var unlockedShelfStyles: [String] {
        get {
            guard let s = unlockedShelfStylesData, !s.isEmpty else { return ["wood_classic"] }
            return s.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
        }
        set { unlockedShelfStylesData = newValue.isEmpty ? nil : newValue.joined(separator: ",") }
    }

    var unlockedAchievementIDs: [String] {
        get {
            guard let s = unlockedAchievementIDsData, !s.isEmpty else { return [] }
            return s.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
        }
        set { unlockedAchievementIDsData = newValue.isEmpty ? nil : newValue.joined(separator: ",") }
    }

    var completedQuestIDs: [String] {
        get {
            guard let s = completedQuestIDsData, !s.isEmpty else { return [] }
            return s.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
        }
        set { completedQuestIDsData = newValue.isEmpty ? nil : newValue.joined(separator: ",") }
    }

    var pendingNotifyAchievementIDs: [String] {
        get {
            guard let s = pendingNotifyAchievementIdsData, !s.isEmpty else { return [] }
            return s.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        }
        set { pendingNotifyAchievementIdsData = newValue.isEmpty ? nil : newValue.joined(separator: ",") }
    }

    var pendingNotifyQuestKeys: [String] {
        get {
            guard let s = pendingNotifyQuestKeysData, !s.isEmpty else { return [] }
            return s.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        }
        set { pendingNotifyQuestKeysData = newValue.isEmpty ? nil : newValue.joined(separator: ",") }
    }
}

/// SF Symbol presets when the user has no custom profile photo.
enum ProfileAvatarSymbolSet {
    static let names: [String] = [
        "person.fill", "person.crop.circle.fill", "book.fill", "heart.fill",
        "star.fill", "flame.fill", "leaf.fill", "moon.fill", "sun.max.fill",
        "cloud.fill", "drop.fill", "bolt.fill",
    ]
}

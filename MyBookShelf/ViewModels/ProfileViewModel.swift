//
//  ProfileViewModel.swift
//  MyBookShelf
//

import Combine
import CoreData
import SwiftUI
import UIKit

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var profile: UserProfile?
    private let context = PersistenceController.shared.container.viewContext

    init() {
        fetch()
    }

    func fetch() {
        let req = UserProfile.fetchRequest()
        req.fetchLimit = 1
        profile = try? context.fetch(req).first
        objectWillChange.send()
    }

    var profileAvatarUIImage: UIImage? {
        guard let path = profile?.localAvatarPath, !path.isEmpty,
              FileManager.default.fileExists(atPath: path),
              let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let img = UIImage(data: data) else { return nil }
        return img
    }

    func saveDisplayName(_ raw: String) {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        profile?.displayName = String(trimmed.prefix(42))
        try? context.save()
        fetch()
    }

    /// Legacy / quick rename (e.g. inline); prefer `saveDisplayName` from the editor.
    func updateName(_ name: String) {
        saveDisplayName(name)
    }

    func setCustomAvatar(_ image: UIImage) {
        guard let p = profile, let id = p.id else { return }
        if let old = p.localAvatarPath, !old.isEmpty {
            CacheService.shared.deleteProfileAvatarFile(at: old)
        }
        guard let path = CacheService.shared.saveProfileAvatar(image, profileId: id) else { return }
        p.localAvatarPath = path
        try? context.save()
        fetch()
    }

    func removeCustomAvatar() {
        guard let p = profile else { return }
        if let path = p.localAvatarPath, !path.isEmpty {
            CacheService.shared.deleteProfileAvatarFile(at: path)
            p.localAvatarPath = nil
            try? context.save()
            fetch()
        }
    }

    func selectSymbolAvatar(index: Int) {
        guard let p = profile else { return }
        let maxI = max(0, ProfileAvatarSymbolSet.names.count - 1)
        let i = min(max(0, index), maxI)
        if let path = p.localAvatarPath, !path.isEmpty {
            CacheService.shared.deleteProfileAvatarFile(at: path)
            p.localAvatarPath = nil
        }
        p.avatarIndex = Int32(i)
        try? context.save()
        fetch()
    }

    func updateDailyGoal(_ pages: Int) {
        profile?.dailyGoalPages = Int32(max(1, pages))
        try? context.save()
    }

    func selectAvatar(_ index: Int) {
        selectSymbolAvatar(index: index)
    }

    var xpToNext: Int {
        guard let p = profile else { return 100 }
        return GamificationEngine.shared.xpToNextLevel(currentLevel: Int(p.currentLevel), totalXP: Int(p.totalXP))
    }

    var xpForNextLevel: Int {
        guard let p = profile else { return 100 }
        return GamificationEngine.shared.xpForLevel(Int(p.currentLevel) + 1)
    }

    var progressToNext: Double {
        guard let p = profile else { return 0 }
        let total = GamificationEngine.shared.xpForLevel(Int(p.currentLevel) + 1)
        let current = GamificationEngine.shared.xpForLevel(Int(p.currentLevel))
        guard total > current else { return 1 }
        return Double(Int(p.totalXP) - current) / Double(total - current)
    }
}

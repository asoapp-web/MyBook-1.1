//
//  HapticsService.swift
//  MyBookShelf
//

import UIKit

final class HapticsService {
    static let shared = HapticsService()

    private let isDevice: Bool

    private init() {
        #if targetEnvironment(simulator)
        isDevice = false
        #else
        isDevice = true
        #endif
    }

    func selection() {
        guard isDevice else { return }
        UISelectionFeedbackGenerator().selectionChanged()
    }

    func success() {
        guard isDevice else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    func error() {
        guard isDevice else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    func light() {
        guard isDevice else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

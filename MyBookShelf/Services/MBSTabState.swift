import Combine
import SwiftUI

enum MBSTab: Int, CaseIterable {
    case shelf = 0, search, timer, rewards, stats, profile

    var label: String {
        switch self {
        case .shelf:   "Shelf"
        case .search:  "Search"
        case .timer:   "Timer"
        case .rewards: "Rewards"
        case .stats:   "Stats"
        case .profile: "Profile"
        }
    }

    var icon: String {
        switch self {
        case .shelf:   "books.vertical"
        case .search:  "magnifyingglass"
        case .timer:   "timer"
        case .rewards: "trophy"
        case .stats:   "chart.bar"
        case .profile: "person.circle"
        }
    }

    var activeIcon: String {
        switch self {
        case .shelf:   "books.vertical.fill"
        case .search:  "magnifyingglass"
        case .timer:   "timer"
        case .rewards: "trophy.fill"
        case .stats:   "chart.bar.fill"
        case .profile: "person.circle.fill"
        }
    }
}

@MainActor
final class MBSTabState: ObservableObject {

    @Published var selectedTab: MBSTab = .shelf

    @Published private(set) var overlayDepth = 0

    func pushOverlay() { overlayDepth += 1 }
    func popOverlay() { overlayDepth = max(0, overlayDepth - 1) }

    @Published var shelfPath   = NavigationPath()
    @Published var searchPath  = NavigationPath()
    @Published var timerPath   = NavigationPath()
    @Published var rewardsPath = NavigationPath()
    @Published var statsPath   = NavigationPath()
    @Published var profilePath = NavigationPath()

    var tabBarHidden: Bool {
        overlayDepth > 0 || !currentPath.isEmpty
    }

    var currentPath: NavigationPath {
        switch selectedTab {
        case .shelf:   shelfPath
        case .search:  searchPath
        case .timer:   timerPath
        case .rewards: rewardsPath
        case .stats:   statsPath
        case .profile: profilePath
        }
    }

    func popToRoot() {
        switch selectedTab {
        case .shelf:   shelfPath   = NavigationPath()
        case .search:  searchPath  = NavigationPath()
        case .timer:   timerPath   = NavigationPath()
        case .rewards: rewardsPath = NavigationPath()
        case .stats:   statsPath   = NavigationPath()
        case .profile: profilePath = NavigationPath()
        }
    }

    @Published var rewardsBadge: Int = 0
    @Published var readingSessionActive: Bool = false
    @Published var dailyGoalPending: Bool = false

    @Published var toastMessage: String?
    @Published var toastIcon: String = "checkmark.circle.fill"

    func showToast(_ message: String, icon: String = "checkmark.circle.fill") {
        toastIcon = icon
        toastMessage = message
    }
}

extension Notification.Name {
    static let mbsSelectTab = Notification.Name("mbsSelectTab")
    static let mbsPopToRoot = Notification.Name("mbsPopToRoot")
}

struct MBSHidesTabBarModifier: ViewModifier {
    @EnvironmentObject private var tabState: MBSTabState
    func body(content: Content) -> some View {
        content
            .onAppear { tabState.pushOverlay() }
            .onDisappear { tabState.popOverlay() }
    }
}

extension View {
    func mbsHidesTabBar() -> some View { modifier(MBSHidesTabBarModifier()) }
}

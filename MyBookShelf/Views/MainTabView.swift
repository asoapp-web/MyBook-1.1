//
//  MainTabView.swift
//  MyBookShelf
//

import CoreData
import SwiftUI
import UIKit

struct MainTabView: View {
    @StateObject private var tabState = MBSTabState()
    @StateObject private var gamificationBadgeObserver = GamificationBadgeObserver()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack(alignment: .bottom) {
            AppTheme.background.ignoresSafeArea()

            tabContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .animation(.easeInOut(duration: 0.22), value: tabState.selectedTab)

            if !tabState.tabBarHidden {
                VStack(spacing: 0) {
                    Spacer()
                    MBSTabBar()
                        .padding(.bottom, 8)
                }
                .ignoresSafeArea(edges: .bottom)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            MBSToastOverlay()
        }
        .animation(.spring(response: 0.36, dampingFraction: 0.84), value: tabState.tabBarHidden)
        .environmentObject(tabState)
        .environmentObject(gamificationBadgeObserver)
        .ignoresSafeArea(.keyboard)
        .preferredColorScheme(.dark)
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
            NotificationCenter.default.post(name: .myBookShelfQuestCalendarTick, object: nil)
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                NotificationCenter.default.post(name: .myBookShelfQuestCalendarTick, object: nil)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .mbsSelectTab)) { note in
            guard let raw = note.userInfo?["tab"] as? Int,
                  let tab = MBSTab(rawValue: raw) else { return }
            withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
                tabState.selectedTab = tab
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .mbsPopToRoot)) { _ in
            tabState.popToRoot()
        }
        .onAppear {
            tabState.rewardsBadge = gamificationBadgeObserver.unreadCount
        }
        .onChange(of: gamificationBadgeObserver.unreadCount) { count in
            tabState.rewardsBadge = count
        }
    }

    private let tabBarClearance: CGFloat = 100

    @ViewBuilder
    private var tabContent: some View {
        Group {
            ShelfView(tabBarHeight: tabBarClearance)
                .opacity(tabState.selectedTab == .shelf ? 1 : 0)
                .allowsHitTesting(tabState.selectedTab == .shelf)

            SearchView(tabBarHeight: tabBarClearance)
                .opacity(tabState.selectedTab == .search ? 1 : 0)
                .allowsHitTesting(tabState.selectedTab == .search)

            MBSReadingSessionView()
                .opacity(tabState.selectedTab == .timer ? 1 : 0)
                .allowsHitTesting(tabState.selectedTab == .timer)
                .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)

            RewardsHubView()
                .opacity(tabState.selectedTab == .rewards ? 1 : 0)
                .allowsHitTesting(tabState.selectedTab == .rewards)

            StatsView(tabBarHeight: tabBarClearance)
                .opacity(tabState.selectedTab == .stats ? 1 : 0)
                .allowsHitTesting(tabState.selectedTab == .stats)

            ProfileView(tabBarHeight: tabBarClearance)
                .opacity(tabState.selectedTab == .profile ? 1 : 0)
                .allowsHitTesting(tabState.selectedTab == .profile)
        }
    }
}

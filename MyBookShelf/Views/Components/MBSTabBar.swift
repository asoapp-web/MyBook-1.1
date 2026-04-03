//
//  MBSTabBar.swift
//  MyBookShelf
//

import SwiftUI

struct MBSTabBar: View {
    @EnvironmentObject private var tabState: MBSTabState
    @EnvironmentObject private var gamificationBadges: GamificationBadgeObserver
    @ObservedObject private var timerService = ReadingTimerService.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Namespace private var tabIndicator

    var body: some View {
        HStack(spacing: 0) {
            ForEach(MBSTab.allCases, id: \.self) { tab in
                tabButton(tab)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 10)
        .background(tabBackground)
        .clipShape(RoundedRectangle(cornerRadius: 26))
        .overlay(
            RoundedRectangle(cornerRadius: 26)
                .stroke(
                    LinearGradient(
                        colors: [
                            AppTheme.accentLamp.opacity(0.38),
                            AppTheme.accentLampDark.opacity(0.18),
                            AppTheme.tabBarEdge.opacity(0.55)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .overlay(alignment: .top) {
            RoundedRectangle(cornerRadius: 1)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.18), Color.clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 1)
                .padding(.horizontal, 22)
                .offset(y: 1)
        }
        .shadow(color: AppTheme.accentLamp.opacity(0.10), radius: 20, x: 0, y: -4)
        .shadow(color: Color.black.opacity(0.30), radius: 14, x: 0, y: -2)
        .padding(.horizontal, 16)
    }

    // MARK: - Tab button

    @ViewBuilder
    private func tabButton(_ tab: MBSTab) -> some View {
        let isActive = tabState.selectedTab == tab
        let sessionActive = tab == .timer && tabState.readingSessionActive

        Button {
            if isActive {
                tabState.popToRoot()
            } else {
                withAnimation(reduceMotion ? .none : .spring(response: 0.35, dampingFraction: 0.72)) {
                    tabState.selectedTab = tab
                }
                HapticsService.shared.selection()
            }
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    // Active tab pill background
                    if isActive {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(AppTheme.accentLamp.opacity(sessionActive ? 0.22 : 0.16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(AppTheme.accentLamp.opacity(sessionActive ? 0.45 : 0.28), lineWidth: 1)
                            )
                            .frame(width: 44, height: 28)
                            .matchedGeometryEffect(id: "tabIndicator", in: tabIndicator)
                    }

                    // Timer tab: wrap icon + arc in TimelineView when session is active
                    if sessionActive {
                        TimelineView(.animation(minimumInterval: 1.0 / 15, paused: !tabState.readingSessionActive)) { ctx in
                            ZStack {
                                timerArcRing(at: ctx.date)
                                Image(systemName: tab.activeIcon)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(AppTheme.accentLamp)
                            }
                        }
                    } else {
                        Image(systemName: isActive ? tab.activeIcon : tab.icon)
                            .font(.system(size: 20, weight: isActive ? .semibold : .regular))
                            .foregroundColor(isActive ? AppTheme.accentLamp : AppTheme.textMuted)
                            .scaleEffect(isActive ? 1.08 : 1.0)
                            .animation(reduceMotion ? .none : .spring(response: 0.3, dampingFraction: 0.65), value: isActive)
                    }

                    // Badge / dot overlays for non-timer tabs
                    tabOverlays(tab: tab, isActive: isActive)
                }
                .frame(height: 28)

                // Label: live elapsed time for active timer tab
                if sessionActive {
                    TimelineView(.animation(minimumInterval: 1.0, paused: !tabState.readingSessionActive)) { _ in
                        Text(timerService.formattedTime)
                            .font(.system(size: 9, weight: .semibold, design: .monospaced))
                            .foregroundColor(AppTheme.accentLamp)
                    }
                } else {
                    Text(tab.label)
                        .font(.mbsTabLabel)
                        .foregroundColor(isActive ? AppTheme.accentLamp : AppTheme.textMuted)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Timer arc ring (surrounds the icon)

    private func timerArcRing(at date: Date) -> some View {
        let elapsed = Double(timerService.elapsedSeconds)
        let progress: Double = {
            if let target = timerService.targetDuration {
                return min(1.0, elapsed / Double(max(1, target)))
            }
            // Free mode: progress within 60-min cycle
            return min(1.0, elapsed.truncatingRemainder(dividingBy: 3600) / 3600)
        }()

        return ZStack {
            Circle()
                .stroke(AppTheme.accentLamp.opacity(0.14), lineWidth: 2)
                .frame(width: 38, height: 38)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [AppTheme.accentLampLight, AppTheme.accentLamp, AppTheme.accentLampDark],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                )
                .frame(width: 38, height: 38)
                .rotationEffect(.degrees(-90))
                .shadow(color: AppTheme.accentLamp.opacity(0.65), radius: 4)
        }
    }

    // MARK: - Badges / dot overlays

    @ViewBuilder
    private func tabOverlays(tab: MBSTab, isActive: Bool) -> some View {
        switch tab {
        case .rewards where gamificationBadges.unreadCount > 0:
            badgeView(count: gamificationBadges.unreadCount)
                .offset(x: 14, y: -12)

        case .stats where tabState.dailyGoalPending && !isActive:
            Circle()
                .fill(AppTheme.accentLamp)
                .frame(width: 6, height: 6)
                .overlay(Circle().stroke(AppTheme.background.opacity(0.5), lineWidth: 1))
                .offset(x: 12, y: -11)

        default:
            EmptyView()
        }
    }

    private func badgeView(count: Int) -> some View {
        Text(count > 9 ? "9+" : "\(count)")
            .font(.system(size: 9, weight: .bold, design: .rounded))
            .foregroundColor(AppTheme.background)
            .padding(.horizontal, count > 9 ? 3 : 4)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(AppTheme.accentLamp)
                    .overlay(Capsule().stroke(AppTheme.textPrimary.opacity(0.3), lineWidth: 0.5))
            )
    }

    @ViewBuilder
    private var tabBackground: some View {
        RoundedRectangle(cornerRadius: 26).fill(LinearGradient.mbsTabBarGradient)
    }
}

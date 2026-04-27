import SwiftUI

struct TabNumericBadge: View {
    let count: Int

    private var text: String {
        if count > 99 { return "99+" }
        return "\(count)"
    }

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, count > 9 ? 5 : 6)
            .frame(minWidth: 18, minHeight: 18)
            .background(Capsule().fill(Color.red))
            .overlay(Capsule().stroke(Color.white.opacity(0.25), lineWidth: 0.5))
    }
}

struct FloatingGlassTabBar: View {
    @Binding var selection: Int
    @EnvironmentObject private var tabBarChrome: FloatingTabBarChrome
    @EnvironmentObject private var gamificationBadges: GamificationBadgeObserver

    private let items: [(icon: String, title: String)] = [
        ("books.vertical", "Shelf"),
        ("magnifyingglass", "Search"),
        ("trophy.fill", "Rewards"),
        ("chart.bar", "Stats"),
        ("person.circle", "Profile"),
    ]

    private let rewardsTabIndex = 2

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                Button {
                    guard selection != index else { return }
                    HapticsService.shared.selection()
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                        selection = index
                    }
                } label: {
                    ZStack(alignment: .topTrailing) {
                        VStack(spacing: 3) {
                            Image(systemName: item.icon)
                                .font(.system(size: index == rewardsTabIndex ? 19 : 20, weight: selection == index ? .semibold : .regular))
                            Text(item.title)
                                .font(.system(size: 9, weight: selection == index ? .semibold : .regular))
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)
                        }
                        .foregroundStyle(selection == index ? AppTheme.accentOrangeLight : AppTheme.textMuted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)

                        if index == rewardsTabIndex, gamificationBadges.unreadCount > 0 {
                            TabNumericBadge(count: gamificationBadges.unreadCount)
                                .offset(x: 10, y: -2)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 6)
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(AppTheme.background.opacity(0.94))
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .background(
                        RoundedRectangle(cornerRadius: 30, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.1),
                                        Color.white.opacity(0.03),
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 30, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.22),
                                        Color.white.opacity(0.06),
                                        Color.white.opacity(0.11),
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            }
            .shadow(color: .black.opacity(0.45), radius: 24, y: 12)
        }
        .padding(.horizontal, 12)
        .opacity(tabBarChrome.isHidden ? 0 : 1)
        .allowsHitTesting(!tabBarChrome.isHidden)
        .animation(.easeInOut(duration: 0.22), value: tabBarChrome.isHidden)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: gamificationBadges.unreadCount)
    }
}

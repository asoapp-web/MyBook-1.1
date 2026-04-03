//
//  OnboardingView.swift
//  MyBookShelf
//

import SwiftUI

enum OnboardingUserDefaults {
    static let completedKey = "MyBookShelf.hasCompletedOnboarding"
}

struct OnboardingPage {
    let icon: String
    let title: String
    let description: String
}

struct OnboardingView: View {
    @Binding var isComplete: Bool
    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "books.vertical.fill",
            title: "Welcome to MyBookShelf",
            description: "Track what you read, log progress, and keep your library on your iPhone—no account required."
        ),
        OnboardingPage(
            icon: "square.stack.3d.up.fill",
            title: "Your shelf",
            description: "Browse books in a 3D cabinet, filter by status, save favorites, and tap the glass to open your full library."
        ),
        OnboardingPage(
            icon: "magnifyingglass",
            title: "Find & add",
            description: "Search Open Library or add a book by hand. Snap or pick a cover with the camera or photo library."
        ),
        OnboardingPage(
            icon: "chart.bar.fill",
            title: "Stats & goals",
            description: "Log reading sessions, set a daily page goal in Settings, and explore charts plus a calendar heat map in Stats."
        ),
        OnboardingPage(
            icon: "trophy.fill",
            title: "Rewards & streaks",
            description: "Earn XP, unlock achievements, finish quests, and build your reading streak—everything lives under Rewards."
        ),
    ]

    var body: some View {
        ZStack {
            onboardingBackdrop
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    if currentPage < pages.count - 1 {
                        Button("Skip") {
                            finish()
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppTheme.textMuted)
                    }
                }
                .frame(height: 44)
                .padding(.horizontal, 20)
                .padding(.top, 8)

                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        OnboardingPageView(page: page, isActive: currentPage == index)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                VStack(spacing: 18) {
                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { i in
                            Capsule()
                                .fill(i == currentPage ? AppTheme.accentOrange : AppTheme.textMuted.opacity(0.35))
                                .frame(width: i == currentPage ? 26 : 7, height: 7)
                                .animation(.spring(response: 0.32, dampingFraction: 0.78), value: currentPage)
                        }
                    }

                    Button {
                        HapticsService.shared.selection()
                        if currentPage == pages.count - 1 {
                            finish()
                        } else {
                            withAnimation(.easeInOut(duration: 0.28)) {
                                currentPage += 1
                            }
                        }
                    } label: {
                        Text(currentPage == pages.count - 1 ? "Get started" : "Next")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                LinearGradient(
                                    colors: [AppTheme.accentOrange, AppTheme.accentOrangeDark],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .shadow(color: AppTheme.accentOrange.opacity(0.35), radius: 12, y: 4)
                    }
                    .buttonStyle(.plain)

                    if currentPage > 0 {
                        Button {
                            withAnimation(.easeInOut(duration: 0.28)) {
                                currentPage -= 1
                            }
                        } label: {
                            Text("Back")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(AppTheme.textMuted)
                        }
                    } else {
                        Color.clear.frame(height: 22)
                    }
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 44)
            }
        }
    }

    private var onboardingBackdrop: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.12, green: 0.09, blue: 0.07),
                    AppTheme.background,
                    AppTheme.backgroundSecondary,
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            RadialGradient(
                colors: [AppTheme.shelfWood.opacity(0.45), Color.clear],
                center: .top,
                startRadius: 20,
                endRadius: 420
            )
            RadialGradient(
                colors: [AppTheme.accentOrange.opacity(0.12), Color.clear],
                center: UnitPoint(x: 0.85, y: 0.15),
                startRadius: 10,
                endRadius: 280
            )
        }
    }

    private func finish() {
        HapticsService.shared.success()
        withAnimation(.easeOut(duration: 0.32)) {
            isComplete = true
        }
    }
}

private struct OnboardingPageView: View {
    let page: OnboardingPage
    let isActive: Bool
    @State private var contentVisible = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 12)

            ZStack {
                Circle()
                    .fill(AppTheme.accentOrange.opacity(0.2))
                    .frame(width: 200, height: 200)
                    .blur(radius: 40)
                    .opacity(contentVisible ? 1 : 0)

                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.accentOrange, AppTheme.accentOrangeDark],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 128, height: 128)
                        .shadow(color: AppTheme.accentOrange.opacity(0.45), radius: 20, y: 10)

                    Image(systemName: page.icon)
                        .font(.system(size: 54, weight: .medium))
                        .foregroundStyle(.white)
                }
                .scaleEffect(contentVisible ? 1 : 0.88)
                .opacity(contentVisible ? 1 : 0)
            }

            Spacer().frame(height: 36)

            VStack(spacing: 14) {
                Text(page.title)
                    .font(.title2.bold())
                    .foregroundStyle(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)

                Text(page.description)
                    .font(.body)
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(22)
            .frame(maxWidth: 340)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(AppTheme.backgroundSecondary.opacity(0.92))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.12), AppTheme.shelfWoodLight.opacity(0.35)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .opacity(contentVisible ? 1 : 0)
            .offset(y: contentVisible ? 0 : 14)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
        .onChange(of: isActive) { active in
            if active {
                contentVisible = false
                withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) {
                    contentVisible = true
                }
            } else {
                contentVisible = false
            }
        }
        .onAppear {
            if isActive {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) {
                    contentVisible = true
                }
            }
        }
    }
}

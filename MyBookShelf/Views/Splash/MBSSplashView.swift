//
//  MBSSplashView.swift
//  MyBookShelf
//

import SwiftUI

struct MBSSplashView: View {
    let onFinished: () -> Void

    @State private var arcProgress: CGFloat = 0
    @State private var iconScale: CGFloat = 0.2
    @State private var iconOpacity: Double = 0
    @State private var titleOpacity: Double = 0
    @State private var titleOffset: CGFloat = 28
    @State private var stageIndex = 0
    @State private var stageOpacity: Double = 0
    @State private var ringRotation: Double = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let stages = [
        "Opening your shelf…",
        "Loading your library…",
        "Counting pages…",
        "Almost ready…"
    ]

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            // Breathing ambient glow — behind everything
            TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { ctx in
                let t = ctx.date.timeIntervalSinceReferenceDate
                let b = 0.82 + 0.18 * CGFloat(sin(t * 0.70))
                ambientGlow(breath: b)
            }

            VStack(spacing: 0) {
                Spacer()

                // Icon cluster
                ZStack {
                    // Outer slow-rotating dashed ring
                    if !reduceMotion {
                        Circle()
                            .stroke(
                                AngularGradient(
                                    colors: [
                                        AppTheme.accentLamp.opacity(0.55),
                                        AppTheme.accentLampLight.opacity(0.20),
                                        Color.clear,
                                        AppTheme.accentLamp.opacity(0.45)
                                    ],
                                    center: .center
                                ),
                                style: StrokeStyle(lineWidth: 1.5, dash: [5, 9])
                            )
                            .frame(width: 158, height: 158)
                            .rotationEffect(.degrees(ringRotation))
                    }

                    // Progress arc track
                    Circle()
                        .stroke(AppTheme.backgroundTertiary, lineWidth: 4)
                        .frame(width: 134, height: 134)

                    // Progress arc fill
                    Circle()
                        .trim(from: 0, to: arcProgress)
                        .stroke(
                            LinearGradient(
                                colors: [AppTheme.accentLampLight, AppTheme.accentLamp, AppTheme.accentLampDark],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 134, height: 134)
                        .rotationEffect(.degrees(-90))
                        .shadow(color: AppTheme.accentLamp.opacity(0.65), radius: 10)

                    // Icon background disc
                    Circle()
                        .fill(AppTheme.backgroundSecondary)
                        .frame(width: 104, height: 104)
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [AppTheme.accentLampLight, AppTheme.accentLampDark],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                        .shadow(color: AppTheme.accentLamp.opacity(0.20), radius: 20)

                    // Book icon
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 44, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppTheme.accentLampLight, AppTheme.accentLamp],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: AppTheme.accentLamp.opacity(0.70), radius: 18)
                }
                .scaleEffect(iconScale)
                .opacity(iconOpacity)

                Spacer().frame(height: 40)

                // App name block
                VStack(spacing: 6) {
                    Text("MyBookShelf")
                        .font(.mbsDisplay(34))
                        .foregroundStyle(AppTheme.textPrimary)
                        .shadow(color: AppTheme.accentLamp.opacity(0.25), radius: 14)

                    Text("Your reading companion")
                        .font(.mbsCaption(14))
                        .foregroundStyle(AppTheme.textMuted)
                        .tracking(1.2)
                }
                .opacity(titleOpacity)
                .offset(y: titleOffset)

                Spacer()

                // Stage text + percentage
                VStack(spacing: 8) {
                    Text(stages[min(stageIndex, stages.count - 1)])
                        .font(.mbsCaption(13))
                        .foregroundStyle(AppTheme.textSecondary)
                        .id(stageIndex)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .offset(y: 8)),
                            removal: .opacity
                        ))
                        .animation(.easeInOut(duration: 0.35), value: stageIndex)

                    Text("\(Int(arcProgress * 100))%")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(AppTheme.accentLamp.opacity(0.75))
                        .monospacedDigit()
                }
                .opacity(stageOpacity)

                Spacer().frame(height: 72)
            }
        }
        .onAppear {
            runLaunchSequence()
        }
    }

    // MARK: - Ambient glow layers

    private func ambientGlow(breath: CGFloat) -> some View {
        ZStack {
            // Centre amber corona
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            AppTheme.accentLamp.opacity(0.42),
                            AppTheme.accentLampDark.opacity(0.18),
                            AppTheme.accentLamp.opacity(0.06),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 220
                    )
                )
                .frame(width: 440, height: 440)
                .scaleEffect(breath)
                .blur(radius: 70)

            // Top-right warm flare
            Circle()
                .fill(
                    RadialGradient(
                        colors: [AppTheme.accentLampLight.opacity(0.28), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 130
                    )
                )
                .frame(width: 260, height: 260)
                .scaleEffect(breath * 0.96)
                .offset(x: 120, y: -200)
                .blur(radius: 55)

            // Bottom-left ink warmth
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            (Color(hex: "#3E1E08") ?? AppTheme.backgroundTertiary).opacity(0.65),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 140
                    )
                )
                .frame(width: 280, height: 280)
                .scaleEffect(1.8 - breath * 0.05)
                .offset(x: -130, y: 240)
                .blur(radius: 60)
        }
        .allowsHitTesting(false)
    }

    // MARK: - Launch sequence

    private func runLaunchSequence() {
        guard !reduceMotion else {
            iconScale = 1; iconOpacity = 1; titleOpacity = 1; titleOffset = 0
            arcProgress = 1; stageOpacity = 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { onFinished() }
            return
        }

        // Icon bounces in
        withAnimation(.spring(response: 0.65, dampingFraction: 0.60)) {
            iconScale = 1.0
            iconOpacity = 1.0
        }

        // Title slides up after icon
        withAnimation(.spring(response: 0.55, dampingFraction: 0.75).delay(0.22)) {
            titleOpacity = 1
            titleOffset = 0
        }

        // Decorative ring starts rotating
        withAnimation(.linear(duration: 12).repeatForever(autoreverses: false)) {
            ringRotation = 360
        }

        // Stage text fades in
        withAnimation(.easeIn(duration: 0.35).delay(0.30)) {
            stageOpacity = 1
        }

        // Progress arc + stage cycling
        let totalDuration: Double = 2.6
        let stepDuration = totalDuration / Double(stages.count)

        for i in 0 ..< stages.count {
            let delay = stepDuration * Double(i) + 0.35
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeInOut(duration: stepDuration * 0.85)) {
                    arcProgress = CGFloat(i + 1) / CGFloat(stages.count)
                }
                withAnimation(.easeInOut(duration: 0.3)) {
                    stageIndex = i
                }
            }
        }

        // Snap to 100% then call finish
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration + 0.4) {
            withAnimation(.easeOut(duration: 0.25)) { arcProgress = 1 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration + 0.95) {
            onFinished()
        }
    }
}

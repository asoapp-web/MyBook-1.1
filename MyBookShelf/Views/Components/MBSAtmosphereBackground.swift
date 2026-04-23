import SwiftUI

struct MBSAtmosphereBackground: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            ZStack {
                if reduceTransparency {
                    AppTheme.background
                } else {
                    MBSAtmosphereBaseLayer(size: size)

                    if reduceMotion {
                        MBSAtmosphereGlowLayer(size: size, breath: 1.0)
                        MBSAtmosphereSheen(size: size, t: 0)
                    } else {
                        TimelineView(.animation(minimumInterval: 1.0 / 20.0, paused: false)) { ctx in
                            let t = ctx.date.timeIntervalSinceReferenceDate
                            let breath = 0.92 + 0.08 * CGFloat(sin(t * 0.45))
                            let drift = CGFloat(sin(t * 0.28)) * 9
                            ZStack {
                                MBSAtmosphereGlowLayer(size: size, breath: breath, drift: drift)
                                MBSAtmosphereSheen(size: size, t: t)
                            }
                        }
                    }

                    MBSAtmosphereVignette(size: size)
                    MBSFilmGrainOverlay()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
    }
}

private struct MBSAtmosphereBaseLayer: View {
    let size: CGSize

    var body: some View {
        ZStack {
            LinearGradient(
                stops: [
                    .init(color: Color(hex: "#090610") ?? AppTheme.background, location: 0),
                    .init(color: Color(hex: "#0D0A16") ?? AppTheme.background, location: 0.22),
                    .init(color: Color(hex: "#0E0B14") ?? AppTheme.background, location: 0.46),
                    .init(color: Color(hex: "#150E09") ?? AppTheme.background, location: 0.70),
                    .init(color: Color(hex: "#0D0907") ?? AppTheme.background, location: 1.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [AppTheme.accentLamp.opacity(0.09), Color.clear],
                center: .init(x: 0.84, y: 0.16),
                startRadius: 10,
                endRadius: min(size.width, size.height) * 0.52
            )

            RadialGradient(
                colors: [
                    (Color(hex: "#1E0E05") ?? AppTheme.backgroundTertiary).opacity(0.40),
                    Color.clear
                ],
                center: .init(x: 0.10, y: 0.80),
                startRadius: 20,
                endRadius: min(size.width, size.height) * 0.55
            )
        }
        .allowsHitTesting(false)
    }
}

private struct MBSAtmosphereGlowLayer: View {
    let size: CGSize
    var breath: CGFloat
    var drift: CGFloat = 0

    var body: some View {
        ZStack {

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            AppTheme.accentLamp.opacity(0.55),
                            AppTheme.accentLampDark.opacity(0.28),
                            AppTheme.accentLamp.opacity(0.10),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 12,
                        endRadius: 215
                    )
                )
                .frame(width: 460, height: 460)
                .scaleEffect(breath)
                .offset(x: size.width * 0.26 + drift * 0.28, y: -size.height * 0.12)
                .blur(radius: 65)
                .allowsHitTesting(false)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            (Color(hex: "#4A2810") ?? AppTheme.backgroundTertiary).opacity(0.75),
                            AppTheme.accentLampDark.opacity(0.18),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 8,
                        endRadius: 180
                    )
                )
                .frame(width: 360, height: 360)
                .scaleEffect(1.90 - breath * 0.06)
                .offset(x: -size.width * 0.28 - drift * 0.20, y: size.height * 0.28)
                .blur(radius: 55)
                .allowsHitTesting(false)

            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            AppTheme.accentLamp.opacity(0.22),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 130
                    )
                )
                .frame(width: 260, height: 100)
                .offset(x: drift * 0.12, y: size.height * 0.25)
                .blur(radius: 40)
                .allowsHitTesting(false)

            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            AppTheme.accentLamp.opacity(0.20),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 120
                    )
                )
                .frame(width: 240, height: 96)
                .offset(x: drift * 0.10, y: -size.height * 0.10)
                .blur(radius: 36)
                .allowsHitTesting(false)
        }
    }
}

private struct MBSAtmosphereSheen: View {
    let size: CGSize
    let t: TimeInterval

    var body: some View {
        let shift = CGFloat(sin(t * 0.28)) * 26
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        AppTheme.accentLamp.opacity(0.13),
                        AppTheme.accentLampDark.opacity(0.07),
                        Color.clear
                    ],
                    startPoint: .topTrailing,
                    endPoint: .bottomLeading
                )
            )
            .frame(width: size.width * 1.6, height: 210)
            .rotationEffect(.degrees(-30))
            .offset(x: size.width * 0.22 + shift, y: -size.height * 0.10)
            .blur(radius: 52)
            .blendMode(.plusLighter)
            .opacity(0.60)
            .allowsHitTesting(false)
    }
}

private struct MBSAtmosphereVignette: View {
    let size: CGSize

    var body: some View {
        RadialGradient(
            colors: [Color.clear, Color.black.opacity(0.50)],
            center: .center,
            startRadius: 65,
            endRadius: max(size.width, size.height) * 0.88
        )
        .blendMode(.multiply)
        .allowsHitTesting(false)
    }
}

private struct MBSFilmGrainOverlay: View {
    var body: some View {
        Canvas { ctx, size in
            let step: CGFloat = 13
            var x: CGFloat = 0
            while x < size.width + step {
                var y: CGFloat = 0
                while y < size.height + step {
                    let h = UInt32(bitPattern: Int32(bitPattern: UInt32(x) &* 2654435761 &+ UInt32(y) &* 2246822519))
                    let n = (h ^ (h >> 16)) & 0xFF
                    let o = 0.010 + Double(n) / 255.0 * 0.036
                    ctx.fill(
                        Path(CGRect(x: x, y: y, width: 1.2, height: 1.2)),
                        with: .color(.white.opacity(o))
                    )
                    y += step
                }
                x += step
            }
        }
        .blendMode(.overlay)
        .opacity(0.58)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

extension View {

    @ViewBuilder
    func mbsScrollSurface() -> some View {
        if #available(iOS 16.0, *) {
            self.scrollContentBackground(.hidden)
        } else {
            self
        }
    }
}

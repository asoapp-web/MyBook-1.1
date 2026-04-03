//
//  ShelfBookTreeView.swift
//  MyBookShelf
//
//  Tree geometry follows the classic recursive “fractal tree” pattern (binary split, length & width decay),
//  similar to common CS/SwiftUI tutorials (e.g. DevGenius / SwiftUI fractals).
//

import SwiftUI

/// Pushed from `ShelfView` — no nested `NavigationStack`; system back replaces a sheet “Done”.
struct ShelfBookTreeView: View {
    @ObservedObject var profileVM: ProfileViewModel
    let bookCount: Int

    private var level: Int {
        max(1, Int(profileVM.profile?.currentLevel ?? 1))
    }

    var body: some View {
        ZStack {
            // Night garden — avoid flat black (reads better than empty modal chrome).
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.09, blue: 0.06),
                    Color(red: 0.03, green: 0.05, blue: 0.07),
                    Color(red: 0.02, green: 0.03, blue: 0.05),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [
                    Color(red: 0.1, green: 0.22, blue: 0.12).opacity(0.35),
                    Color.clear,
                ],
                center: .init(x: 0.5, y: 0.35),
                startRadius: 20,
                endRadius: 280
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

            FractalBookTreeCanvas(level: level, bookCount: bookCount)
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 8)

            VStack {
                Spacer()
                Text("Higher levels grow deeper branches and a fuller crown. Books you add appear as fruit.")
                    .font(.footnote)
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
            }
        }
        .navigationTitle("Book tree")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppTheme.background.opacity(0.92), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .suppressesFloatingTabBar()
    }
}

// MARK: - Fractal tree (Canvas)

private struct FractalBookTreeCanvas: View {
    let level: Int
    let bookCount: Int

    /// Recursion depth — main lever for “bigger tree at higher level” (full binary growth is exponential; keep bounded).
    private var maxDepth: Int {
        min(10, max(5, 4 + level / 2))
    }

    private var fruitCount: Int {
        let bc = min(999, max(0, bookCount))
        return min(64, max(2, bc / 2 + min(level + 2, 18)))
    }

    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                var rng = SeededRandom(seed: UInt64(level) &* 31 &+ UInt64(bookCount) &+ 7)
                var terminals: [CGPoint] = []

                let cx = size.width * 0.5
                let baseY = size.height - 24
                let initialLen = size.height * (0.16 + min(0.06, CGFloat(level) * 0.004))
                let maxW = max(10, size.width * 0.028 + CGFloat(level) * 0.35)

                let bark = Color(red: 0.28, green: 0.17, blue: 0.09)
                let barkHi = Color(red: 0.42, green: 0.28, blue: 0.15)

                func strokeSegment(from: CGPoint, to: CGPoint, w: CGFloat) {
                    guard w >= 0.5 else { return }
                    var p = Path()
                    p.move(to: from)
                    p.addLine(to: to)
                    context.stroke(p, with: .color(bark), style: StrokeStyle(lineWidth: w + 1.2, lineCap: .round))
                    context.stroke(p, with: .color(barkHi.opacity(0.55)), style: StrokeStyle(lineWidth: max(1, w * 0.35), lineCap: .round))
                }

                func grow(from: CGPoint, angle: CGFloat, len: CGFloat, depth: Int, width: CGFloat) {
                    if depth <= 0 || len < 4 {
                        if terminals.count < 96 {
                            terminals.append(from)
                        }
                        return
                    }

                    let jitter = (rng.nextUnit() - 0.5) * 0.09
                    let a = angle + jitter
                    let end = CGPoint(
                        x: from.x + cos(a) * len,
                        y: from.y - sin(a) * len
                    )

                    strokeSegment(from: from, to: end, w: width)

                    let shorten: CGFloat = 0.74 + rng.nextUnit() * 0.06
                    let spread: CGFloat = 0.32 + CGFloat(depth) * 0.018 + (CGFloat(level) * 0.008)
                    let nextLen = len * shorten
                    let nextW = max(0.8, width * 0.68)

                    grow(from: end, angle: a + spread, len: nextLen, depth: depth - 1, width: nextW)
                    grow(from: end, angle: a - spread, len: nextLen, depth: depth - 1, width: nextW)

                    // Occasional middle twig — richer crown at higher levels (standard fractal variation).
                    if level >= 4, depth > 3, depth < maxDepth - 1, rng.nextUnit() > 0.62 {
                        grow(from: end, angle: a + (rng.nextUnit() - 0.5) * 0.2, len: nextLen * 0.78, depth: depth - 2, width: nextW * 0.85)
                    }
                }

                // Trunk: start at bottom, grow upward (angle = π/2).
                let root = CGPoint(x: cx, y: baseY)
                grow(from: root, angle: .pi / 2, len: initialLen, depth: maxDepth, width: maxW)

                // Soft foliage clumps at branch tips (cap draws for performance).
                let tipSample = deterministicShuffle(terminals, seed: UInt64(level) &+ 101).prefix(56)
                for (i, tip) in tipSample.enumerated() {
                    let t = CGFloat(i) / CGFloat(max(1, tipSample.count - 1))
                    let radius = 14 + CGFloat(level) * 0.6 + rng.nextUnit() * 10
                    let ox = (rng.nextUnit() - 0.5) * 16
                    let oy = (rng.nextUnit() - 0.5) * 12
                    let c = CGPoint(x: tip.x + ox, y: tip.y + oy)
                    let blob = Path(ellipseIn: CGRect(x: c.x - radius, y: c.y - radius * 0.85, width: radius * 2, height: radius * 1.7))
                    let deep = Color(red: 0.05 + t * 0.04, green: 0.28 + t * 0.08, blue: 0.1 + t * 0.05)
                    let lite = Color(red: 0.12, green: 0.48, blue: 0.22).opacity(0.55)
                    context.fill(
                        blob,
                        with: .radialGradient(
                            Gradient(colors: [lite, deep.opacity(0.92)]),
                            center: c,
                            startRadius: 0,
                            endRadius: radius * 1.2
                        )
                    )
                }

                // Extra mist around the crown (reads as volume, not three flat ovals).
                for _ in 0..<min(28, 12 + level) {
                    let u = rng.nextUnit()
                    let v = rng.nextUnit()
                    let spreadX = size.width * 0.42
                    let top = size.height * 0.08
                    let bot = size.height * 0.62
                    let px = cx + (u - 0.5) * spreadX * 2
                    let py = top + v * (bot - top)
                    let r = 22 + rng.nextUnit() * 38
                    let ell = Path(ellipseIn: CGRect(x: px - r, y: py - r * 0.65, width: r * 2, height: r * 1.3))
                    context.fill(ell, with: .color(Color(red: 0.08, green: 0.32, blue: 0.16).opacity(0.14 + rng.nextUnit() * 0.08)))
                }

                // “Books” / fruit — prefer terminal tips.
                var tips = deterministicShuffle(terminals, seed: UInt64(level) ^ UInt64(fruitCount))
                if tips.isEmpty {
                    tips = [CGPoint(x: cx, y: size.height * 0.28)]
                }
                for i in 0..<fruitCount {
                    let anchor = tips[i % tips.count]
                    let jitterR: CGFloat = 10 + rng.nextUnit() * 14
                    let fx = anchor.x + (rng.nextUnit() - 0.5) * jitterR
                    let fy = anchor.y + (rng.nextUnit() - 0.5) * jitterR * 0.7
                    let fr = CGFloat(3.5 + rng.nextUnit() * 4)
                    let disk = Path(ellipseIn: CGRect(x: fx - fr, y: fy - fr, width: fr * 2, height: fr * 2))
                    let orange = Color(
                        red: 0.92 + rng.nextUnit() * 0.06,
                        green: 0.42 + rng.nextUnit() * 0.14,
                        blue: 0.06 + rng.nextUnit() * 0.1
                    )
                    context.fill(disk, with: .color(orange))
                    context.stroke(disk, with: .color(.white.opacity(0.28)), lineWidth: 0.5)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

private func deterministicShuffle<T>(_ elements: [T], seed: UInt64) -> [T] {
    var rng = SeededRandom(seed: seed == 0 ? 0xCAFEBABE : seed)
    var arr = elements
    let n = arr.count
    guard n > 1 else { return arr }
    for i in stride(from: n - 1, through: 1, by: -1) {
        let j = Int(rng.nextUnit() * CGFloat(i + 1)) % (i + 1)
        if i != j {
            arr.swapAt(i, j)
        }
    }
    return arr
}

private struct SeededRandom {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 0xDEADBEEF : seed
    }

    mutating func nextUnit() -> CGFloat {
        state &*= 6_364_136_223_846_793_005
        state &+= 1
        let x = (state >> 33) & 0x7FFF_FFFF
        return CGFloat(x) / CGFloat(0x7FFF_FFFF)
    }
}

import Combine
import SwiftUI
import UIKit
import WebKit

struct MBSSplashView: View {
    @ObservedObject var flow: MyBookShelfFlowController
    let onFinished: () -> Void

    @State private var arcProgress: CGFloat = 0
    @State private var iconScale: CGFloat = 0.2
    @State private var iconOpacity: Double = 0
    @State private var titleOpacity: Double = 0
    @State private var titleOffset: CGFloat = 28
    @State private var stageOpacity: Double = 0
    @State private var ringRotation: Double = 0
    @State private var startTime: Date?
    @State private var didCallFinish = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let minSplashDuration: TimeInterval = 3.5

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { ctx in
                let t = ctx.date.timeIntervalSinceReferenceDate
                let b = 0.82 + 0.18 * CGFloat(sin(t * 0.70))
                ambientGlow(breath: b)
            }

            VStack(spacing: 0) {
                Spacer()

                ZStack {
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

                    Circle()
                        .stroke(AppTheme.backgroundTertiary, lineWidth: 4)
                        .frame(width: 134, height: 134)

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

                VStack(spacing: 8) {
                    Text(mbsStageTitle(progress: arcProgress))
                        .font(.mbsCaption(13))
                        .foregroundStyle(AppTheme.textSecondary)
                        .id(mbsStageTitle(progress: arcProgress))
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .offset(y: 8)),
                            removal: .opacity
                        ))
                        .animation(.easeInOut(duration: 0.35), value: arcProgress)

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
            startTime = Date()
            runIntroMotion()
        }
        .onReceive(Timer.publish(every: 1.0 / 30.0, on: .main, in: .common).autoconnect()) { _ in
            guard let startTime else { return }
            let elapsed = Date().timeIntervalSince(startTime)

            if reduceMotion {
                arcProgress = 1
                guard !didCallFinish, !flow.mbsIsLoading, elapsed >= 1.2 else { return }
                didCallFinish = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    onFinished()
                }
                return
            }

            withAnimation(.linear(duration: 0.03)) {
                arcProgress = mbsComputedProgress(elapsed: elapsed)
            }
            tryFinishIfNeeded(elapsed: elapsed)
        }
    }

    private func mbsStageTitle(progress: CGFloat) -> String {
        if progress < 0.25 { return "Opening your shelf…" }
        if progress < 0.50 { return "Loading your library…" }
        if progress < 0.75 { return "Counting pages…" }
        return "Almost ready…"
    }

    private func mbsComputedProgress(elapsed: TimeInterval) -> CGFloat {
        let cap: CGFloat = 0.94
        let timePortion = min(elapsed / minSplashDuration, 1.0)
        let base = CGFloat(timePortion) * cap

        if !flow.mbsIsLoading {
            if elapsed >= minSplashDuration {
                return 1.0
            }
            return max(base, min(0.92, cap))
        }

        return min(base, cap)
    }

    private func tryFinishIfNeeded(elapsed: TimeInterval) {
        guard !didCallFinish else { return }
        guard !flow.mbsIsLoading, elapsed >= minSplashDuration else { return }
        didCallFinish = true
        withAnimation(.easeOut(duration: 0.28)) {
            arcProgress = 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            onFinished()
        }
    }

    private func runIntroMotion() {
        if reduceMotion {
            iconScale = 1
            iconOpacity = 1
            titleOpacity = 1
            titleOffset = 0
            stageOpacity = 1
            arcProgress = 1
            return
        }

        withAnimation(.spring(response: 0.65, dampingFraction: 0.60)) {
            iconScale = 1.0
            iconOpacity = 1.0
        }

        withAnimation(.spring(response: 0.55, dampingFraction: 0.75).delay(0.22)) {
            titleOpacity = 1
            titleOffset = 0
        }

        withAnimation(.linear(duration: 12).repeatForever(autoreverses: false)) {
            ringRotation = 360
        }

        withAnimation(.easeIn(duration: 0.35).delay(0.30)) {
            stageOpacity = 1
        }
    }

    private func ambientGlow(breath: CGFloat) -> some View {
        ZStack {
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
}

struct MyBookShelfDisplayView: View {
    let pageAddress: String

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            MyBookShelfWebContainer(pageAddress: pageAddress)
                .ignoresSafeArea(edges: .bottom)
        }
    }
}

struct MyBookShelfWebContainer: UIViewRepresentable {
    let pageAddress: String

    func makeCoordinator() -> MyBookShelfWebCoordinator {
        MyBookShelfWebCoordinator()
    }

    func makeUIView(context: Context) -> WKWebView {
        let mbsConfig = WKWebViewConfiguration()
        mbsConfig.defaultWebpagePreferences.allowsContentJavaScript = true
        mbsConfig.allowsInlineMediaPlayback = true
        mbsConfig.mediaTypesRequiringUserActionForPlayback = []
        mbsConfig.allowsAirPlayForMediaPlayback = true
        mbsConfig.allowsPictureInPictureMediaPlayback = true
        mbsConfig.websiteDataStore = .default()

        let mbsWebView = WKWebView(frame: .zero, configuration: mbsConfig)
        mbsWebView.customUserAgent =
            "Mozilla/5.0 (iPhone; CPU iPhone OS 18_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1"
        mbsWebView.navigationDelegate = context.coordinator
        mbsWebView.uiDelegate = context.coordinator
        mbsWebView.allowsBackForwardNavigationGestures = true
        mbsWebView.scrollView.keyboardDismissMode = .interactive
        mbsWebView.allowsLinkPreview = false

        let mbsRefresh = UIRefreshControl()
        mbsRefresh.addTarget(context.coordinator, action: #selector(MyBookShelfWebCoordinator.mbsHandleRefresh(_:)), for: .valueChanged)
        mbsWebView.scrollView.refreshControl = mbsRefresh
        mbsWebView.scrollView.bounces = true

        context.coordinator.mbsWebView = mbsWebView

        MyBookShelfWebCoordinator.mbsLoadCookies(into: mbsWebView) {
            if let mbsURL = URL(string: pageAddress) {
                mbsWebView.load(URLRequest(url: mbsURL))
            }
        }

        return mbsWebView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

final class MyBookShelfWebCoordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
    weak var mbsWebView: WKWebView?

    private let mbsCookiesDefaultsKey = "mbs_saved_cookies_v1"

    @objc func mbsHandleRefresh(_ sender: UIRefreshControl) {
        mbsWebView?.reload()
    }

    static func mbsLoadCookies(into webView: WKWebView, completion: @escaping () -> Void) {
        guard let cookiesData = UserDefaults.standard.data(forKey: "mbs_saved_cookies_v1"),
              let cookiesArray = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(cookiesData) as? [[String: Any]] else {
            completion()
            return
        }

        let mbsGroup = DispatchGroup()
        for cookieDict in cookiesArray {
            var convertedDict: [HTTPCookiePropertyKey: Any] = [:]
            for (key, value) in cookieDict {
                convertedDict[HTTPCookiePropertyKey(key)] = value
            }
            if let cookie = HTTPCookie(properties: convertedDict) {
                mbsGroup.enter()
                webView.configuration.websiteDataStore.httpCookieStore.setCookie(cookie) {
                    mbsGroup.leave()
                }
            }
        }
        mbsGroup.notify(queue: .main, execute: completion)
    }

    private func mbsSaveCookies(from webView: WKWebView) {
        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
            var mbsSerialized: [[String: Any]] = []
            for cookie in cookies {
                guard let props = cookie.properties else { continue }
                var dict: [String: Any] = [:]
                for (key, value) in props {
                    dict[key.rawValue] = value
                }
                mbsSerialized.append(dict)
            }
            guard !mbsSerialized.isEmpty else { return }
            do {
                let data = try NSKeyedArchiver.archivedData(withRootObject: mbsSerialized, requiringSecureCoding: false)
                UserDefaults.standard.set(data, forKey: self.mbsCookiesDefaultsKey)
            } catch {}
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.scrollView.refreshControl?.endRefreshing()
        mbsSaveCookies(from: webView)
        if let mbsFinalPath = webView.url?.absoluteString {
            MyBookShelfFlowController.shared.mbsCacheResource(mbsFinalPath)
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        webView.scrollView.refreshControl?.endRefreshing()
        MyBookShelfFlowController.shared.mbsFinishWithOriginalExperience(permanentLock: true)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        webView.scrollView.refreshControl?.endRefreshing()
        MyBookShelfFlowController.shared.mbsFinishWithOriginalExperience(permanentLock: true)
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        if let mbsURL = navigationAction.request.url {
            let mbsScheme = mbsURL.scheme?.lowercased() ?? ""
            if mbsScheme != "http" && mbsScheme != "https" {
                UIApplication.shared.open(mbsURL)
                decisionHandler(.cancel)
                return
            }
        }
        decisionHandler(.allow)
    }

    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        if navigationAction.targetFrame == nil, let mbsURL = navigationAction.request.url {
            webView.load(URLRequest(url: mbsURL))
        }
        return nil
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptAlertPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping () -> Void
    ) {
        let mbsAlert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        mbsAlert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler() })
        mbsPresentAlert(mbsAlert)
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptConfirmPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping (Bool) -> Void
    ) {
        let mbsAlert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        mbsAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completionHandler(false) })
        mbsAlert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler(true) })
        mbsPresentAlert(mbsAlert)
    }

    private func mbsPresentAlert(_ controller: UIAlertController) {
        guard let mbsScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = mbsScene.windows.first(where: { $0.isKeyWindow })?.rootViewController
                ?? mbsScene.windows.first?.rootViewController else {
            return
        }
        var top = root
        while let presented = top.presentedViewController {
            top = presented
        }
        top.present(controller, animated: true)
    }
}

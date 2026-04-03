//
//  PrivacyPolicyView.swift
//  MyBookShelf
//

import SwiftUI
import WebKit

struct PrivacyPolicyView: View {
    @State private var isLoading = true
    @State private var loadFailed = false

    private let policyURL: URL? = {
        if let stored = UserDefaults.standard.string(forKey: "privacyPolicyURL"),
           let url = URL(string: stored) { return url }
        return URL(string: "https://sites.google.com/view/mybookshelfonline")
    }()

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            if let url = policyURL, !loadFailed {
                MBSWebView(url: url, isLoading: $isLoading, didFail: $loadFailed)
                    .ignoresSafeArea(edges: .bottom)

                if isLoading {
                    ProgressView()
                        .tint(AppTheme.accentLamp)
                }
            } else {
                offlineFallback
            }
        }
        .navigationTitle("Privacy policy")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppTheme.background.opacity(0.95), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .mbsHidesTabBar()
        .toolbar(.hidden, for: .tabBar)
    }

    private var offlineFallback: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Your reading life stays on your device. MyBookShelf is built for local use: we don't run analytics, ads, or background tracking.")
                    .font(.body)
                    .foregroundStyle(AppTheme.textPrimary)

                policyBlock(
                    title: "What we don't collect",
                    body: "We don't ask for an account. We don't upload your library, notes, streaks, or profile to our servers—there's no central database of your books. Nothing is sold to third parties."
                )

                policyBlock(
                    title: "Camera & photos",
                    body: "The camera and photo library are used only when you choose to add a book cover or a profile picture. Those images are saved locally on your iPhone, like the rest of your data."
                )

                policyBlock(
                    title: "Your control",
                    body: "You can remove a custom photo anytime in Edit profile, change book covers in the book editor, or erase everything with \"Reset all progress\" in Settings (this deletes local app data)."
                )

                Text("If you have questions, use the support channel listed on the App Store page for this app.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textMuted)
            }
            .padding(20)
            .padding(.bottom, 24)
        }
        .background(AppTheme.background)
    }

    private func policyBlock(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)
            Text(body)
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - WKWebView wrapper

struct MBSWebView: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool
    @Binding var didFail: Bool

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let wv = WKWebView(frame: .zero, configuration: config)
        wv.navigationDelegate = context.coordinator
        wv.isOpaque = false
        wv.backgroundColor = .clear
        wv.scrollView.backgroundColor = .clear
        wv.load(URLRequest(url: url))
        return wv
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    final class Coordinator: NSObject, WKNavigationDelegate {
        let parent: MBSWebView
        init(_ parent: MBSWebView) { self.parent = parent }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
        }
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
            parent.didFail = true
        }
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
            parent.didFail = true
        }
    }
}

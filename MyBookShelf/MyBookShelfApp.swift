//
//  MyBookShelfApp.swift
//  MyBookShelf
//

import CoreData
import SwiftUI

@main
struct MyBookShelfApp: App {
    let persistence = PersistenceController.shared
    @AppStorage(OnboardingUserDefaults.completedKey) private var hasCompletedOnboardingFlag = false
    @State private var showSplash = true

    init() {
        let nav = UINavigationBarAppearance()
        nav.configureWithTransparentBackground()
        nav.backgroundColor = .clear
        nav.shadowColor = .clear
        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
        UINavigationBar.appearance().compactAppearance = nav
        UINavigationBar.appearance().compactScrollEdgeAppearance = nav
        UINavigationBar.appearance().isTranslucent = true
        UIScrollView.appearance().backgroundColor = .clear
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                Group {
                    if !hasCompletedOnboardingFlag {
                        OnboardingView(isComplete: Binding(
                            get: { hasCompletedOnboardingFlag },
                            set: { hasCompletedOnboardingFlag = $0 }
                        ))
                    } else {
                        MainTabView()
                            .environment(\.managedObjectContext, persistence.container.viewContext)
                            .onAppear {
                                Task { @MainActor in
                                    persistence.ensureUserProfile()
                                }
                            }
                    }
                }
                .opacity(showSplash ? 0 : 1)

                if showSplash {
                    MBSSplashView {
                        withAnimation(.easeOut(duration: 0.3)) {
                            showSplash = false
                        }
                    }
                }
            }
            .preferredColorScheme(.dark)
            .animation(.easeInOut(duration: 0.35), value: hasCompletedOnboardingFlag)
        }
    }
}

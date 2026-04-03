//
//  FloatingTabBarChrome.swift
//  MyBookShelf
//

import Combine
import SwiftUI

/// Legacy visibility object. No longer actively managed — kept only so
/// existing `@EnvironmentObject` references compile. The real tab bar
/// visibility is driven by `MBSTabState.tabBarHidden`.
final class FloatingTabBarChrome: ObservableObject {
    @Published private var depth = 0
    var isHidden: Bool { depth > 0 }

    func push() { depth += 1 }
    func pop() { depth = max(0, depth - 1) }
}

/// The modifier now delegates to `MBSTabState` while keeping the old call-site name.
private struct SuppressFloatingTabBarModifier: ViewModifier {
    @EnvironmentObject private var tabState: MBSTabState

    func body(content: Content) -> some View {
        content
            .onAppear { tabState.pushOverlay() }
            .onDisappear { tabState.popOverlay() }
    }
}

extension View {
    func suppressesFloatingTabBar() -> some View {
        modifier(SuppressFloatingTabBarModifier())
    }
}

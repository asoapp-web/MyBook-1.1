import Combine
import SwiftUI

final class FloatingTabBarChrome: ObservableObject {
    @Published private var depth = 0
    var isHidden: Bool { depth > 0 }

    func push() { depth += 1 }
    func pop() { depth = max(0, depth - 1) }
}

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

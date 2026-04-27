import SwiftUI

struct MBSToastOverlay: View {
    @EnvironmentObject private var tabState: MBSTabState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack {
            if let msg = tabState.toastMessage {
                HStack(spacing: 8) {
                    Image(systemName: tabState.toastIcon)
                        .font(.system(size: 16))
                        .foregroundColor(AppTheme.accentLamp)
                    Text(msg)
                        .font(.mbsBody(14, weight: .medium))
                        .foregroundStyle(AppTheme.textPrimary)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 11)
                .background(
                    Capsule()
                        .fill(AppTheme.backgroundElevated.opacity(0.96))
                        .overlay(Capsule().stroke(AppTheme.outlineLamp, lineWidth: 1))
                )
                .shadow(color: AppTheme.shadow, radius: 8, y: 4)
                .transition(.move(edge: .top).combined(with: .opacity))
                .padding(.top, 54)
                .zIndex(200)
            }
            Spacer()
        }
        .animation(
            reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.3, dampingFraction: 0.7),
            value: tabState.toastMessage
        )
        .onChange(of: tabState.toastMessage) { new in
            guard new != nil else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                tabState.toastMessage = nil
            }
        }
        .allowsHitTesting(false)
    }
}

struct ToastModifier: ViewModifier {
    @Binding var message: String?
    let duration: Double

    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content
            if let msg = message {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(AppTheme.accentLamp)
                    Text(msg)
                        .font(.mbsBody(14, weight: .medium))
                        .foregroundStyle(AppTheme.textPrimary)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 11)
                .background(
                    Capsule()
                        .fill(AppTheme.backgroundElevated.opacity(0.96))
                        .overlay(Capsule().stroke(AppTheme.outlineLamp, lineWidth: 1))
                )
                .shadow(color: AppTheme.shadow, radius: 8, y: 4)
                .padding(.top, 50)
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(100)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: message)
        .onChange(of: message) { new in
            guard new != nil else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                message = nil
            }
        }
    }
}

extension View {
    func toast(_ message: Binding<String?>, duration: Double = 2) -> some View {
        modifier(ToastModifier(message: message, duration: duration))
    }
}

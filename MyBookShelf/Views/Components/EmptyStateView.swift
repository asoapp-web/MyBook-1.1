import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var onAction: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 56))
                .foregroundStyle(AppTheme.textMuted)
            Text(title)
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            if let actionTitle, let onAction {
                Button(action: onAction) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 13, weight: .semibold))
                        Text(actionTitle)
                            .font(.mbsBody(14, weight: .semibold))
                    }
                    .foregroundStyle(AppTheme.backgroundSecondary)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 11)
                    .background(LinearGradient.mbsLampAccent)
                    .clipShape(Capsule())
                    .shadow(color: AppTheme.accentLamp.opacity(0.35), radius: 8)
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 48)
    }
}

import SwiftUI

struct ProgressBarView: View {
    let progress: Double
    var height: CGFloat = 8

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(AppTheme.backgroundTertiary)
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.accentLampLight, AppTheme.accentLamp, AppTheme.accentLampDark],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * CGFloat(min(1, max(0, progress / 100))))
                    .shadow(color: AppTheme.accentLamp.opacity(0.40), radius: 4)
                    .animation(.spring(response: 0.72, dampingFraction: 0.82), value: progress)
            }
        }
        .frame(height: height)
    }
}

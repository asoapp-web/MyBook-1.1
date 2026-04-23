import SwiftUI

struct ExpandableModuleView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "books.vertical")
                .font(.system(size: 60))
                .foregroundStyle(AppTheme.accentLamp.opacity(0.5))
            Text("More features")
                .font(.mbsDisplay(22))
                .foregroundStyle(AppTheme.textPrimary)
            Text("Additional reading tools and content modules will be available here.")
                .font(.mbsBody(14))
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.background)
        .navigationTitle("More")
        .navigationBarTitleDisplayMode(.inline)
        .suppressesFloatingTabBar()
        .toolbar(.hidden, for: .tabBar)
    }
}

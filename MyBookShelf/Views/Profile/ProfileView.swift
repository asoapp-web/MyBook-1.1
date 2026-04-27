import CoreData
import SwiftUI

struct ProfileView: View {
    @StateObject private var vm = ProfileViewModel()
    @EnvironmentObject private var tabState: MBSTabState
    @State private var exportURL: URL?
    @State private var showExportPopup = false
    @State private var showShareSheet = false
    @State private var appeared = false
    @State private var displayedXP: Double = 0
    var tabBarHeight: CGFloat = 80

    var body: some View {
        NavigationStack {
            ZStack {

                MBSAtmosphereBackground()

                ScrollView {
                    VStack(spacing: 18) {
                        let p = vm.profile
                        profileHeader(p)
                            .profileEntryAnim(appeared: appeared, delay: 0.04)
                        if let p = p {
                            streakSection(p)
                                .profileEntryAnim(appeared: appeared, delay: 0.11)
                        }
                        ProfileFavoritesEntryRow()
                            .profileEntryAnim(appeared: appeared, delay: 0.18)
                        exportButton
                            .profileEntryAnim(appeared: appeared, delay: 0.24)
                        settingsLink
                            .profileEntryAnim(appeared: appeared, delay: 0.30)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, tabBarHeight + 16)
                }
                .background(Color.clear)

                if showExportPopup, let url = exportURL {
                    MBSPopupOverlay(isPresented: $showExportPopup, title: "Export ready") {
                        VStack(spacing: 16) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 40))
                                .foregroundStyle(AppTheme.accentLamp)

                            Text("Your library has been exported and is ready to share.")
                                .font(.mbsBody(14))
                                .foregroundStyle(AppTheme.textSecondary)
                                .multilineTextAlignment(.center)

                            Button {
                                showExportPopup = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    showShareSheet = true
                                }
                            } label: {
                                Text("Share")
                                    .font(.mbsBody(16, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(LinearGradient.mbsLampAccent)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(20)
                    }
                    .zIndex(50)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(AppTheme.background.opacity(0.88), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                vm.fetch()
                withAnimation(.spring(response: 0.55, dampingFraction: 0.78)) {
                    appeared = true
                }
                withAnimation(.spring(response: 0.85, dampingFraction: 0.80).delay(0.40)) {
                    displayedXP = vm.progressToNext * 100
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = exportURL {
                    ShareSheet(items: [url])
                }
            }
        }
    }

    private var exportButton: some View {
        Button {
            performExport()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(AppTheme.accentLamp)
                Text("Export library")
                    .font(.mbsBody(15, weight: .medium))
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.textMuted)
            }
            .padding(18)
            .mbsCard()
        }
        .buttonStyle(.plain)
    }

    private var settingsLink: some View {
        NavigationLink {
            SettingsView()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(AppTheme.accentLamp)
                Text("Settings")
                    .font(.mbsBody(15, weight: .medium))
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.textMuted)
            }
            .padding(18)
            .mbsCard()
        }
        .foregroundStyle(AppTheme.textPrimary)
    }

    private func performExport() {
        let ctx = PersistenceController.shared.container.viewContext
        do {
            let data = try MBSExportService.buildJSON(context: ctx)
            let url = try MBSExportService.writeToTemp(data: data, filename: "MyBookShelf_Library.json")
            exportURL = url
            showExportPopup = true
        } catch {
            tabState.showToast("Export failed", icon: "xmark.circle.fill")
        }
    }

    private func xpProgressCaption(for p: UserProfile) -> String {
        let lvl = Int(p.currentLevel)
        let low = GamificationEngine.shared.xpForLevel(lvl)
        let high = GamificationEngine.shared.xpForLevel(lvl + 1)
        let inLevel = max(0, Int(p.totalXP) - low)
        let span = max(1, high - low)
        return "\(inLevel) / \(span) XP to level \(lvl + 1) · \(Int(p.totalXP)) total"
    }

    private func profileHeader(_ p: UserProfile?) -> some View {
        VStack(spacing: 20) {

            ZStack {

                Circle()
                    .fill(AppTheme.accentLamp.opacity(0.12))
                    .frame(width: 120, height: 120)
                    .blur(radius: 12)

                Group {
                    if let img = vm.profileAvatarUIImage {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                    } else {
                        let idx = min(Int(p?.avatarIndex ?? 0), ProfileAvatarSymbolSet.names.count - 1)
                        Image(systemName: ProfileAvatarSymbolSet.names[idx])
                            .font(.system(size: 52))
                            .foregroundStyle(AppTheme.accentLamp)
                    }
                }
                .frame(width: 96, height: 96)
                .background(AppTheme.backgroundTertiary)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [AppTheme.accentLampLight, AppTheme.accentLampDark],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
            }

            VStack(spacing: 6) {
                Text(p?.displayName ?? "Reader")
                    .font(.mbsDisplay(24))
                    .foregroundStyle(AppTheme.textPrimary)

                if let p {
                    Text("Level \(p.currentLevel)")
                        .font(.mbsBody(14))
                        .foregroundStyle(AppTheme.accentLamp)
                }
            }

            if let p {
                VStack(spacing: 6) {
                    ProgressBarView(progress: displayedXP)
                        .frame(height: 6)
                    Text(xpProgressCaption(for: p))
                        .font(.mbsCaption(11))
                        .foregroundStyle(AppTheme.textMuted)
                        .multilineTextAlignment(.center)
                }
            }

            NavigationLink {
                EditProfileView(vm: vm)
            } label: {
                Text("Edit profile")
                    .font(.mbsBody(15, weight: .semibold))
                    .foregroundStyle(AppTheme.accentLamp)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(AppTheme.accentLamp.opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(AppTheme.accentLamp.opacity(0.30), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .mbsCard()
    }

    private func streakSection(_ p: UserProfile) -> some View {
        HStack(spacing: 16) {

            TimelineView(.animation(minimumInterval: 1.0 / 20.0)) { ctx in
                let t = ctx.date.timeIntervalSinceReferenceDate
                let breathe = 0.86 + 0.14 * CGFloat(abs(sin(t * 1.6)))
                ZStack {
                    Circle()
                        .fill(AppTheme.accentLamp.opacity(0.14 * breathe))
                        .frame(width: 54, height: 54)
                        .blur(radius: 4)
                    Circle()
                        .fill(AppTheme.accentLamp.opacity(0.10))
                        .frame(width: 50, height: 50)
                    Image(systemName: "flame.fill")
                        .font(.system(size: 26, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppTheme.accentLampLight, AppTheme.accentLamp],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .scaleEffect(breathe)
                        .shadow(color: AppTheme.accentLamp.opacity(0.55 * breathe), radius: 10)
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("\(p.currentStreak) days in a row")
                    .font(.mbsBody(16, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                Text("Best: \(p.longestStreak) days")
                    .font(.mbsBody(13))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(p.totalBooksFinished)")
                    .font(.mbsDisplay(24))
                    .foregroundStyle(AppTheme.textPrimary)
                Text("finished")
                    .font(.mbsCaption(11))
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .padding(18)
        .mbsCard()
    }
}

private extension View {
    func profileEntryAnim(appeared: Bool, delay: Double) -> some View {
        self
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
            .animation(
                .spring(response: 0.52, dampingFraction: 0.80).delay(delay),
                value: appeared
            )
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

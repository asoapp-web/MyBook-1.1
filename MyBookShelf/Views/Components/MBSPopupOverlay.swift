//
//  MBSPopupOverlay.swift
//  MyBookShelf
//

import SwiftUI

/// Full-screen dimmed overlay with a centered card. Same UX class as Station, unique code and styling.
struct MBSPopupOverlay<Content: View>: View {
    @Binding var isPresented: Bool
    var title: String?
    var maxWidth: CGFloat = 380
    var dismissOnBackdropTap: Bool = true
    @ViewBuilder var content: () -> Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    guard dismissOnBackdropTap else { return }
                    dismiss()
                }

            VStack(spacing: 0) {
                if let title {
                    HStack(alignment: .center) {
                        Text(title)
                            .font(.mbsDialogTitle)
                            .foregroundColor(AppTheme.textPrimary)
                            .multilineTextAlignment(.leading)
                        Spacer(minLength: 8)
                        Button { dismiss() } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(AppTheme.textMuted)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Close")
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 12)

                    Rectangle()
                        .fill(AppTheme.divider)
                        .frame(height: 1)
                }

                content()
            }
            .frame(maxWidth: maxWidth)
            .background(AppTheme.backgroundElevated)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(AppTheme.outlineLamp, lineWidth: 1)
            )
            .shadow(color: AppTheme.shadow, radius: 24, y: 10)
            .padding(.horizontal, 20)
            .scaleEffect(appeared ? 1.0 : (reduceMotion ? 1.0 : 0.92))
            .opacity(appeared ? 1.0 : 0.0)
        }
        .onAppear {
            appeared = false
            withAnimation(reduceMotion ? .easeOut(duration: 0.2) : .spring(response: 0.32, dampingFraction: 0.82)) {
                appeared = true
            }
        }
    }

    private func dismiss() {
        withAnimation(reduceMotion ? .easeOut(duration: 0.15) : .spring(response: 0.28, dampingFraction: 0.88)) {
            isPresented = false
        }
    }
}

/// Confirmation dialog that replaces system alerts.
struct MBSConfirmationDialog: View {
    let title: String
    var message: String?
    let primaryAction: DialogAction
    var cancelAction: (() -> Void)?
    var showsCancelButton: Bool = true

    struct DialogAction {
        let title: String
        var isDestructive: Bool = false
        let action: () -> Void
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Text(title)
                    .font(.mbsDialogTitle)
                    .foregroundColor(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)

                if let message {
                    Text(message)
                        .font(.mbsBody(14))
                        .foregroundColor(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 10) {
                    Button {
                        primaryAction.action()
                    } label: {
                        Text(primaryAction.title)
                            .font(.mbsBody(16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                primaryAction.isDestructive
                                    ? AnyShapeStyle(Color.red)
                                    : AnyShapeStyle(LinearGradient.mbsLampAccent)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)

                    if showsCancelButton {
                        Button {
                            cancelAction?()
                        } label: {
                            Text("Cancel")
                                .font(.mbsBody(16, weight: .medium))
                                .foregroundStyle(AppTheme.textSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: 340)
            .background(AppTheme.backgroundElevated)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(AppTheme.outlineLamp, lineWidth: 1)
            )
            .shadow(color: AppTheme.shadow, radius: 24, y: 10)
            .scaleEffect(appeared ? 1.0 : (reduceMotion ? 1.0 : 0.92))
            .opacity(appeared ? 1.0 : 0.0)
        }
        .onAppear {
            appeared = false
            withAnimation(reduceMotion ? .easeOut(duration: 0.2) : .spring(response: 0.32, dampingFraction: 0.82)) {
                appeared = true
            }
        }
    }
}

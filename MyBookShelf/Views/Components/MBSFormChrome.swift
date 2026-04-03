//
//  MBSFormChrome.swift
//  MyBookShelf
//

import SwiftUI

struct MBSTextFieldChrome: View {
    let placeholder: String
    @Binding var text: String
    var submitLabel: SubmitLabel = .search
    var onSubmit: (() -> Void)?

    var body: some View {
        TextField(placeholder, text: $text)
            .submitLabel(submitLabel)
            .onSubmit { onSubmit?() }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(AppTheme.backgroundTertiary)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(AppTheme.divider, lineWidth: 1)
            )
            .foregroundStyle(AppTheme.textPrimary)
    }
}

struct MBSSegmentPickerChrome: View {
    let options: [(String, Int)]
    @Binding var selection: Int

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.1) { title, tag in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selection = tag
                    }
                    HapticsService.shared.selection()
                } label: {
                    Text(title)
                        .font(.system(size: 13, weight: selection == tag ? .semibold : .medium))
                        .foregroundStyle(selection == tag ? AppTheme.textPrimary : AppTheme.textMuted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(
                            Group {
                                if selection == tag {
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(AppTheme.accentLamp.opacity(0.22))
                                }
                            }
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(AppTheme.backgroundTertiary)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(AppTheme.divider, lineWidth: 1)
        )
    }
}

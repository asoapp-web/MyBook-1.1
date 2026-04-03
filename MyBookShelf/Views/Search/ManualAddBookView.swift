//
//  ManualAddBookView.swift
//

import SwiftUI
import UIKit

private let genres = ["Fiction", "Non-fiction", "Science Fiction", "Fantasy", "Mystery", "Thriller", "Romance", "Poetry", "Biography", "History", "Science", "Psychology", "Business", "Self-help", "Children's", "Comics", "Horror", "Adventure", "Philosophy", "Other"]

/// Manual add form field: gray hint turns red + border when `error != nil`.
private struct ManualValidatedField<Content: View>: View {
    let label: String
    let error: String?
    let hint: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
            content()
                .textFieldStyle(.plain)
                .padding(12)
                .background(AppTheme.backgroundTertiary)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay {
                    if error != nil {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.red.opacity(0.92), lineWidth: 1.5)
                    }
                }
                .foregroundStyle(AppTheme.textPrimary)
            Text(error ?? hint)
                .font(.caption2)
                .foregroundStyle(error != nil ? Color.red : AppTheme.textMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct ManualAddBookView: View {
    @StateObject private var vm = AddBookViewModel()
    var onBookAdded: (() -> Void)?
    var tabBarClearance: CGFloat = 36
    @State private var showImageOptions = false
    @State private var showImagePicker = false
    @State private var useCamera = false
    @State private var toastMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Button {
                    showImageOptions = true
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppTheme.backgroundTertiary)
                            .aspectRatio(2 / 3, contentMode: .fit)
                        if let img = vm.coverImage {
                            Image(uiImage: img)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        } else {
                            VStack(spacing: 8) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 36))
                                Text("Add cover")
                                    .font(.subheadline)
                            }
                            .foregroundStyle(AppTheme.textMuted)
                        }
                    }
                }
                .buttonStyle(.plain)

                ManualValidatedField(
                    label: "Title *",
                    error: vm.titleFieldError,
                    hint: "Required · max \(ManualAddBookFieldLimits.titleMax) characters"
                ) {
                    TextField("Enter book title", text: vm.bindingTitle())
                }

                ManualValidatedField(
                    label: "Author *",
                    error: vm.authorFieldError,
                    hint: "Required · max \(ManualAddBookFieldLimits.authorMax) characters"
                ) {
                    TextField("Enter author name", text: vm.bindingAuthor())
                }

                ManualValidatedField(
                    label: "Pages *",
                    error: vm.pagesFieldError,
                    hint: "\(ManualAddBookFieldLimits.pagesMin)–\(ManualAddBookFieldLimits.pagesMax) pages"
                ) {
                    TextField("0", value: vm.bindingTotalPages(), format: .number)
                        .keyboardType(.numberPad)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Genre")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                    Picker("Genre", selection: $vm.genre) {
                        ForEach(genres, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.menu)
                    if vm.genre == "Other" {
                        ManualValidatedField(
                            label: "Custom genre *",
                            error: vm.customGenreFieldError,
                            hint: "Required · max \(ManualAddBookFieldLimits.customGenreMax) characters"
                        ) {
                            TextField("Genre name", text: vm.bindingCustomGenre())
                        }
                        .padding(.top, 4)
                    }
                }

                ManualValidatedField(
                    label: "Year",
                    error: vm.yearFieldError,
                    hint: "Optional · \(ManualAddBookFieldLimits.yearMin)–\(ManualAddBookFieldLimits.yearMax) · 4 digits"
                ) {
                    TextField("Optional", text: vm.bindingPublishYear())
                        .keyboardType(.numberPad)
                }

                ManualValidatedField(
                    label: "ISBN",
                    error: vm.isbnFieldError,
                    hint: "Optional · digits, -, spaces, X · ≥10 digit/X if filled · max \(ManualAddBookFieldLimits.isbnMax)"
                ) {
                    TextField("Optional", text: vm.bindingIsbn())
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Status")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                    Picker("Status", selection: $vm.status) {
                        ForEach(ReadingStatus.allCases, id: \.rawValue) { s in
                            Text(s.label).tag(s)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Button {
                    if vm.canSave {
                        vm.save()
                        vm.showValidationErrors = false
                        HapticsService.shared.success()
                        toastMessage = "Book added!"
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            onBookAdded?()
                        }
                    } else {
                        vm.noteInvalidSaveAttempt()
                        HapticsService.shared.error()
                    }
                } label: {
                    Text("Add book")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(vm.canSave ? AppTheme.accentOrange : AppTheme.textMuted)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
            .padding(20)
            .padding(.bottom, tabBarClearance)
        }
        .background(AppTheme.background)
        .onChange(of: vm.canSave) { newValue in
            if newValue {
                vm.clearValidationHighlightIfFormValid()
            }
        }
        .confirmationDialog("Cover", isPresented: $showImageOptions) {
            Button("Camera") {
                useCamera = true
                showImagePicker = true
            }
            Button("Photo library") {
                useCamera = false
                showImagePicker = true
            }
            if vm.coverImage != nil {
                Button("Remove", role: .destructive) {
                    vm.coverImage = nil
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Choose source")
        }
        .sheet(isPresented: $showImagePicker) {
            if useCamera {
                ImagePicker(sourceType: .camera, onPick: {
                    vm.coverImage = $0.mb_croppedToBookCoverAspect()
                    showImagePicker = false
                }, onCancel: { showImagePicker = false })
            } else {
                PHPickerView(onPick: {
                    vm.coverImage = $0.mb_croppedToBookCoverAspect()
                    showImagePicker = false
                }, onCancel: { showImagePicker = false })
            }
        }
        .toast($toastMessage)
    }
}

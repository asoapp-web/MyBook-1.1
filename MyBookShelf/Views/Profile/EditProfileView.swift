//
//  EditProfileView.swift
//  MyBookShelf
//

import PhotosUI
import SwiftUI
import UIKit

struct EditProfileView: View {
    @ObservedObject var vm: ProfileViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var nameDraft = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var pickedImage: UIImage?
    @State private var showCameraPicker = false
    @FocusState private var nameFocused: Bool

    private var cameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    var body: some View {
        Form {
                Section {
                    VStack(spacing: 16) {
                        avatarPreview
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(AppTheme.accentOrange.opacity(0.45), lineWidth: 2))
                    }
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                }
                Section("Display name") {
                    TextField("Your name", text: $nameDraft)
                        .focused($nameFocused)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                }
                Section("Photo") {
                    if cameraAvailable {
                        Button {
                            showCameraPicker = true
                        } label: {
                            Label("Take photo", systemImage: "camera.fill")
                        }
                    }
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        Label("Choose from library", systemImage: "photo.on.rectangle.angled")
                    }
                    if vm.profile?.localAvatarPath != nil {
                        Button(role: .destructive) {
                            vm.removeCustomAvatar()
                            pickedImage = nil
                            selectedPhotoItem = nil
                        } label: {
                            Label("Remove photo", systemImage: "trash")
                        }
                    }
                }
                Section {
                    Text("Or pick an icon (used when there is no photo)")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textMuted)
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 52))], spacing: 12) {
                        ForEach(Array(ProfileAvatarSymbolSet.names.enumerated()), id: \.offset) { index, name in
                            let selected = vm.profile?.localAvatarPath == nil && Int(vm.profile?.avatarIndex ?? 0) == index
                            Button {
                                vm.selectSymbolAvatar(index: index)
                                pickedImage = nil
                                selectedPhotoItem = nil
                            } label: {
                                Image(systemName: name)
                                    .font(.system(size: 26))
                                    .foregroundStyle(selected ? AppTheme.accentOrange : AppTheme.textSecondary)
                                    .frame(width: 48, height: 48)
                                    .background(selected ? AppTheme.accentOrange.opacity(0.15) : AppTheme.backgroundTertiary)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                }
        }
        .scrollContentBackground(.hidden)
        .background(AppTheme.background)
        .navigationTitle("Edit profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    vm.saveDisplayName(nameDraft)
                    dismiss()
                }
                .fontWeight(.semibold)
            }
        }
        .suppressesFloatingTabBar()
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            nameDraft = vm.profile?.displayName ?? "Reader"
        }
        .onChange(of: selectedPhotoItem) { item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let ui = UIImage(data: data) {
                    await MainActor.run {
                        vm.setCustomAvatar(ui)
                        pickedImage = ui
                    }
                }
            }
        }
        .sheet(isPresented: $showCameraPicker) {
            ImagePicker(sourceType: .camera, onPick: { img in
                vm.setCustomAvatar(img)
                pickedImage = img
                selectedPhotoItem = nil
                showCameraPicker = false
            }, onCancel: {
                showCameraPicker = false
            })
        }
    }

    @ViewBuilder
    private var avatarPreview: some View {
        if let picked = pickedImage {
            Image(uiImage: picked)
                .resizable()
                .scaledToFill()
        } else if let img = vm.profileAvatarUIImage {
            Image(uiImage: img)
                .resizable()
                .scaledToFill()
        } else if let p = vm.profile {
            let idx = min(Int(p.avatarIndex), ProfileAvatarSymbolSet.names.count - 1)
            Image(systemName: ProfileAvatarSymbolSet.names[idx])
                .font(.system(size: 56))
                .foregroundStyle(AppTheme.accentOrange)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppTheme.backgroundTertiary)
        } else {
            ProgressView()
        }
    }
}

//
//  UserProfileView.swift
//  WalkyTrails
//

import PhotosUI
import SwiftUI
import UIKit

struct UserProfileView: View {
    @EnvironmentObject var userStore: UserProfileStore
    var isOnboarding: Bool = false
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var selectedItem: PhotosUI.PhotosPickerItem?

    private let photoSize: CGFloat = 100
    private let jpegQuality: CGFloat = 0.7

    var body: some View {
        Form {
            Section {
                HStack {
                    Spacer()
                    photoView
                    Spacer()
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 4, trailing: 16))

                PhotosPicker(
                    selection: $selectedItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    Label("Change Photo", systemImage: "photo.on.rectangle.angled")
                }
                .onChange(of: selectedItem) { _, newItem in
                    Task { await loadAndSavePhoto(from: newItem) }
                }
                .accessibilityLabel("Change your photo")
                if userStore.user.photoData != nil {
                    Button(role: .destructive) {
                        userStore.updatePhoto(nil)
                    } label: {
                        Label("Remove Photo", systemImage: "trash")
                    }
                }
            } header: {
                Text("Photo")
            }

            Section {
                TextField("Your name", text: $name, prompt: Text("Name"))
                    .accessibilityLabel("Your name")
            } header: {
                Text("Profile")
            }
        }
        .navigationTitle(isOnboarding ? "Set Up Your Profile" : "Your Profile")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(isOnboarding)
        .toolbar {
            if !isOnboarding {
                ToolbarItem(placement: .primaryAction) {
                    Button("Save") {
                        userStore.save(UserProfile(name: name.trimmingCharacters(in: .whitespacesAndNewlines), photoData: userStore.user.photoData))
                        dismiss()
                    }
                    .accessibilityLabel("Save profile")
                }
            }
        }
        .onAppear {
            name = userStore.user.name
        }
        .onChange(of: name) { _, new in
            userStore.save(UserProfile(name: new, photoData: userStore.user.photoData))
        }
    }

    @ViewBuilder
    private var photoView: some View {
        if let data = userStore.user.photoData, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: photoSize, height: photoSize)
                .clipShape(Circle())
        } else {
            Image(systemName: "person.circle.fill")
                .font(.system(size: photoSize))
                .foregroundStyle(.secondary)
        }
    }

    private func loadAndSavePhoto(from item: PhotosPickerItem?) async {
        guard let item else { return }
        guard let data = try? await item.loadTransferable(type: Data.self) else { return }
        guard let uiImage = UIImage(data: data) else { return }
        let jpeg = uiImage.jpegData(compressionQuality: jpegQuality)
        await MainActor.run {
            userStore.updatePhoto(jpeg)
        }
    }
}

#Preview {
    NavigationStack {
        UserProfileView()
            .environmentObject(UserProfileStore())
    }
}

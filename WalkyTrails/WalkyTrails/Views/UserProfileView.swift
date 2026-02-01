//
//  UserProfileView.swift
//  WalkyTrails
//

import PhotosUI
import SwiftUI
import UIKit

struct UserProfileView: View {
    @ObservedObject var userStore: UserProfileStore
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
                    Spacer()
                }
                .listRowBackground(Color.clear)
                PhotosPicker(selection: $selectedItem, matching: .images, photoLibrary: .shared()) {
                    Text("Choose photo")
                }
                .onChange(of: selectedItem) { _, new in
                    Task {
                        if let data = try? await new?.loadTransferable(type: Data.self) {
                            let compressed = UIImage(data: data).flatMap { $0.jpegData(compressionQuality: jpegQuality) } ?? data
                            await MainActor.run { userStore.updatePhoto(compressed) }
                        }
                    }
                }
                TextField("Your name", text: $name)
                    .textContentType(.name)
                    .autocapitalization(.words)
            } header: {
                Text("Profile")
            }
            Section {
                Button("Save") {
                    userStore.update(UserProfile(name: name.trimmingCharacters(in: .whitespacesAndNewlines), photoData: userStore.user.photoData))
                    if isOnboarding { dismiss() }
                }
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && userStore.user.photoData == nil)
            }
        }
        .navigationTitle(isOnboarding ? "Welcome" : "Your profile")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            name = userStore.user.name
        }
    }
}

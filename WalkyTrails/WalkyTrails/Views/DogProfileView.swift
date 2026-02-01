//
//  DogProfileView.swift
//  WalkyTrails
//

import PhotosUI
import SwiftUI
import UIKit

private let commonBreeds = [
    "", // "Select breed" / none
    "Vizsla",
    "Weimaraner",
    "German Shorthaired",
    "German Wirehaired",
    "German Shepherd",
    "Labrador Retriever",
    "Golden Retriever",
    "German Shepherd",
    "French Bulldog",
    "Bulldog",
    "Poodle",
    "Beagle",
    "Rottweiler",
    "Yorkshire Terrier",
    "Boxer",
    "Dachshund",
    "Shih Tzu",
    "Australian Shepherd",
    "Pembroke Welsh Corgi",
    "Chihuahua",
    "Cavalier King Charles Spaniel",
    "Husky",
    "Mixed",
    "Other"
]

struct DogProfileView: View {
    @ObservedObject var dogStore: DogProfileStore
    /// When true, shown as first-run onboarding (no back button); after save, app shows Home.
    var isOnboarding: Bool = false
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var selectedBreed: String = ""
    @State private var customBreed: String = ""
    @State private var selectedItem: PhotosPickerItem?
    @State private var showDeleteConfirmation = false

    private let photoSize: CGFloat = 100
    private let jpegQuality: CGFloat = 0.7

    private var displayBreed: String {
        if selectedBreed.isEmpty || selectedBreed == "Other" {
            return customBreed.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return selectedBreed
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !displayBreed.isEmpty
            || dogStore.dog.photoData != nil
    }

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
                .accessibilityLabel("Change dog photo")
                .accessibilityHint("Pick a photo from your library")
                if dogStore.dog.photoData != nil {
                    Button(role: .destructive) {
                        dogStore.updatePhoto(nil)
                    } label: {
                        Label("Remove Photo", systemImage: "trash")
                    }
                    .accessibilityLabel("Remove dog photo")
                    .accessibilityHint("Removes the current photo")
                }
            } header: {
                Text("Photo")
            }

            Section {
                TextField("Name", text: $name, prompt: Text("Dog's name"))
                    .accessibilityLabel("Dog's name")
                Picker("Breed", selection: $selectedBreed) {
                    Text("Select breed").tag("")
                    ForEach(commonBreeds.filter { !$0.isEmpty }, id: \.self) { breed in
                        Text(breed).tag(breed)
                    }
                }
                if selectedBreed == "Other" {
                    TextField("Breed name", text: $customBreed, prompt: Text("Enter breed"))
                }
            } header: {
                Text("Details")
            }

            if !isOnboarding {
                Section {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete Profile", systemImage: "trash")
                    }
                    .accessibilityLabel("Delete dog profile")
                    .accessibilityHint("Removes the profile; you can set it up again later")
                }
            }
        }
        .navigationTitle(isOnboarding ? "Set Up Your Dog" : "Dog Profile")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(isOnboarding)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Save") {
                    saveAndDismissIfNeeded()
                }
                .disabled(!canSave)
                .accessibilityLabel("Save dog profile")
                .accessibilityHint(canSave ? "Saves name, breed, and photo" : "Enter a name or breed to save")
            }
        }
        .confirmationDialog("Delete Profile", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                dogStore.clearProfile()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will remove the dog profile. You can set it up again anytime.")
        }
        .onAppear {
            name = dogStore.dog.name
            let saved = dogStore.dog.breed
            if commonBreeds.contains(saved) && !saved.isEmpty {
                selectedBreed = saved
                customBreed = ""
            } else {
                selectedBreed = saved.isEmpty ? "" : "Other"
                customBreed = saved
            }
        }
    }

    @ViewBuilder
    private var photoView: some View {
        if let data = dogStore.dog.photoData, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: photoSize, height: photoSize)
                .clipShape(Circle())
        } else {
            Image(systemName: "pawprint.circle.fill")
                .font(.system(size: photoSize * 0.8))
                .foregroundStyle(.secondary)
                .frame(width: photoSize, height: photoSize)
        }
    }

    private func loadAndSavePhoto(from item: PhotosPickerItem?) async {
        guard let item else { return }
        guard let data = try? await item.loadTransferable(type: Data.self) else { return }
        guard let uiImage = UIImage(data: data) else { return }
        let jpeg = uiImage.jpegData(compressionQuality: jpegQuality)
        await MainActor.run {
            dogStore.updatePhoto(jpeg)
        }
    }

    private func saveAndDismissIfNeeded() {
        dogStore.save(Dog(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            breed: displayBreed,
            photoData: dogStore.dog.photoData
        ))
        if !isOnboarding {
            dismiss()
        }
    }
}

#Preview {
    NavigationStack {
        DogProfileView(dogStore: DogProfileStore())
    }
}

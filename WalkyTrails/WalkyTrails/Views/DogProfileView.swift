//
//  DogProfileView.swift
//  WalkyTrails
//

import PhotosUI
import SwiftUI
import UIKit

private let commonBreeds = [
    "", "Vizsla", "Weimaraner", "German Shorthaired", "German Wirehaired", "German Shepherd",
    "Labrador Retriever", "Golden Retriever", "French Bulldog", "Bulldog", "Poodle", "Beagle",
    "Rottweiler", "Yorkshire Terrier", "Boxer", "Dachshund", "Shih Tzu", "Australian Shepherd",
    "Pembroke Welsh Corgi", "Chihuahua", "Cavalier King Charles Spaniel", "Husky", "Mixed", "Other"
]

struct DogProfileView: View {
    @EnvironmentObject var dogStore: DogProfileStore
    /// When nil, adding a new dog; when set, editing.
    var initialDog: Dog?
    var isOnboarding: Bool = false
    var onComplete: (() -> Void)?
    var onSkip: (() -> Void)?
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var selectedBreed: String = ""
    @State private var customBreed: String = ""
    @State private var selectedItem: PhotosUI.PhotosPickerItem?
    @State private var newPhotoData: Data?
    @State private var showDeleteConfirmation = false

    private let photoSize: CGFloat = 100
    private let jpegQuality: CGFloat = 0.7
    private var isAddMode: Bool { initialDog == nil }

    private var displayBreed: String {
        if selectedBreed.isEmpty || selectedBreed == "Other" {
            return customBreed.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return selectedBreed
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !displayBreed.isEmpty
            || (isAddMode ? newPhotoData != nil : (dogStore.dog(byId: initialDog!.id)?.photoData != nil))
    }

    private var currentPhotoData: Data? {
        if isAddMode { return newPhotoData }
        return dogStore.dog(byId: initialDog!.id)?.photoData
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

                PhotosPicker(selection: $selectedItem, matching: .images, photoLibrary: .shared()) {
                    Label("Change Photo", systemImage: "photo.on.rectangle.angled")
                }
                .onChange(of: selectedItem) { _, newItem in
                    Task { await loadAndSavePhoto(from: newItem) }
                }
                .accessibilityLabel("Change dog photo")
                if currentPhotoData != nil {
                    Button(role: .destructive) {
                        if isAddMode { newPhotoData = nil }
                        else if let id = initialDog?.id { dogStore.updatePhoto(forDogId: id, imageData: nil) }
                    } label: {
                        Label("Remove Photo", systemImage: "trash")
                    }
                }
            } header: { Text("Photo") }

            Section {
                TextField("Name", text: $name, prompt: Text("Dog's name"))
                Picker("Breed", selection: $selectedBreed) {
                    Text("Select breed").tag("")
                    ForEach(commonBreeds.filter { !$0.isEmpty }, id: \.self) { Text($0).tag($0) }
                }
                if selectedBreed == "Other" {
                    TextField("Breed name", text: $customBreed, prompt: Text("Enter breed"))
                }
            } header: { Text("Details") }

            if !isOnboarding && !isAddMode {
                Section {
                    Button(role: .destructive) { showDeleteConfirmation = true } label: {
                        Label("Delete Dog", systemImage: "trash")
                    }
                }
            }
        }
        .navigationTitle(isOnboarding ? "Add Your First Dog" : (isAddMode ? "New Dog" : "Edit Dog"))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(isOnboarding)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Save") {
                    saveAndDismiss()
                }
                .disabled(!canSave)
                .accessibilityLabel("Save dog")
            }
            if isOnboarding && isAddMode {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Skip") {
                        onSkip?()
                    }
                    .accessibilityLabel("Skip adding a dog")
                }
            }
        }
        .confirmationDialog("Delete Dog", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let id = initialDog?.id {
                    dogStore.deleteDog(id: id)
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will remove this dog from your profile. Walks with this dog will still appear in history.")
        }
        .onAppear {
            if let dog = initialDog {
                name = dog.name
                if commonBreeds.contains(dog.breed) && !dog.breed.isEmpty {
                    selectedBreed = dog.breed
                    customBreed = ""
                } else {
                    selectedBreed = dog.breed.isEmpty ? "" : "Other"
                    customBreed = dog.breed
                }
            }
        }
    }

    @ViewBuilder
    private var photoView: some View {
        if let data = currentPhotoData, let uiImage = UIImage(data: data) {
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
            if isAddMode { newPhotoData = jpeg }
            else if let id = initialDog?.id { dogStore.updatePhoto(forDogId: id, imageData: jpeg) }
        }
    }

    private func saveAndDismiss() {
        if isAddMode {
            let dog = Dog(name: name.trimmingCharacters(in: .whitespacesAndNewlines), breed: displayBreed, photoData: newPhotoData)
            dogStore.addDog(dog)
            if isOnboarding { onComplete?() }
            else { dismiss() }
        } else if let dog = initialDog {
            let updated = Dog(id: dog.id, name: name.trimmingCharacters(in: .whitespacesAndNewlines), breed: displayBreed, photoData: dogStore.dog(byId: dog.id)?.photoData)
            dogStore.updateDog(updated)
            if isOnboarding { onComplete?() }
            else { dismiss() }
        }
    }
}

#Preview {
    NavigationStack {
        DogProfileView(initialDog: nil)
            .environmentObject(DogProfileStore())
    }
}

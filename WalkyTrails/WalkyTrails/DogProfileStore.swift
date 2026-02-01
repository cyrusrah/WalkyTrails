//
//  DogProfileStore.swift
//  WalkyTrails
//

import Foundation
import SwiftUI

/// Persists multiple dogs (belonging to the user) in UserDefaults.
/// Migrates from legacy single-dog key to dogs array on first load.
final class DogProfileStore: ObservableObject {
    static let dogKey = "walkyTrails.dogProfile"
    static let dogsKey = "walkyTrails.dogs"

    @Published var dogs: [Dog]

    init() {
        self.dogs = Self.loadDogs()
    }

    private static func loadDogs() -> [Dog] {
        // New format: array of dogs
        if let data = UserDefaults.standard.data(forKey: dogsKey),
           let decoded = try? JSONDecoder().decode([Dog].self, from: data),
           !decoded.isEmpty {
            return decoded
        }
        // Migrate from legacy single dog (no id)
        if let data = UserDefaults.standard.data(forKey: dogKey) {
            struct LegacyDog: Codable {
                var name: String
                var breed: String
                var photoData: Data?
            }
            if let legacy = try? JSONDecoder().decode(LegacyDog.self, from: data),
               legacy.name.isEmpty == false || legacy.breed.isEmpty == false || legacy.photoData != nil {
                let dog = Dog(name: legacy.name, breed: legacy.breed, photoData: legacy.photoData)
                UserDefaults.standard.removeObject(forKey: dogKey)
                let encoded = (try? JSONEncoder().encode([dog])) ?? Data()
                UserDefaults.standard.set(encoded, forKey: dogsKey)
                return [dog]
            }
        }
        return []
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(dogs) else { return }
        UserDefaults.standard.set(data, forKey: Self.dogsKey)
    }

    func dog(byId id: UUID) -> Dog? {
        dogs.first { $0.id == id }
    }

    func addDog(_ dog: Dog) {
        dogs.append(dog)
        persist()
    }

    func updateDog(_ dog: Dog) {
        guard let idx = dogs.firstIndex(where: { $0.id == dog.id }) else { return }
        dogs[idx] = dog
        persist()
    }

    func deleteDog(id: UUID) {
        dogs.removeAll { $0.id == id }
        persist()
    }

    func updatePhoto(forDogId id: UUID, imageData: Data?) {
        guard let idx = dogs.firstIndex(where: { $0.id == id }) else { return }
        dogs[idx].photoData = imageData
        persist()
    }

    /// Convenience: first dog (for backward-compat UI during transition).
    var firstDog: Dog? { dogs.first }

    /// Whether the user has at least one dog with content.
    var hasAnyDog: Bool { dogs.contains { $0.hasContent } }

    /// Replaces all dogs (e.g. after restore from backup).
    func replaceDogs(with newDogs: [Dog]) {
        dogs = newDogs
        persist()
    }
}

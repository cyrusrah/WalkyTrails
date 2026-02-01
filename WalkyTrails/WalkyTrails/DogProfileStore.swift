//
//  DogProfileStore.swift
//  WalkyTrails
//

import Foundation
import SwiftUI

/// Persists the single dog profile (name, breed, photo) in UserDefaults.
final class DogProfileStore: ObservableObject {
    static let dogKey = "walkyTrails.dogProfile"

    @Published var dog: Dog

    init() {
        self.dog = Self.loadDog()
    }

    private static func loadDog() -> Dog {
        guard let data = UserDefaults.standard.data(forKey: dogKey) else { return Dog() }
        let decoder = JSONDecoder()
        return (try? decoder.decode(Dog.self, from: data)) ?? Dog()
    }

    private func persist() {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(dog) else { return }
        UserDefaults.standard.set(data, forKey: Self.dogKey)
    }

    func save(_ newDog: Dog) {
        dog = newDog
        persist()
    }

    func updatePhoto(_ imageData: Data?) {
        dog.photoData = imageData
        persist()
    }

    /// Clears the profile; app will show onboarding again when appropriate.
    func clearProfile() {
        dog = Dog()
        persist()
    }
}

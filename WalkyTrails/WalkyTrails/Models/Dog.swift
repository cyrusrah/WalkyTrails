//
//  Dog.swift
//  WalkyTrails
//

import Foundation

/// Single dog profile: name, optional breed, optional photo. Stored locally.
struct Dog: Codable, Equatable {
    var name: String
    var breed: String
    /// JPEG data for profile photo; kept small for UserDefaults.
    var photoData: Data?

    init(name: String = "", breed: String = "", photoData: Data? = nil) {
        self.name = name
        self.breed = breed
        self.photoData = photoData
    }

    var hasContent: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !breed.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || photoData != nil
    }
}

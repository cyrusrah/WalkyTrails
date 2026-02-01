//
//  Dog.swift
//  WalkyTrails
//

import Foundation
import SwiftUI

/// Single dog profile: name, optional breed, optional photo. Belongs to the user; stored locally.
struct Dog: Codable, Equatable, Identifiable {
    let id: UUID
    var name: String
    var breed: String
    /// JPEG data for profile photo; kept small for UserDefaults.
    var photoData: Data?

    init(id: UUID = UUID(), name: String = "", breed: String = "", photoData: Data? = nil) {
        self.id = id
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

/// Shared visual language for multi-dog: stable color per dog (map markers, event lists).
enum DogColors {
    private static let palette: [Color] = [
        Color(red: 0.25, green: 0.45, blue: 0.95),
        Color(red: 0.95, green: 0.55, blue: 0.2),
        Color(red: 0.2, green: 0.65, blue: 0.45),
        Color(red: 0.6, green: 0.35, blue: 0.85),
        Color(red: 0.2, green: 0.7, blue: 0.75),
        Color(red: 0.9, green: 0.4, blue: 0.55),
    ]

    static func color(for dogId: UUID, in dogIds: [UUID]) -> Color? {
        guard dogIds.count >= 2, let index = dogIds.firstIndex(of: dogId) else { return nil }
        return palette[index % palette.count]
    }
}

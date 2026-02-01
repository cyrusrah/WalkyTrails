//
//  Dog.swift
//  WalkyTrails
//

import Foundation
import SwiftUI

/// Single dog profile: name, optional breed, optional photo. Stored locally.
struct Dog: Codable, Equatable, Identifiable {
    var id: UUID
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

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? ""
        breed = try c.decodeIfPresent(String.self, forKey: .breed) ?? ""
        photoData = try c.decodeIfPresent(Data.self, forKey: .photoData)
    }

    var hasContent: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !breed.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || photoData != nil
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, breed, photoData
    }
}

/// Stable colors for multi-dog walks (map rings, list dots).
enum DogColors {
    private static let palette: [Color] = [
        .blue, .orange, .green, .purple, .pink, .cyan, .indigo, .mint
    ]

    static func color(for dogId: UUID, in dogIds: [UUID]) -> Color? {
        guard dogIds.count >= 2, let index = dogIds.firstIndex(of: dogId) else { return nil }
        return palette[index % palette.count]
    }
}

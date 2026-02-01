//
//  UserProfileStore.swift
//  WalkyTrails
//

import Foundation
import SwiftUI

/// User profile: name and optional photo. Stored locally.
struct UserProfile: Codable, Equatable {
    var name: String
    var photoData: Data?

    init(name: String = "", photoData: Data? = nil) {
        self.name = name
        self.photoData = photoData
    }

    var hasContent: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || photoData != nil
    }
}

final class UserProfileStore: ObservableObject {
    static let key = "walkyTrails.userProfile"

    @Published var user: UserProfile

    init() {
        self.user = Self.load()
    }

    private static func load() -> UserProfile {
        guard let data = UserDefaults.standard.data(forKey: key) else { return UserProfile() }
        return (try? JSONDecoder().decode(UserProfile.self, from: data)) ?? UserProfile()
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(user) else { return }
        UserDefaults.standard.set(data, forKey: Self.key)
    }

    func update(_ newUser: UserProfile) {
        user = newUser
        persist()
    }

    func updatePhoto(_ imageData: Data?) {
        user.photoData = imageData
        persist()
    }
}

//
//  UserProfile.swift
//  WalkyTrails
//

import Foundation

/// The human profile (you). One per app; later becomes the account in community.
struct UserProfile: Codable, Equatable {
    var name: String
    /// JPEG data for profile photo; kept small for UserDefaults.
    var photoData: Data?

    init(name: String = "", photoData: Data? = nil) {
        self.name = name
        self.photoData = photoData
    }

    var hasContent: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || photoData != nil
    }
}

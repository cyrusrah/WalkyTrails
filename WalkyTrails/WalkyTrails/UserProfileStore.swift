//
//  UserProfileStore.swift
//  WalkyTrails
//

import Foundation
import SwiftUI

/// Persists the user profile (you: name, photo) and onboarding state in UserDefaults.
final class UserProfileStore: ObservableObject {
    static let userProfileKey = "walkyTrails.userProfile"
    static let onboardingCompletedKey = "walkyTrails.onboardingCompleted"

    @Published var user: UserProfile
    @Published var hasCompletedOnboarding: Bool

    init() {
        self.user = Self.loadUser()
        let explicit = UserDefaults.standard.bool(forKey: Self.onboardingCompletedKey)
        let hadLegacyDog = UserDefaults.standard.data(forKey: DogProfileStore.dogKey) != nil
        let hasDogs = (UserDefaults.standard.data(forKey: DogProfileStore.dogsKey).flatMap { try? JSONDecoder().decode([Dog].self, from: $0) })?.isEmpty == false
        self.hasCompletedOnboarding = explicit || hadLegacyDog || hasDogs
    }

    private static func loadUser() -> UserProfile {
        guard let data = UserDefaults.standard.data(forKey: userProfileKey) else { return UserProfile() }
        return (try? JSONDecoder().decode(UserProfile.self, from: data)) ?? UserProfile()
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(user) else { return }
        UserDefaults.standard.set(data, forKey: Self.userProfileKey)
    }

    func save(_ newUser: UserProfile) {
        user = newUser
        persist()
    }

    func updatePhoto(_ imageData: Data?) {
        user.photoData = imageData
        persist()
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: Self.onboardingCompletedKey)
    }
}

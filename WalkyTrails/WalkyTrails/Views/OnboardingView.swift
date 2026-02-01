//
//  OnboardingView.swift
//  WalkyTrails
//

import SwiftUI

/// Onboarding flow: 1) Your profile (name, photo), 2) Add first dog or Skip.
struct OnboardingView: View {
    @ObservedObject var userStore: UserProfileStore
    @ObservedObject var dogStore: DogProfileStore
    @State private var step: Step = .userProfile

    enum Step {
        case userProfile
        case addDog
    }

    var body: some View {
        Group {
            switch step {
            case .userProfile:
                UserProfileView(userStore: userStore, isOnboarding: true)
                    .toolbar {
                        ToolbarItem(placement: .primaryAction) {
                            Button("Next") {
                                step = .addDog
                            }
                            .accessibilityLabel("Next: add your first dog")
                        }
                    }
            case .addDog:
                DogProfileView(dogStore: dogStore, initialDog: nil, isOnboarding: true, onComplete: {
                    userStore.completeOnboarding()
                }, onSkip: {
                    userStore.completeOnboarding()
                })
            }
        }
    }
}

#Preview {
    NavigationStack {
        OnboardingView(userStore: UserProfileStore(), dogStore: DogProfileStore())
    }
}

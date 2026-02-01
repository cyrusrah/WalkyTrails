//
//  OnboardingView.swift
//  WalkyTrails
//

import SwiftUI

/// Onboarding flow: 1) Your profile (name, photo), 2) Add first dog or Skip.
struct OnboardingView: View {
    @EnvironmentObject var userStore: UserProfileStore
    @EnvironmentObject var dogStore: DogProfileStore
    @State private var step: Step = .userProfile

    enum Step {
        case userProfile
        case addDog
    }

    var body: some View {
        Group {
            switch step {
            case .userProfile:
                UserProfileView(isOnboarding: true)
                    .toolbar {
                        ToolbarItem(placement: .primaryAction) {
                            Button("Next") {
                                step = .addDog
                            }
                            .accessibilityLabel("Next: add your first dog")
                        }
                    }
            case .addDog:
                DogProfileView(initialDog: nil, isOnboarding: true, onComplete: {
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
        OnboardingView()
            .environmentObject(UserProfileStore())
            .environmentObject(DogProfileStore())
    }
}

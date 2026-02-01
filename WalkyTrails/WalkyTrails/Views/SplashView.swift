//
//  SplashView.swift
//  WalkyTrails
//

import SwiftUI

/// Branded splash shown briefly at launch before Home or onboarding.
struct SplashView: View {
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            VStack(spacing: 16) {
                Image("SplashLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                Text("WalkyTrails")
                    .font(.largeTitle.weight(.bold))
                Text("Log your walks, one step at a time.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    SplashView()
}

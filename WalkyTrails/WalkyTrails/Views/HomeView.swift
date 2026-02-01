//
//  HomeView.swift
//  WalkyTrails
//

import SwiftUI
import UIKit

struct HomeView: View {
    @ObservedObject var store: WalkStore
    @ObservedObject var dogStore: DogProfileStore
    @State private var showHistory = false

    private var greeting: String {
        let name = dogStore.dog.name.trimmingCharacters(in: .whitespacesAndNewlines)
        if name.isEmpty { return "Log your walks, one step at a time." }
        return "Ready to walk, \(name)?"
    }

    private var hasProfile: Bool { dogStore.dog.hasContent }

    var body: some View {
        VStack(spacing: 0) {
            if hasProfile {
                NavigationLink {
                    DogProfileView(dogStore: dogStore, isOnboarding: false)
                } label: {
                    profileRow
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color(.secondarySystemBackground))
            }
            Spacer()
            Text("WalkyTrails")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text(greeting)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Spacer()
            Button {
                store.startWalk()
            } label: {
                Label("Start Walk", systemImage: "figure.walk")
                    .font(.title2)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 24)
            NavigationLink {
                WalkHistoryView(store: store)
            } label: {
                Label("History", systemImage: "clock.arrow.circlepath")
                    .font(.body)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.bordered)
            .padding(.horizontal, 24)
            Spacer()
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var profileRow: some View {
        HStack(spacing: 12) {
            if let data = dogStore.dog.photoData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
            } else {
                Image(systemName: "pawprint.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.secondary)
            }
            Text(dogStore.dog.name.isEmpty ? "Dog" : dogStore.dog.name)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
            if !dogStore.dog.breed.isEmpty {
                Text("·")
                    .foregroundStyle(.secondary)
                Text(dogStore.dog.breed)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
    }
}

#Preview {
    HomeView(store: WalkStore(), dogStore: DogProfileStore())
}

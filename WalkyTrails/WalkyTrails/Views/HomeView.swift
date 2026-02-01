//
//  HomeView.swift
//  WalkyTrails
//

import SwiftUI
import UIKit

struct HomeView: View {
    @ObservedObject var store: WalkStore
    @ObservedObject var userStore: UserProfileStore
    @ObservedObject var dogStore: DogProfileStore
    @ObservedObject var settings: SettingsStore
    @State private var showStartWalkSheet = false
    @State private var selectedDogIds: Set<UUID> = []

    private var greeting: String {
        let userName = userStore.user.name.trimmingCharacters(in: .whitespacesAndNewlines)
        if !userName.isEmpty { return "Ready to walk, \(userName)?" }
        if let first = dogStore.dogs.first, !first.name.isEmpty {
            return "Ready to walk, \(first.name)?"
        }
        return "Log your walks, one step at a time."
    }

    private var hasUserPhoto: Bool { userStore.user.photoData != nil }
    private var hasAnyDog: Bool { dogStore.hasAnyDog }

    private var walksThisWeek: [Walk] {
        let cal = Calendar.current
        guard let weekStart = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) else { return [] }
        return store.walks.filter { $0.startTime >= weekStart }
    }

    /// Consecutive days (including today) with at least one walk.
    private var currentStreakDays: Int {
        let cal = Calendar.current
        var day = cal.startOfDay(for: Date())
        var streak = 0
        let walksByDay = Set(store.walks.map { cal.startOfDay(for: $0.startTime) })
        while walksByDay.contains(day) {
            streak += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }
        return streak
    }

    private var statsSection: some View {
        HStack(spacing: 24) {
            VStack(spacing: 4) {
                Text("\(walksThisWeek.count)")
                    .font(.title2.weight(.semibold))
                Text("Walks this week")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            VStack(spacing: 4) {
                Text(settings.formattedDistanceShort(walksThisWeek.reduce(0) { $0 + $1.distanceMeters }))
                    .font(.title2.weight(.semibold))
                Text("This week")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if currentStreakDays > 0 {
                VStack(spacing: 4) {
                    Text("\(currentStreakDays)")
                        .font(.title2.weight(.semibold))
                    Text("Streak")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Stats: \(walksThisWeek.count) walks this week, \(settings.formattedDistanceShort(walksThisWeek.reduce(0) { $0 + $1.distanceMeters })) this week\(currentStreakDays > 0 ? ", \(currentStreakDays) day streak" : "")")
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            Text("WalkyTrails")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text(greeting)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            if !store.walks.isEmpty {
                statsSection
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
            }
            Spacer()
            Button {
                if dogStore.dogs.count == 1 {
                    store.startWalk(dogIds: [dogStore.dogs[0].id])
                } else {
                    selectedDogIds = Set(dogStore.dogs.map(\.id))
                    showStartWalkSheet = true
                }
            } label: {
                Label("Start Walk", systemImage: "figure.walk")
                    .font(.title2)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 24)
            .accessibilityLabel("Start walk")
            .accessibilityHint("Begins tracking a new walk with timer and GPS")
            .sheet(isPresented: $showStartWalkSheet) {
                startWalkSheet
            }
            .onChange(of: showStartWalkSheet) { _, isShowing in
                if isShowing { selectedDogIds = Set(dogStore.dogs.map(\.id)) }
            }
            NavigationLink {
                WalkHistoryView(store: store, settings: settings, dogStore: dogStore)
            } label: {
                Label("History", systemImage: "clock.arrow.circlepath")
                    .font(.body)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.bordered)
            .padding(.horizontal, 24)
            .accessibilityLabel("Walk history")
            .accessibilityHint("Opens list of past walks")
            Spacer()
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                NavigationLink {
                    UserProfileView(userStore: userStore, isOnboarding: false)
                } label: {
                    profileCircle
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Your profile")
                .accessibilityHint("Opens your name and photo")
            }
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    SettingsView(settings: settings, store: store, userStore: userStore, dogStore: dogStore)
                } label: {
                    Image(systemName: "gearshape")
                }
                .accessibilityLabel("Settings")
                .accessibilityHint("Units, date format, and map style")
            }
        }
    }

    private var profileCircle: some View {
        Group {
            if let data = userStore.user.photoData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
            } else if let data = dogStore.firstDog?.photoData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var startWalkSheet: some View {
        NavigationStack {
            List {
                if dogStore.dogs.isEmpty {
                    Section {
                        Text("Add a dog to track who's on the walk.")
                            .foregroundStyle(.secondary)
                        NavigationLink {
                            DogProfileView(dogStore: dogStore, initialDog: nil, isOnboarding: false)
                        } label: {
                            Label("Add dog", systemImage: "plus.circle.fill")
                        }
                    }
                } else {
                    Section {
                        ForEach(dogStore.dogs) { dog in
                            Button {
                                if selectedDogIds.contains(dog.id) {
                                    selectedDogIds.remove(dog.id)
                                } else {
                                    selectedDogIds.insert(dog.id)
                                }
                            } label: {
                                HStack {
                                    Text(dog.name.isEmpty ? "Unnamed" : dog.name)
                                    Spacer()
                                    if selectedDogIds.contains(dog.id) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(Color.accentColor)
                                    }
                                }
                            }
                        }
                    } footer: {
                        Text("Tap to select. All selected by default.")
                    }
                }
            }
            .navigationTitle("Who's walking?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showStartWalkSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if dogStore.dogs.isEmpty {
                        NavigationLink {
                            DogProfileView(dogStore: dogStore, initialDog: nil, isOnboarding: false)
                        } label: {
                            Text("Add dog")
                        }
                        .fontWeight(.semibold)
                    } else {
                        Button("Start") {
                            store.startWalk(dogIds: Array(selectedDogIds))
                            showStartWalkSheet = false
                        }
                        .disabled(selectedDogIds.isEmpty)
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    HomeView(store: WalkStore(), userStore: UserProfileStore(), dogStore: DogProfileStore(), settings: SettingsStore())
}

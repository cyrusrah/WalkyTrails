//
//  HomeView.swift
//  WalkyTrails
//

import MapKit
import SwiftUI
import UIKit

struct HomeView: View {
    @EnvironmentObject var store: WalkStore
    @EnvironmentObject var userStore: UserProfileStore
    @EnvironmentObject var dogStore: DogProfileStore
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var locationManager: LocationManager
    @State private var showStartWalkSheet = false
    @State private var selectedDogIds: Set<UUID> = []
    @State private var showPlanWalkSheet = false
    @State private var planWalkPickDogsFirst = false
    @State private var planWalkDogIds: [UUID] = []
    @State private var searchText: String = ""
    @State private var selectedFilter: HomeFilter = .parks
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)

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

    enum HomeFilter: String, CaseIterable, Identifiable {
        case parks = "Parks"
        case water = "Water"
        case dogParks = "Dog Parks"
        var id: String { rawValue }
        var icon: String {
            switch self {
            case .parks: return "tree.fill"
            case .water: return "drop.fill"
            case .dogParks: return "pawprint.fill"
            }
        }
    }

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
        WTCard {
            HStack(spacing: 18) {
                statPill(value: "\(walksThisWeek.count)", label: "Walks")
                Divider()
                    .overlay(WTTheme.ColorToken.stone)
                statPill(
                    value: settings.formattedDistanceShort(walksThisWeek.reduce(0) { $0 + $1.distanceMeters }),
                    label: "This week"
                )
                if currentStreakDays > 0 {
                    Divider()
                        .overlay(WTTheme.ColorToken.stone)
                    statPill(value: "\(currentStreakDays)", label: "Streak")
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Stats: \(walksThisWeek.count) walks this week, \(settings.formattedDistanceShort(walksThisWeek.reduce(0) { $0 + $1.distanceMeters })) this week\(currentStreakDays > 0 ? ", \(currentStreakDays) day streak" : "")")
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            WTTheme.ColorToken.warmGrey.ignoresSafeArea()

            mapLayer

            VStack(spacing: WTTheme.Spacing.sm) {
                topSearchAndChips
                    .padding(.horizontal, WTTheme.Spacing.lg)
                    .padding(.top, WTTheme.Spacing.md)

                Spacer()

                VStack(spacing: WTTheme.Spacing.sm) {
                    placeCard
                        .padding(.horizontal, WTTheme.Spacing.lg)

                    startWalkCTA
                        .padding(.horizontal, WTTheme.Spacing.lg)
                }
                .padding(.bottom, WTTheme.Spacing.lg)
            }
        }
        .sheet(isPresented: $showStartWalkSheet) {
            startWalkSheet
        }
        .sheet(isPresented: $showPlanWalkSheet) {
            planWalkSheet
        }
        .onChange(of: showStartWalkSheet) { _, isShowing in
            if isShowing { selectedDogIds = Set(dogStore.dogs.map(\.id)) }
        }
        .onChange(of: showPlanWalkSheet) { _, isShowing in
            if isShowing, planWalkPickDogsFirst {
                selectedDogIds = Set(dogStore.dogs.map(\.id))
            }
            if !isShowing {
                planWalkPickDogsFirst = false
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                NavigationLink {
                    UserProfileView(isOnboarding: false)
                } label: {
                    profileCircle
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Your profile")
                .accessibilityHint("Opens your name and photo")
            }
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    SettingsView()
                } label: {
                    Image(systemName: "slider.horizontal.3")
                }
                .accessibilityLabel("Settings")
                .accessibilityHint("Units, date format, and map style")
            }
        }
    }

    private var mapLayer: some View {
        Map(position: $cameraPosition) {
            UserAnnotation()
        }
        .mapStyle(settings.mapStylePreference.mapStyle)
        .mapControlVisibility(.hidden)
        .ignoresSafeArea()
        .tint(WTTheme.ColorToken.route)
        .overlay(alignment: .trailing) {
            VStack(spacing: WTTheme.Spacing.sm) {
                mapFab(systemImage: "location.fill") {
                    cameraPosition = .userLocation(fallback: .automatic)
                }
                mapFab(systemImage: "square.3.layers.3d") {
                    cycleMapStyle()
                }
            }
            .padding(.trailing, WTTheme.Spacing.lg)
            .padding(.top, 160)
        }
    }

    private var topSearchAndChips: some View {
        VStack(spacing: WTTheme.Spacing.sm) {
            WTSearchBar(text: $searchText)
                .overlay(alignment: .trailing) {
                    Button {
                        // placeholder for filters panel
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease")
                            .foregroundStyle(WTTheme.ColorToken.mutedText)
                            .padding(.trailing, 10)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Filters")
                }

            HStack(spacing: WTTheme.Spacing.xs) {
                ForEach(HomeFilter.allCases) { filter in
                    WTChip(
                        title: filter.rawValue,
                        systemImage: filter.icon,
                        isSelected: selectedFilter == filter
                    ) {
                        selectedFilter = filter
                    }
                }
                Spacer(minLength: 0)
            }
        }
    }

    private var placeCard: some View {
        WTCard {
            HStack(spacing: WTTheme.Spacing.sm) {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(WTTheme.ColorToken.mapWater.opacity(0.55))
                    .frame(width: 56, height: 56)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundStyle(WTTheme.ColorToken.mutedText)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text("Riverside Park")
                        .font(.system(.headline, design: .default).weight(.semibold))
                        .foregroundStyle(WTTheme.ColorToken.charcoal)
                    Text("0.8 km away · Dog friendly")
                        .font(WTTheme.Typography.caption)
                        .foregroundStyle(WTTheme.ColorToken.mutedText)
                    Text("Popular now")
                        .font(WTTheme.Typography.caption)
                        .foregroundStyle(WTTheme.ColorToken.mutedText)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .foregroundStyle(WTTheme.ColorToken.mutedText)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Riverside Park, 0.8 kilometers away, dog friendly")
    }

    private var startWalkCTA: some View {
        Button {
            if dogStore.dogs.count == 1 {
                store.startWalk(dogIds: [dogStore.dogs[0].id])
            } else {
                selectedDogIds = Set(dogStore.dogs.map(\.id))
                showStartWalkSheet = true
            }
        } label: {
            Text("Start Walk")
                .frame(maxWidth: .infinity)
        }
        .wtButton(.primary, size: .large)
        .accessibilityLabel("Start walk")
        .accessibilityHint("Begins tracking a new walk with timer and GPS")
    }

    private func mapFab(systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(WTTheme.ColorToken.forest)
                .frame(width: 42, height: 42)
                .background(
                    Circle()
                        .fill(.white)
                        .overlay(Circle().stroke(WTTheme.ColorToken.stone, lineWidth: WTTheme.Stroke.hairline))
                        .shadow(color: .black.opacity(WTTheme.Shadow.opacity), radius: 12, x: 0, y: 6)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Map action")
    }

    private func cycleMapStyle() {
        switch settings.mapStylePreference {
        case .standard:
            settings.mapStylePreference = .hybrid
        case .hybrid:
            settings.mapStylePreference = .imagery
        case .imagery:
            settings.mapStylePreference = .standard
        }
    }

    private func statPill(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.system(.title3, design: .default).weight(.bold))
                .foregroundStyle(WTTheme.ColorToken.charcoal)
            Text(label)
                .font(WTTheme.Typography.caption)
                .foregroundStyle(WTTheme.ColorToken.mutedText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
                            DogProfileView(initialDog: nil, isOnboarding: false)
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
                            DogProfileView(initialDog: nil, isOnboarding: false)
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

    @ViewBuilder
    private var planWalkSheet: some View {
        NavigationStack {
            if planWalkPickDogsFirst {
                List {
                    if dogStore.dogs.isEmpty {
                        Section {
                            Text("Add a dog to plan a walk.")
                                .foregroundStyle(.secondary)
                            NavigationLink {
                                DogProfileView(initialDog: nil, isOnboarding: false)
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
                            Text("Tap to select who is on this walk.")
                        }
                    }
                }
                .navigationTitle("Who's walking?")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showPlanWalkSheet = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        if dogStore.dogs.isEmpty {
                            NavigationLink {
                                DogProfileView(initialDog: nil, isOnboarding: false)
                            } label: {
                                Text("Add dog")
                            }
                            .fontWeight(.semibold)
                        } else {
                            Button("Next") {
                                planWalkDogIds = Array(selectedDogIds)
                                planWalkPickDogsFirst = false
                            }
                            .disabled(selectedDogIds.isEmpty)
                            .fontWeight(.semibold)
                        }
                    }
                }
            } else {
                PlanWalkView(dogIds: planWalkDogIds)
            }
        }
        .presentationDetents([.large])
    }
}

#Preview {
    HomeView()
        .environmentObject(WalkStore())
        .environmentObject(UserProfileStore())
        .environmentObject(DogProfileStore())
        .environmentObject(SettingsStore())
        .environmentObject(LocationManager())
}

//
//  HomeView.swift
//  WalkyTrails
//

import SwiftUI
import UIKit

struct HomeView: View {
    @ObservedObject var store: WalkStore
    @ObservedObject var dogStore: DogProfileStore
    @ObservedObject var settings: SettingsStore
    @State private var showHistory = false

    private var greeting: String {
        let name = dogStore.dog.name.trimmingCharacters(in: .whitespacesAndNewlines)
        if name.isEmpty { return "Log your walks, one step at a time." }
        return "Ready to walk, \(name)?"
    }

    private var hasProfile: Bool { dogStore.dog.hasContent }

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
                store.startWalk()
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
            NavigationLink {
                WalkHistoryView(store: store, settings: settings)
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
                if hasProfile {
                    NavigationLink {
                        DogProfileView(dogStore: dogStore, isOnboarding: false)
                    } label: {
                        profileCircle
                    }
                    .buttonStyle(.plain)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    SettingsView(settings: settings, store: store, dogStore: dogStore)
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
            if let data = dogStore.dog.photoData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
            } else {
                Image(systemName: "pawprint.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    HomeView(store: WalkStore(), dogStore: DogProfileStore(), settings: SettingsStore())
}

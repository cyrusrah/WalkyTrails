//
//  ContentView.swift
//  WalkyTrails
//
//  Created by Cyrus Rahgoshay on 2026-01-31.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var store: WalkStore
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var userStore: UserProfileStore
    @ObservedObject var dogStore: DogProfileStore
    @ObservedObject var settingsStore: SettingsStore
    @ObservedObject var weatherService: WeatherService

    var body: some View {
        Group {
            if store.currentWalk != nil {
                DuringWalkView(store: store, locationManager: locationManager, settings: settingsStore, dogStore: dogStore, weatherService: weatherService)
            } else if store.walkToSummarize != nil {
                WalkSummaryView(store: store, settings: settingsStore, dogStore: dogStore, locationManager: locationManager, weatherService: weatherService)
            } else if !userStore.user.hasContent {
                NavigationStack {
                    UserProfileView(userStore: userStore, isOnboarding: true)
                }
            } else if !dogStore.hasAnyDog {
                NavigationStack {
                    DogProfileView(dogStore: dogStore, isOnboarding: true)
                }
            } else {
                NavigationStack {
                    HomeView(store: store, userStore: userStore, dogStore: dogStore, settings: settingsStore)
                }
            }
        }
        .onChange(of: store.currentWalk != nil) { _, hasWalk in
            if hasWalk {
                locationManager.requestPermission()
                locationManager.startTracking()
            } else {
                locationManager.stopTracking()
            }
        }
    }
}

#Preview {
    ContentView(store: WalkStore(), locationManager: LocationManager(), userStore: UserProfileStore(), dogStore: DogProfileStore(), settingsStore: SettingsStore(), weatherService: WeatherService())
}

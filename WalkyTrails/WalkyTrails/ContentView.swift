//
//  ContentView.swift
//  WalkyTrails
//
//  Created by Cyrus Rahgoshay on 2026-01-31.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: WalkStore
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var userStore: UserProfileStore
    @EnvironmentObject var dogStore: DogProfileStore
    @EnvironmentObject var settingsStore: SettingsStore
    @EnvironmentObject var weatherService: WeatherService

    var body: some View {
        Group {
            if store.currentWalk != nil {
                DuringWalkView()
            } else if store.walkToSummarize != nil {
                WalkSummaryView()
            } else if !userStore.hasCompletedOnboarding {
                NavigationStack {
                    OnboardingView()
                }
            } else {
                NavigationStack {
                    HomeView()
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
    ContentView()
        .environmentObject(WalkStore())
        .environmentObject(LocationManager())
        .environmentObject(UserProfileStore())
        .environmentObject(DogProfileStore())
        .environmentObject(SettingsStore())
        .environmentObject(WeatherService())
}

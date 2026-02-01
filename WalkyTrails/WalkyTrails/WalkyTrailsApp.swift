//
//  WalkyTrailsApp.swift
//  WalkyTrails
//
//  Created by Cyrus Rahgoshay on 2026-01-31.
//

import SwiftUI

@main
struct WalkyTrailsApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var store = WalkStore()
    @StateObject private var locationManager = LocationManager()
    @StateObject private var userStore = UserProfileStore()
    @StateObject private var dogStore = DogProfileStore()
    @StateObject private var settingsStore = SettingsStore()
    @StateObject private var weatherService = WeatherService()
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            Group {
                if showSplash {
                    SplashView()
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                withAnimation(.easeOut(duration: 0.25)) {
                                    showSplash = false
                                }
                            }
                        }
                } else {
                    ContentView()
                        .environmentObject(store)
                        .environmentObject(locationManager)
                        .environmentObject(userStore)
                        .environmentObject(dogStore)
                        .environmentObject(settingsStore)
                        .environmentObject(weatherService)
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active { store.reloadCurrentWalkFromStorage() }
            }
        }
    }
}

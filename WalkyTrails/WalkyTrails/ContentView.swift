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
    @ObservedObject var dogStore: DogProfileStore

    var body: some View {
        Group {
            if store.currentWalk != nil {
                DuringWalkView(store: store, locationManager: locationManager)
            } else if store.walkToSummarize != nil {
                WalkSummaryView(store: store)
            } else if !dogStore.dog.hasContent {
                NavigationStack {
                    DogProfileView(dogStore: dogStore, isOnboarding: true)
                }
            } else {
                NavigationStack {
                    HomeView(store: store, dogStore: dogStore)
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
    ContentView(store: WalkStore(), locationManager: LocationManager(), dogStore: DogProfileStore())
}

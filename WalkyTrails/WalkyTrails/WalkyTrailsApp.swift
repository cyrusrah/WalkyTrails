//
//  WalkyTrailsApp.swift
//  WalkyTrails
//
//  Created by Cyrus Rahgoshay on 2026-01-31.
//

import SwiftUI

@main
struct WalkyTrailsApp: App {
    @StateObject private var store = WalkStore()
    @StateObject private var locationManager = LocationManager()
    @StateObject private var dogStore = DogProfileStore()
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
                    ContentView(store: store, locationManager: locationManager, dogStore: dogStore)
                }
            }
        }
    }
}

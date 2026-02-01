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

    var body: some Scene {
        WindowGroup {
            ContentView(store: store)
        }
    }
}

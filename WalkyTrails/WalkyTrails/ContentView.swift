//
//  ContentView.swift
//  WalkyTrails
//
//  Created by Cyrus Rahgoshay on 2026-01-31.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var store: WalkStore

    var body: some View {
        Group {
            if store.currentWalk != nil {
                DuringWalkView(store: store)
            } else if store.walkToSummarize != nil {
                WalkSummaryView(store: store)
            } else {
                HomeView(store: store)
            }
        }
    }
}

#Preview {
    ContentView(store: WalkStore())
}

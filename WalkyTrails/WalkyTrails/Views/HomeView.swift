//
//  HomeView.swift
//  WalkyTrails
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var store: WalkStore
    @State private var showHistory = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()
                Text("WalkyTrails")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("Log your walks, one step at a time.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
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
                NavigationLink {
                    WalkHistoryView(store: store)
                } label: {
                    Label("History", systemImage: "clock.arrow.circlepath")
                        .font(.body)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.bordered)
                .padding(.horizontal, 24)
                Spacer()
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    HomeView(store: WalkStore())
}

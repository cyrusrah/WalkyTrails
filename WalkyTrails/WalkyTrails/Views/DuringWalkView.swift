//
//  DuringWalkView.swift
//  WalkyTrails
//

import SwiftUI

struct DuringWalkView: View {
    @ObservedObject var store: WalkStore

    private var currentWalk: Walk? { store.currentWalk }

    var body: some View {
        VStack(spacing: 24) {
            Text("Walk in progress")
                .font(.headline)
                .foregroundStyle(.secondary)
            if let walk = currentWalk {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    Text(formattedDuration(walk.startTime, now: context.date))
                        .font(.system(.largeTitle, design: .monospaced))
                }
                HStack(spacing: 16) {
                    Button {
                        store.addEventToCurrentWalk(.pee)
                    } label: {
                        Label("Pee", systemImage: "drop")
                    }
                    .buttonStyle(.bordered)
                    Button {
                        store.addEventToCurrentWalk(.poop)
                    } label: {
                        Label("Poop", systemImage: "leaf")
                    }
                    .buttonStyle(.bordered)
                }
                Spacer()
                Button(role: .destructive) {
                    store.endWalk()
                } label: {
                    Label("End Walk", systemImage: "stop.circle.fill")
                        .font(.title3)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
            }
        }
        .padding()
    }

    private func formattedDuration(_ from: Date, now: Date = Date()) -> String {
        let interval = now.timeIntervalSince(from)
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    DuringWalkView(store: {
        let s = WalkStore()
        s.startWalk()
        return s
    }())
}

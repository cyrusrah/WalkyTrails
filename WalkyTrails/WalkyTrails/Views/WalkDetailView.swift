//
//  WalkDetailView.swift
//  WalkyTrails
//

import SwiftUI

struct WalkDetailView: View {
    let walk: Walk

    var body: some View {
        List {
            Section {
                Label(formattedDuration(walk.durationSeconds), systemImage: "clock")
                if walk.distanceMeters > 0 {
                    Label(String(format: "%.2f km", walk.distanceMeters / 1000), systemImage: "location")
                }
                Text(walk.startTime, style: .date)
                Text(walk.startTime, style: .time)
            } header: {
                Text("Summary")
            }

            if !walk.events.isEmpty {
                Section {
                    ForEach(walk.events) { event in
                        HStack {
                            Image(systemName: event.type == .pee ? "drop.fill" : "leaf.fill")
                                .foregroundStyle(event.type == .pee ? .blue : .brown)
                            Text(event.type.rawValue.capitalized)
                            Spacer()
                            Text(event.timestamp, style: .time)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Events")
                }
            }
        }
        .navigationTitle("Walk")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func formattedDuration(_ seconds: TimeInterval) -> String {
        let m = Int(seconds) / 60
        let s = Int(seconds) % 60
        return String(format: "%d min %d sec", m, s)
    }
}

#Preview {
    NavigationStack {
        WalkDetailView(walk: Walk(
            startTime: Date().addingTimeInterval(-600),
            endTime: Date(),
            distanceMeters: 0,
            events: [
                WalkEvent(type: .pee, timestamp: Date().addingTimeInterval(-400)),
                WalkEvent(type: .poop, timestamp: Date().addingTimeInterval(-200))
            ]
        ))
    }
}

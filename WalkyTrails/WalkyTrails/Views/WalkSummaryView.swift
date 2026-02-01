//
//  WalkSummaryView.swift
//  WalkyTrails
//

import SwiftUI

struct WalkSummaryView: View {
    @ObservedObject var store: WalkStore

    private var walk: Walk? { store.walkToSummarize }

    var body: some View {
        Group {
            if let w = walk {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Walk summary")
                        .font(.title2)
                        .fontWeight(.semibold)
                    HStack {
                        Label(formattedDuration(w.durationSeconds), systemImage: "clock")
                        Spacer()
                    }
                    if w.distanceMeters > 0 {
                        HStack {
                            Label(String(format: "%.2f km", w.distanceMeters / 1000), systemImage: "location")
                            Spacer()
                        }
                    }
                    if !w.events.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Events")
                                .font(.headline)
                            ForEach(w.events) { event in
                                HStack {
                                    Image(systemName: event.type == .pee ? "drop" : "leaf")
                                    Text(event.type.rawValue.capitalized)
                                    Spacer()
                                    Text(event.timestamp, style: .time)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    Spacer()
                    HStack(spacing: 16) {
                        Button("Discard") {
                            store.discardWalk()
                        }
                        .buttonStyle(.bordered)
                        Button("Save") {
                            store.saveWalk()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding()
            } else {
                Text("No summary")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func formattedDuration(_ seconds: TimeInterval) -> String {
        let m = Int(seconds) / 60
        let s = Int(seconds) % 60
        return String(format: "%d min %d sec", m, s)
    }
}

#Preview {
    WalkSummaryView(store: {
        let s = WalkStore()
        s.walkToSummarize = Walk(
            startTime: Date().addingTimeInterval(-600),
            endTime: Date(),
            distanceMeters: 0,
            events: [WalkEvent(type: .pee), WalkEvent(type: .poop)]
        )
        return s
    }())
}

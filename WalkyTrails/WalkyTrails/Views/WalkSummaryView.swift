//
//  WalkSummaryView.swift
//  WalkyTrails
//

import SwiftUI

struct WalkSummaryView: View {
    @ObservedObject var store: WalkStore
    @ObservedObject var settings: SettingsStore
    @State private var notesText = ""

    private var walk: Walk? { store.walkToSummarize }

    var body: some View {
        Group {
            if let w = walk {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Walk summary")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .accessibilityAddTraits(.isHeader)
                    HStack {
                        Label(formattedDuration(w.durationSeconds), systemImage: "clock")
                        Spacer()
                    }
                    if w.distanceMeters > 0 {
                        HStack {
                            Label(settings.formattedDistance(w.distanceMeters), systemImage: "location")
                            Spacer()
                        }
                    }
                    if !w.events.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Events")
                                .font(.headline)
                            ForEach(w.events) { event in
                                HStack {
                                    Image(systemName: eventIcon(for: event.type))
                                        .foregroundStyle(eventColor(for: event.type))
                                    Text(event.type.rawValue.capitalized)
                                    Spacer()
                                    Text(event.timestamp, style: .time)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Notes (optional)")
                            .font(.headline)
                        TextField("e.g. Sunny, met a friend", text: $notesText, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(2...5)
                            .onChange(of: notesText) { _, new in store.setNotesForWalkToSummarize(new) }
                    }
                    .onAppear { notesText = w.notes ?? "" }
                    Spacer()
                    HStack(spacing: 16) {
                        Button("Discard") {
                            store.discardWalk()
                        }
                        .buttonStyle(.bordered)
                        .accessibilityLabel("Discard walk")
                        .accessibilityHint("Deletes this walk without saving")
                        Button("Save") {
                            store.saveWalk()
                        }
                        .buttonStyle(.borderedProminent)
                        .accessibilityLabel("Save walk")
                        .accessibilityHint("Saves walk to history")
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

    private func eventIcon(for type: WalkEvent.EventType) -> String {
        switch type {
        case .pee: return "drop.fill"
        case .poop: return "leaf.fill"
        case .water: return "cup.and.saucer.fill"
        case .play: return "tennisball.fill"
        }
    }

    private func eventColor(for type: WalkEvent.EventType) -> Color {
        switch type {
        case .pee: return .blue
        case .poop: return .brown
        case .water: return .cyan
        case .play: return .orange
        }
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
    }(), settings: SettingsStore())
}

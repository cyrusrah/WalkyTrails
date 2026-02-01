//
//  WalkSummaryView.swift
//  WalkyTrails
//

import SwiftUI

struct WalkSummaryView: View {
    @ObservedObject var store: WalkStore
    @ObservedObject var settings: SettingsStore
    @ObservedObject var dogStore: DogProfileStore
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var weatherService: WeatherService
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
                    if !dogsSummaryText(w).isEmpty {
                        HStack {
                            Label(dogsSummaryText(w), systemImage: "dog")
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                    }
                    if let weather = weatherService.currentWeather {
                        HStack(spacing: 8) {
                            Image(systemName: "cloud.sun")
                                .foregroundStyle(.secondary)
                            Text(settings.formattedTemperature(celsius: weather.temperatureCelsius) + " · " + weather.conditionDescription)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        if let suggestion = weatherService.suggestion {
                            Text(suggestion.message)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else if let saved = w.savedWeather {
                        HStack(spacing: 8) {
                            Image(systemName: "cloud.sun")
                                .foregroundStyle(.secondary)
                            Text(settings.formattedTemperature(celsius: saved.temperatureCelsius) + " · " + saved.conditionDescription)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
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
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(event.type.rawValue.capitalized)
                                        if let label = eventLabel(for: event, walk: w) {
                                            Text(label)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
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
                    .onAppear {
                        notesText = w.notes ?? ""
                        if let loc = locationManager.currentLocation {
                            weatherService.load(latitude: loc.coordinate.latitude, longitude: loc.coordinate.longitude, temperatureUnit: settings.temperatureUnitApi)
                        }
                    }
                    Spacer()
                    HStack(spacing: 16) {
                        Button("Discard") {
                            store.discardWalk()
                        }
                        .buttonStyle(.bordered)
                        .accessibilityLabel("Discard walk")
                        .accessibilityHint("Deletes this walk without saving")
                        Button("Save") {
                            store.saveWalk(weather: weatherService.currentWeatherForSave)
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
    }(), settings: SettingsStore(), dogStore: DogProfileStore(), locationManager: LocationManager(), weatherService: WeatherService())
}

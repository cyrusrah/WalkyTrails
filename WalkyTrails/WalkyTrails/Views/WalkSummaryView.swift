//
//  WalkSummaryView.swift
//  WalkyTrails
//

import CoreLocation
import SwiftUI

struct WalkSummaryView: View {
    @ObservedObject var store: WalkStore
    @ObservedObject var settings: SettingsStore
    @ObservedObject var dogStore: DogProfileStore
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var weatherService: WeatherService
    @State private var notesText = ""

    private var walk: Walk? { store.walkToSummarize }

    @ViewBuilder
    private var weatherRow: some View {
        if weatherService.isLoading {
            HStack(spacing: 8) {
                ProgressView()
                Text("Weather…")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        } else if let w = weatherService.currentWeather {
            HStack(spacing: 8) {
                Image(systemName: weatherIcon(for: w.weatherCode))
                    .font(.title3)
                    .foregroundStyle(.secondary)
                Text(settings.formattedTemperature(celsius: w.temperatureCelsius))
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(w.conditionDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Weather: \(w.conditionDescription), \(settings.formattedTemperature(celsius: w.temperatureCelsius))")
            if let suggestion = WeatherSuggestion.suggestion(for: w) {
                Text(suggestion)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func weatherIcon(for code: Int) -> String {
        switch code {
        case 0: return "sun.max.fill"
        case 1, 2, 3: return "cloud.sun.fill"
        case 45, 48: return "cloud.fog.fill"
        case 51...67: return "cloud.drizzle.fill"
        case 71...77: return "cloud.snow.fill"
        case 80...82: return "cloud.rain.fill"
        case 85, 86: return "cloud.snow.fill"
        case 95...99: return "cloud.bolt.rain.fill"
        default: return "cloud.fill"
        }
    }

    private func loadWeatherIfNeeded(coord: CLLocationCoordinate2D) {
#if DEBUG
        if let mock = WeatherService.mockSnapshot(debugModeRaw: settings.weatherDebugMode.rawValue) {
            weatherService.setOverride(mock)
            return
        }
#endif
        weatherService.clearOverride()
        weatherService.load(latitude: coord.latitude, longitude: coord.longitude, temperatureUnit: settings.temperatureUnitApi)
    }

    private func dogNames(for walk: Walk) -> String {
        let names = walk.dogIds.compactMap { dogStore.dog(byId: $0)?.name }.filter { !$0.isEmpty }
        let missingCount = walk.dogIds.count - names.count
        if !names.isEmpty {
            let part = names.joined(separator: ", ")
            if missingCount > 0 {
                let suffix = missingCount == 1 ? "1 dog (no longer in profile)" : "\(missingCount) dogs (no longer in profile)"
                return "\(part), \(suffix)"
            }
            return part
        }
        if walk.dogIds.isEmpty { return "No dog" }
        return walk.dogIds.count == 1 ? "1 dog (no longer in profile)" : "\(walk.dogIds.count) dogs (no longer in profile)"
    }

    var body: some View {
        Group {
            if let w = walk {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Walk summary")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .accessibilityAddTraits(.isHeader)
                    weatherRow
                    HStack {
                        Label(formattedDuration(w.durationSeconds), systemImage: "clock")
                        Spacer()
                    }
                    if !w.dogIds.isEmpty {
                        HStack {
                            Label(dogNames(for: w), systemImage: "pawprint")
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
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
                                HStack(spacing: 10) {
                                    if w.dogIds.count > 1, let dogId = event.dogId, let dogColor = DogColors.color(for: dogId, in: w.dogIds) {
                                        Circle()
                                            .fill(dogColor)
                                            .frame(width: 8, height: 8)
                                    }
                                    Image(systemName: eventIcon(for: event.type))
                                        .foregroundStyle(eventColor(for: event.type))
                                    Text(eventLabel(for: event))
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
#if DEBUG
                        if let mock = WeatherService.mockSnapshot(debugModeRaw: settings.weatherDebugMode.rawValue) {
                            weatherService.setOverride(mock)
                        } else if let coord = locationManager.currentLocation?.coordinate {
                            loadWeatherIfNeeded(coord: coord)
                        }
#else
                        if let coord = locationManager.currentLocation?.coordinate {
                            loadWeatherIfNeeded(coord: coord)
                        }
#endif
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
                            let weather = weatherService.currentWeather.map {
                                SavedWeather(temperatureCelsius: $0.temperatureCelsius, conditionDescription: $0.conditionDescription, weatherCode: $0.weatherCode)
                            }
                            store.saveWalk(weather: weather)
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

    private func eventLabel(for event: WalkEvent) -> String {
        let typeStr = event.type.rawValue.capitalized
        guard let id = event.dogId else { return typeStr }
        guard let name = dogStore.dog(byId: id)?.name, !name.isEmpty else { return "\(typeStr) (no longer in profile)" }
        return "\(typeStr) (\(name))"
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

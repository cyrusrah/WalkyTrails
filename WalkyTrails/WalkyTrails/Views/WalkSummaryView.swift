//
//  WalkSummaryView.swift
//  WalkyTrails
//

import CoreLocation
import SwiftUI

struct WalkSummaryView: View {
    @EnvironmentObject var store: WalkStore
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var dogStore: DogProfileStore
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var weatherService: WeatherService
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
            WeatherDisplayView(
                temperatureCelsius: w.temperatureCelsius,
                conditionDescription: w.conditionDescription,
                suggestionMessage: WeatherSuggestion.suggestion(for: w),
                settings: settings
            )
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
                        Label(formattedDuration(seconds: w.durationSeconds), systemImage: "clock")
                        Spacer()
                    }
                    if !w.dogIds.isEmpty {
                        HStack {
                            Label(dogsSummaryText(walk: w, dogStore: dogStore), systemImage: "pawprint")
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
                                    Image(systemName: event.type.iconName)
                                        .foregroundStyle(event.type.displayColor)
                                    Text(eventListLabel(for: event))
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

    private func eventListLabel(for event: WalkEvent) -> String {
        let typeStr = event.type.rawValue.capitalized
        guard let label = eventLabel(event: event, dogStore: dogStore) else { return typeStr }
        return "\(typeStr) (\(label))"
    }
}

#Preview {
    WalkSummaryView()
        .environmentObject({
        let s = WalkStore()
        s.walkToSummarize = Walk(
            startTime: Date().addingTimeInterval(-600),
            endTime: Date(),
            distanceMeters: 0,
            events: [WalkEvent(type: .pee), WalkEvent(type: .poop)]
        )
        return s
        }())
        .environmentObject(SettingsStore())
        .environmentObject(DogProfileStore())
        .environmentObject(LocationManager())
        .environmentObject(WeatherService())
}

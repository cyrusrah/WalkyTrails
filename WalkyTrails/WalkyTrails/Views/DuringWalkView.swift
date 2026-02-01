//
//  DuringWalkView.swift
//  WalkyTrails
//

import AppIntents
import CoreLocation
import MapKit
import SwiftUI

struct DuringWalkView: View {
    @ObservedObject var store: WalkStore
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var settings: SettingsStore
    @ObservedObject var dogStore: DogProfileStore
    @ObservedObject var weatherService: WeatherService
    /// When multiple dogs on walk, which dog we're logging for. Nil = single dog (use walk.dogIds.first).
    @State private var selectedDogIdForLogging: UUID?

    private var currentWalk: Walk? { store.currentWalk }

    @ViewBuilder
    private var weatherRow: some View {
        if weatherService.isLoading {
            HStack(spacing: 8) {
                ProgressView()
                Text("Weather…")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Loading weather")
        } else if let w = weatherService.currentWeather {
            VStack(spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: weatherIcon(for: w.weatherCode))
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text(settings.formattedTemperature(celsius: w.temperatureCelsius))
                        .font(.title3)
                        .fontWeight(.medium)
                    Text(w.conditionDescription)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Weather: \(w.conditionDescription), \(settings.formattedTemperature(celsius: w.temperatureCelsius))")
                if let suggestion = WeatherSuggestion.suggestion(for: w) {
                    Text(suggestion)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .accessibilityLabel("Suggestion: \(suggestion)")
                }
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

    var body: some View {
        VStack(spacing: 0) {
            if let walk = currentWalk {
                walkMap(walk: walk)
                walkControls(walk: walk)
            }
        }
        .onChange(of: currentWalk?.id) { _, _ in
            if let walk = currentWalk, !walk.dogIds.isEmpty {
                selectedDogIdForLogging = walk.dogIds.first
            } else {
                selectedDogIdForLogging = nil
            }
        }
        .onAppear {
            if let walk = currentWalk, selectedDogIdForLogging == nil, !walk.dogIds.isEmpty {
                selectedDogIdForLogging = walk.dogIds.first
            }
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
        .onChange(of: locationManager.currentLocation?.coordinate.latitude) { _, _ in
            if let coord = locationManager.currentLocation?.coordinate {
                loadWeatherIfNeeded(coord: coord)
            }
        }
        .onChange(of: locationManager.distanceMeters) { _, newDistance in
            store.updateCurrentWalkDistance(newDistance)
        }
    }

    @ViewBuilder
    private func walkMap(walk: Walk) -> some View {
        Map(initialPosition: .userLocation(fallback: .automatic)) {
            UserAnnotation()
            if !locationManager.routeCoordinates.isEmpty {
                MapPolyline(coordinates: locationManager.routeCoordinates)
                    .stroke(.tint, lineWidth: 4)
            }
            ForEach(walk.events.filter { $0.coordinate != nil }, id: \.id) { event in
                if let coord = event.coordinate {
                    Annotation("", coordinate: CLLocationCoordinate2D(latitude: coord.latitude, longitude: coord.longitude)) {
                        eventMarker(event: event, walk: walk)
                    }
                }
            }
        }
        .mapStyle(settings.mapStylePreference.mapStyle)
        .frame(height: 220)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Walk map showing route and event markers")
        .accessibilityHint("Shows your current path and where you logged pee, poop, water, or play")
    }

    @ViewBuilder
    private func walkControls(walk: Walk) -> some View {
        VStack(spacing: 16) {
            weatherRow
            Text("Walk in progress")
                .font(.headline)
                .foregroundStyle(.secondary)
                .accessibilityAddTraits(.isHeader)
            TimelineView(.periodic(from: .now, by: 1)) { context in
                Text(formattedDuration(walk.startTime, now: context.date))
                    .font(.system(.largeTitle, design: .monospaced))
                    .contentTransition(.numericText())
                    .accessibilityLabel("Elapsed time")
                    .accessibilityValue(formattedDuration(walk.startTime, now: context.date))
            }
            if locationManager.distanceMeters > 0 {
                Text(settings.formattedDistance(locationManager.distanceMeters))
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Distance walked")
                    .accessibilityValue(settings.formattedDistance(locationManager.distanceMeters))
            }
            if walk.dogIds.count > 1 {
                currentDogBar(walk: walk)
            }
            eventButtons(walk: walk)
            Spacer(minLength: 8)
            endWalkButton
        }
        .padding()
    }

    private func effectiveDogId(for walk: Walk) -> UUID? {
        if walk.dogIds.count == 1 { return walk.dogIds.first }
        return selectedDogIdForLogging
    }

    @ViewBuilder
    private func currentDogBar(walk: Walk) -> some View {
        Picker("Logging for", selection: $selectedDogIdForLogging) {
            ForEach(walk.dogIds, id: \.self) { id in
                Text(dogStore.dog(byId: id)?.name.isEmpty == false ? dogStore.dog(byId: id)!.name : "Unnamed")
                    .tag(Optional(id))
            }
        }
        .pickerStyle(.segmented)
        .onAppear {
            if selectedDogIdForLogging == nil || !walk.dogIds.contains(selectedDogIdForLogging!) {
                selectedDogIdForLogging = walk.dogIds.first
            }
        }
        .accessibilityLabel("Who you’re logging events for")
    }

    private func eventButtons(walk: Walk) -> some View {
        let dogId = effectiveDogId(for: walk)
        return HStack(spacing: 12) {
            Button {
                store.addEventToCurrentWalk(.pee, at: locationManager.currentLocation?.coordinate, dogId: dogId)
                LogPeeIntent().donate()
            } label: { Label("Pee", systemImage: "drop") }
            .buttonStyle(.bordered)
            .accessibilityLabel("Log pee")
            .accessibilityHint("Records a pee event at current location")
            Button {
                store.addEventToCurrentWalk(.poop, at: locationManager.currentLocation?.coordinate, dogId: dogId)
                LogPoopIntent().donate()
            } label: { Label("Poop", systemImage: "leaf") }
            .buttonStyle(.bordered)
            .accessibilityLabel("Log poop")
            .accessibilityHint("Records a poop event at current location")
            Button {
                store.addEventToCurrentWalk(.water, at: locationManager.currentLocation?.coordinate, dogId: dogId)
                LogWaterIntent().donate()
            } label: { Label("Water", systemImage: "cup.and.saucer") }
            .buttonStyle(.bordered)
            .accessibilityLabel("Log water")
            .accessibilityHint("Records a water break at current location")
            Button {
                store.addEventToCurrentWalk(.play, at: locationManager.currentLocation?.coordinate, dogId: dogId)
                LogPlayIntent().donate()
            } label: { Label("Play", systemImage: "tennisball") }
            .buttonStyle(.bordered)
            .accessibilityLabel("Log play")
            .accessibilityHint("Records a play event at current location")
        }
    }

    private var endWalkButton: some View {
        Button(role: .destructive) {
            store.updateCurrentWalkDistance(locationManager.distanceMeters)
            store.endWalk(withRoute: locationManager.routeCoordinates)
        } label: {
            Label("End Walk", systemImage: "stop.circle.fill")
                .font(.title3)
                .frame(maxWidth: .infinity)
                .padding()
        }
        .buttonStyle(.borderedProminent)
        .padding(.horizontal)
        .accessibilityLabel("End walk")
        .accessibilityHint("Stops the walk and shows summary to save or discard")
    }

    @ViewBuilder
    private func eventMarker(event: WalkEvent, walk: Walk) -> some View {
        ZStack {
            if walk.dogIds.count > 1, let dogId = (event.dogId ?? walk.dogIds.first), let ringColor = DogColors.color(for: dogId, in: walk.dogIds) {
                Circle()
                    .stroke(ringColor, lineWidth: 3)
                    .frame(width: 44, height: 44)
            }
            Image(systemName: eventIcon(for: event.type))
                .font(.title2)
                .foregroundStyle(eventColor(for: event.type))
                .padding(8)
                .background(.background, in: Circle())
                .shadow(radius: 2)
        }
        .accessibilityHidden(true)
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
    }(), locationManager: LocationManager(), settings: SettingsStore(), dogStore: DogProfileStore(), weatherService: WeatherService())
}

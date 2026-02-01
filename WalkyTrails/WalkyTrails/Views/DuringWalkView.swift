//
//  DuringWalkView.swift
//  WalkyTrails
//

import AppIntents
import CoreLocation
import MapKit
import SwiftUI

struct DuringWalkView: View {
    @EnvironmentObject var store: WalkStore
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var dogStore: DogProfileStore
    @EnvironmentObject var weatherService: WeatherService
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
            WeatherDisplayView(
                temperatureCelsius: w.temperatureCelsius,
                conditionDescription: w.conditionDescription,
                suggestionMessage: WeatherSuggestion.suggestion(for: w),
                settings: settings
            )
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
        WalkMapView(
            routeCoordinates: locationManager.routeCoordinates,
            events: walk.events,
            dogIds: walk.dogIds,
            mapStyle: settings.mapStylePreference.mapStyle,
            height: 220,
            showUserLocation: true
        )
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
                Text(formattedElapsed(from: walk.startTime, now: context.date))
                    .font(.system(.largeTitle, design: .monospaced))
                    .contentTransition(.numericText())
                    .accessibilityLabel("Elapsed time")
                    .accessibilityValue(formattedElapsed(from: walk.startTime, now: context.date))
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

}

#Preview {
    DuringWalkView()
        .environmentObject({
            let s = WalkStore()
            s.startWalk()
            return s
        }())
        .environmentObject(LocationManager())
        .environmentObject(SettingsStore())
        .environmentObject(DogProfileStore())
        .environmentObject(WeatherService())
}

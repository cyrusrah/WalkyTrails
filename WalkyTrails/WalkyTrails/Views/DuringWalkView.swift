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
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)

    private var currentWalk: Walk? { store.currentWalk }
    private let statsBarHeight: CGFloat = 112

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
        GeometryReader { proxy in
            let safeTop = proxy.safeAreaInsets.top
            let safeBottom = proxy.safeAreaInsets.bottom

            ZStack {
                WTTheme.ColorToken.warmGrey.ignoresSafeArea()

                if let walk = currentWalk {
                    walkMap(walk: walk, safeTop: safeTop)
                        .ignoresSafeArea()

                    // Top overlay: stats + chips (does not affect map size)
                    VStack(spacing: 0) {
                        topStatsBar(walk: walk)
                            .padding(.horizontal, WTTheme.Spacing.lg)
                            .padding(.top, safeTop + 6)

                        chipsRow
                            .padding(.horizontal, WTTheme.Spacing.lg)
                            .padding(.top, 8)

                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                    // Bottom overlay: actions + End Walk (does not affect map size)
                    bottomActions(walk: walk)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                        .padding(.bottom, safeBottom + 104)
                }
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

    private func walkMap(walk: Walk, safeTop: CGFloat) -> some View {
        let dogId = walk.dogIds.first
        let photoData = dogId.flatMap { dogStore.dog(byId: $0)?.photoData }
        let marker: WalkMapView.UserMarker? = {
            guard let coord = locationManager.currentLocation?.coordinate else { return nil }
            return WalkMapView.UserMarker(coordinate: coord, photoData: photoData)
        }()

        return WalkMapView(
            routeCoordinates: locationManager.routeCoordinates,
            plannedRouteCoordinates: walk.plannedRouteForMap.map {
                CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
            },
            events: walk.events,
            dogIds: walk.dogIds,
            mapStyle: settings.mapStylePreference.mapStyle,
            height: UIScreen.main.bounds.height,
            showUserLocation: marker == nil,
            userMarker: marker,
            position: $cameraPosition
        )
        .overlay(alignment: .trailing) {
            VStack(spacing: 10) {
                // Keep same order/placement as Home: layers, then center.
                mapFab(systemImage: "square.3.layers.3d") { cycleMapStyle() }
                mapFab(systemImage: "location.fill") { cameraPosition = .userLocation(fallback: .automatic) }
            }
            .padding(.trailing, WTTheme.Spacing.lg)
            .padding(.top, safeTop + statsBarHeight + 92)
        }
    }

    private func topStatsBar(walk: Walk) -> some View {
        HStack(spacing: 0) {
            statColumn(title: "TIME") {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    Text(formattedElapsed(from: walk.startTime, now: context.date))
                        .font(.system(.title, design: .default).weight(.bold))
                        .foregroundStyle(WTTheme.ColorToken.charcoal)
                        .contentTransition(.numericText())
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
            }
            Divider().overlay(WTTheme.ColorToken.stone)
            statColumn(title: "DISTANCE") {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(distanceForHeader.value)
                        .font(.system(.title, design: .default).weight(.bold))
                        .foregroundStyle(WTTheme.ColorToken.charcoal)
                    Text(distanceForHeader.unit)
                        .font(.system(.callout, design: .default).weight(.semibold))
                        .foregroundStyle(WTTheme.ColorToken.mutedText)
                }
                .lineLimit(1)
                .minimumScaleFactor(0.85)
            }
            Divider().overlay(WTTheme.ColorToken.stone)
            statColumn(title: "PACE") {
                VStack(spacing: 2) {
                    Text(paceForHeader.value)
                        .font(.system(.title, design: .default).weight(.bold))
                        .foregroundStyle(WTTheme.ColorToken.charcoal)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                    Text(paceForHeader.unit)
                        .font(.system(.caption, design: .default).weight(.semibold))
                        .foregroundStyle(WTTheme.ColorToken.mutedText)
                        .lineLimit(1)
                }
            }
        }
        .frame(height: statsBarHeight)
        .background(
            RoundedRectangle(cornerRadius: WTTheme.Radius.md, style: .continuous)
                .fill(.white)
                .overlay(
                    RoundedRectangle(cornerRadius: WTTheme.Radius.md, style: .continuous)
                        .stroke(WTTheme.ColorToken.stone, lineWidth: WTTheme.Stroke.hairline)
                )
                .shadow(color: .black.opacity(WTTheme.Shadow.opacity), radius: 18, x: 0, y: 8)
        )
    }

    private var chipsRow: some View {
        HStack(alignment: .center, spacing: 10) {
            chip(text: "GPS", systemImage: "location.fill", showsStatusDot: true)
            if let w = weatherService.currentWeather {
                chip(text: settings.formattedTemperature(celsius: w.temperatureCelsius), systemImage: "cloud.sun")
            }
            Spacer(minLength: 0)
            mapFab(systemImage: "music.note") {
                // Placeholder (future: navigation voice/commands)
            }
        }
    }

    private func bottomActions(walk: Walk) -> some View {
        VStack(spacing: WTTheme.Spacing.md) {
            HStack(spacing: 18) {
                bathroomMenuButton(walk: walk)
                circleActionButton(title: "Photo", systemImage: "camera") {
                    // Placeholder for photo capture later
                }
                circleActionButton(title: "Marker", systemImage: "flag") {
                    // Placeholder for future marker types
                }
            }
            .padding(.top, WTTheme.Spacing.sm)

            endWalkButton
                .padding(.horizontal, WTTheme.Spacing.lg)
        }
        .padding(.top, 14)
        .background(
            LinearGradient(
                colors: [
                    WTTheme.ColorToken.warmGrey.opacity(0),
                    WTTheme.ColorToken.warmGrey.opacity(0.92),
                    WTTheme.ColorToken.warmGrey
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .bottom)
        )
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
        return HStack(spacing: 10) {
            Button {
                store.addEventToCurrentWalk(.pee, at: locationManager.currentLocation?.coordinate, dogId: dogId)
                LogPeeIntent().donate()
            } label: { Label("Pee", systemImage: "drop") }
            .wtButton(.secondary, size: .small, fullWidth: false)
            .accessibilityLabel("Log pee")
            .accessibilityHint("Records a pee event at current location")
            Button {
                store.addEventToCurrentWalk(.poop, at: locationManager.currentLocation?.coordinate, dogId: dogId)
                LogPoopIntent().donate()
            } label: { Label("Poop", systemImage: "leaf") }
            .wtButton(.secondary, size: .small, fullWidth: false)
            .accessibilityLabel("Log poop")
            .accessibilityHint("Records a poop event at current location")
            Button {
                store.addEventToCurrentWalk(.water, at: locationManager.currentLocation?.coordinate, dogId: dogId)
                LogWaterIntent().donate()
            } label: { Label("Water", systemImage: "cup.and.saucer") }
            .wtButton(.secondary, size: .small, fullWidth: false)
            .accessibilityLabel("Log water")
            .accessibilityHint("Records a water break at current location")
            Button {
                store.addEventToCurrentWalk(.play, at: locationManager.currentLocation?.coordinate, dogId: dogId)
                LogPlayIntent().donate()
            } label: { Label("Play", systemImage: "tennisball") }
            .wtButton(.secondary, size: .small, fullWidth: false)
            .accessibilityLabel("Log play")
            .accessibilityHint("Records a play event at current location")
        }
    }

    private var endWalkButton: some View {
        Button(role: .destructive) {
            store.updateCurrentWalkDistance(locationManager.distanceMeters)
            store.endWalk(withRoute: locationManager.routeCoordinates)
        } label: {
            Text("End Walk")
                .frame(maxWidth: .infinity)
        }
        .wtButton(.destructiveOutline, size: .large)
        .accessibilityLabel("End walk")
        .accessibilityHint("Stops the walk and shows summary to save or discard")
    }

    private func chip(text: String, systemImage: String, showsStatusDot: Bool = false) -> some View {
        HStack(spacing: 6) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: systemImage)
                    .imageScale(.small)

                if showsStatusDot {
                    Circle()
                        .fill(WTTheme.ColorToken.forest)
                        .frame(width: 7, height: 7)
                        .overlay(Circle().stroke(.white, lineWidth: 2))
                        .offset(x: 5, y: -4)
                        .accessibilityHidden(true)
                }
            }
            Text(text)
                .font(.system(.callout, design: .default).weight(.semibold))
        }
        .foregroundStyle(WTTheme.ColorToken.charcoal)
        .padding(.vertical, 9)
        .padding(.horizontal, 12)
        .background(
            Capsule(style: .continuous)
                .fill(.white)
                .overlay(Capsule(style: .continuous).stroke(WTTheme.ColorToken.stone, lineWidth: WTTheme.Stroke.hairline))
        )
    }

    private func statColumn(title: String, @ViewBuilder value: () -> some View) -> some View {
        VStack(alignment: .center, spacing: 8) {
            Text(title)
                .font(WTTheme.Typography.caption)
                .foregroundStyle(WTTheme.ColorToken.mutedText)
                .kerning(0.7)
            value()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 10)
        .padding(.bottom, 12)
        .padding(.horizontal, 12)
    }

    private var distanceForHeader: (value: String, unit: String) {
        let meters = locationManager.distanceMeters
        if meters <= 0 {
            return (value: "0.00", unit: settings.distanceUnit == .miles ? "mi" : "km")
        }
        switch settings.distanceUnit {
        case .kilometers:
            return (value: String(format: "%.2f", meters / 1000), unit: "km")
        case .miles:
            return (value: String(format: "%.2f", meters / 1609.344), unit: "mi")
        }
    }

    private var paceForHeader: (value: String, unit: String) {
        let meters = locationManager.distanceMeters
        let elapsed = max(Date().timeIntervalSince(store.currentWalk?.startTime ?? Date()), 1)
        guard meters > 1 else {
            return (value: "—", unit: settings.distanceUnit == .miles ? "min/mi" : "min/km")
        }
        let minutes = elapsed / 60.0
        switch settings.distanceUnit {
        case .kilometers:
            let km = meters / 1000.0
            let pace = minutes / max(km, 0.001)
            return (value: formatMinutes(pace), unit: "min/km")
        case .miles:
            let mi = meters / 1609.344
            let pace = minutes / max(mi, 0.001)
            return (value: formatMinutes(pace), unit: "min/mi")
        }
    }

    private func formatMinutes(_ value: Double) -> String {
        let totalSeconds = Int((value * 60).rounded())
        let m = totalSeconds / 60
        let s = totalSeconds % 60
        return String(format: "%d:%02d", m, s)
    }

    private func cycleMapStyle() {
        switch settings.mapStylePreference {
        case .standard: settings.mapStylePreference = .hybrid
        case .hybrid: settings.mapStylePreference = .imagery
        case .imagery: settings.mapStylePreference = .standard
        }
    }

    private func mapFab(systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(WTTheme.ColorToken.forest)
                .frame(width: 42, height: 42)
                .background(
                    Circle()
                        .fill(.white)
                        .overlay(Circle().stroke(WTTheme.ColorToken.stone, lineWidth: WTTheme.Stroke.hairline))
                        .shadow(color: .black.opacity(WTTheme.Shadow.opacity), radius: 12, x: 0, y: 6)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Map action")
    }

    private func circleActionButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(WTTheme.ColorToken.forest)
                    .frame(width: 70, height: 70)
                    .background(
                        Circle()
                            .fill(.white)
                            .overlay(Circle().stroke(WTTheme.ColorToken.stone, lineWidth: WTTheme.Stroke.hairline))
                    )
                Text(title)
                    .font(WTTheme.Typography.caption)
                    .foregroundStyle(WTTheme.ColorToken.mutedText)
            }
        }
        .buttonStyle(.plain)
    }

    private func bathroomMenuButton(walk: Walk) -> some View {
        let dogId = effectiveDogId(for: walk)
        return Menu {
            Button {
                store.addEventToCurrentWalk(.pee, at: locationManager.currentLocation?.coordinate, dogId: dogId)
                LogPeeIntent().donate()
            } label: { Label("Pee", systemImage: "drop") }
            Button {
                store.addEventToCurrentWalk(.poop, at: locationManager.currentLocation?.coordinate, dogId: dogId)
                LogPoopIntent().donate()
            } label: { Label("Poop", systemImage: "leaf") }
            Button {
                store.addEventToCurrentWalk(.water, at: locationManager.currentLocation?.coordinate, dogId: dogId)
                LogWaterIntent().donate()
            } label: { Label("Water", systemImage: "cup.and.saucer") }
            Button {
                store.addEventToCurrentWalk(.play, at: locationManager.currentLocation?.coordinate, dogId: dogId)
                LogPlayIntent().donate()
            } label: { Label("Play", systemImage: "tennisball") }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: "toilet")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(WTTheme.ColorToken.forest)
                    .frame(width: 70, height: 70)
                    .background(
                        Circle()
                            .fill(.white)
                            .overlay(Circle().stroke(WTTheme.ColorToken.stone, lineWidth: WTTheme.Stroke.hairline))
                    )
                Text("Bathroom")
                    .font(WTTheme.Typography.caption)
                    .foregroundStyle(WTTheme.ColorToken.mutedText)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Bathroom")
        .accessibilityHint("Opens menu to log pee, poop, water, or play")
    }

    // Dog avatar now follows GPS as a map annotation (see `WalkMapView.userMarker`).

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

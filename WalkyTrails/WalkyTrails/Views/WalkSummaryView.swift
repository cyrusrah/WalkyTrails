//
//  WalkSummaryView.swift
//  WalkyTrails
//

import CoreLocation
import MapKit
import SwiftUI

struct WalkSummaryView: View {
    @EnvironmentObject var store: WalkStore
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var dogStore: DogProfileStore
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var weatherService: WeatherService
    @State private var isShowingShareSheet = false
    @State private var navigateToDogDashboard = false

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

    private var routeCoords: [CLLocationCoordinate2D] {
        guard let w = walk else { return [] }
        return w.routeForMap.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
    }

    private var mapPosition: MapCameraPosition {
        guard !routeCoords.isEmpty else { return .automatic }
        return .region(WalkMapView.regionFitting(coordinates: routeCoords))
    }

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                let safeTop = proxy.safeAreaInsets.top
                let safeBottom = proxy.safeAreaInsets.bottom

                ZStack {
                    WTTheme.ColorToken.warmGrey.ignoresSafeArea()

                    if let w = walk {
                        VStack(spacing: 12) {
                            headerSection(walk: w)
                                .padding(.top, safeTop + 6)
                                .padding(.horizontal, WTTheme.Spacing.lg)

                            mapSection(walk: w)
                                .padding(.horizontal, WTTheme.Spacing.lg)

                            statsStrip(walk: w)
                                .padding(.horizontal, WTTheme.Spacing.lg)

                            quickRows(walk: w)
                                .padding(.horizontal, WTTheme.Spacing.lg)

                            achievementCardPlaceholder
                                .padding(.horizontal, WTTheme.Spacing.lg)

                            Spacer(minLength: 0)

                            actionRow
                                .padding(.horizontal, WTTheme.Spacing.lg)
                                .padding(.bottom, safeBottom + 10)
                        }
                        .onAppear {
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
                    } else {
                        Text("No summary")
                            .foregroundStyle(WTTheme.ColorToken.mutedText)
                    }
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
            }
            .tint(WTTheme.ColorToken.brandOrange)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        store.discardWalk()
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .accessibilityLabel("Back")
                }

                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        isShowingShareSheet = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .accessibilityLabel("Share")
                    .accessibilityHint("Share your walk card (coming soon)")

                    Menu {
                        if walk?.dogIds.first != nil {
                            Button {
                                navigateToDogDashboard = true
                            } label: {
                                Label("View Profile", systemImage: "pawprint")
                            }
                        }
                        Button(role: .destructive) {
                            store.discardWalk()
                        } label: {
                            Label("Discard Walk", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                    .accessibilityLabel("More")
                }
            }
            .sheet(isPresented: $isShowingShareSheet) {
                ShareSheet(activityItems: [sharePlaceholderText])
            }
            .navigationDestination(isPresented: $navigateToDogDashboard) {
                if let id = walk?.dogIds.first {
                    DogDashboardView(dogId: id)
                } else {
                    Text("No dog")
                        .foregroundStyle(WTTheme.ColorToken.mutedText)
                }
            }
        }
    }

    // MARK: - Sections

    private func headerSection(walk: Walk) -> some View {
        let dogName = walk.dogIds.first.flatMap { dogStore.dog(byId: $0)?.name }.flatMap { $0.isEmpty ? nil : $0 }
        return VStack(spacing: 4) {
            HStack(spacing: 6) {
                Text(dogName.map { "Great walk, \($0)!" } ?? "Great walk!")
                    .font(.system(.title2, design: .default).weight(.bold))
                    .foregroundStyle(WTTheme.ColorToken.charcoal)
                    .accessibilityAddTraits(.isHeader)

                HStack(spacing: 4) {
                    Image(systemName: "pawprint.fill")
                    Image(systemName: "pawprint.fill")
                }
                .font(.system(.callout, design: .default).weight(.semibold))
                .foregroundStyle(WTTheme.ColorToken.mutedText)
                .accessibilityHidden(true)
            }

            Text("You both crushed it.")
                .font(WTTheme.Typography.callout)
                .foregroundStyle(WTTheme.ColorToken.mutedText)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private func mapSection(walk: Walk) -> some View {
        WTCard(padding: 0) {
            WalkMapView(
                routeCoordinates: routeCoords,
                plannedRouteCoordinates: [],
                events: walk.events,
                dogIds: walk.dogIds,
                mapStyle: settings.mapStylePreference.mapStyle,
                height: 210,
                showUserLocation: false,
                cameraPosition: mapPosition
            )
            .clipShape(RoundedRectangle(cornerRadius: WTTheme.Radius.md, style: .continuous))
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Walk route map")
        }
    }

    private func statsStrip(walk: Walk) -> some View {
        WTCard {
            HStack(spacing: 0) {
                let dist = distanceForHeader(meters: walk.distanceMeters)
                statBlock(title: "DISTANCE", value: dist.value, unit: dist.unit)
                Divider().overlay(WTTheme.ColorToken.stone)
                statBlock(title: "TIME", value: formattedTimeMMSS(seconds: Int(walk.durationSeconds)), unit: nil)
                Divider().overlay(WTTheme.ColorToken.stone)
                statBlock(title: "BREAKS", value: "\(bathroomBreakCount(walk: walk))", unit: nil)
            }
            .padding(.vertical, 2)
        }
    }

    private func quickRows(walk: Walk) -> some View {
        WTCard {
            VStack(alignment: .leading, spacing: WTTheme.Spacing.sm) {
                quickStatRow(
                    icon: "drop",
                    title: "Bathroom Breaks",
                    value: "\(bathroomBreakCount(walk: walk))"
                )
                Divider().overlay(WTTheme.ColorToken.stone)
                quickStatRow(
                    icon: "location",
                    title: "New Places Explored",
                    value: "—"
                )
                Divider().overlay(WTTheme.ColorToken.stone)
                quickStatRow(
                    icon: "gauge.with.dots.needle.67percent",
                    title: "Avg Pace",
                    value: averagePaceText(walk: walk)
                )
            }
        }
    }

    private var achievementCardPlaceholder: some View {
        WTCard {
            HStack(spacing: 12) {
                Circle()
                    .fill(WTTheme.ColorToken.brandOrange.opacity(0.14))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "rosette")
                            .foregroundStyle(WTTheme.ColorToken.brandOrange)
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text("Trail Explorer")
                        .font(WTTheme.Typography.callout.weight(.semibold))
                        .foregroundStyle(WTTheme.ColorToken.charcoal)
                    Text("You explored 3 new places today.")
                        .font(WTTheme.Typography.caption)
                        .foregroundStyle(WTTheme.ColorToken.mutedText)
                }
                Spacer()
            }
        }
        .accessibilityLabel("Achievement")
        .accessibilityHint("Achievements are coming soon")
    }

    private var actionRow: some View {
        HStack(spacing: WTTheme.Spacing.sm) {
            Button("Save Walk") {
                let weather = weatherService.currentWeather.map {
                    SavedWeather(temperatureCelsius: $0.temperatureCelsius, conditionDescription: $0.conditionDescription, weatherCode: $0.weatherCode)
                }
                store.saveWalk(weather: weather)
            }
            .wtButton(.secondary, size: .large)
            .accessibilityLabel("Save walk")
            .accessibilityHint("Saves walk to history")

            Button("Share") {
                isShowingShareSheet = true
            }
            .wtButton(.primary, size: .large)
            .accessibilityLabel("Share walk")
            .accessibilityHint("Share your walk card (coming soon)")
        }
        .padding(.top, WTTheme.Spacing.xs)
    }

    // MARK: - Components

    private func statBlock(title: String, value: String, unit: String?) -> some View {
        VStack(alignment: .center, spacing: 4) {
            Text(title)
                .font(WTTheme.Typography.caption)
                .foregroundStyle(WTTheme.ColorToken.mutedText)
                .kerning(0.7)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(value)
                    .font(.system(.title3, design: .default).weight(.bold))
                    .foregroundStyle(WTTheme.ColorToken.charcoal)
                if let unit {
                    Text(unit)
                        .font(.system(.callout, design: .default).weight(.semibold))
                        .foregroundStyle(WTTheme.ColorToken.mutedText)
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
    }

    private func quickStatRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(WTTheme.ColorToken.mutedText)
                .frame(width: 22)
            Text(title)
                .foregroundStyle(WTTheme.ColorToken.charcoal)
            Spacer()
            Text(value)
                .foregroundStyle(WTTheme.ColorToken.mutedText)
        }
        .font(WTTheme.Typography.callout)
    }

    private func summaryMetric(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(WTTheme.ColorToken.mutedText)
            VStack(alignment: .leading, spacing: 2) {
                Text(title.uppercased())
                    .font(WTTheme.Typography.caption)
                    .foregroundStyle(WTTheme.ColorToken.mutedText)
                    .kerning(0.6)
                Text(value)
                    .font(.system(.title3, design: .default).weight(.bold))
                    .foregroundStyle(WTTheme.ColorToken.charcoal)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func eventListLabel(for event: WalkEvent) -> String {
        let typeStr = event.type.rawValue.capitalized
        guard let label = eventLabel(event: event, dogStore: dogStore) else { return typeStr }
        return "\(typeStr) (\(label))"
    }

    private func bathroomBreakCount(walk: Walk) -> Int {
        walk.events.filter { $0.type == .pee || $0.type == .poop }.count
    }

    private func averagePaceText(walk: Walk) -> String {
        guard walk.distanceMeters > 1, walk.durationSeconds > 0 else {
            return "— \(settings.distanceUnit == .miles ? "min/mi" : "min/km")"
        }
        let minutes = Double(walk.durationSeconds) / 60.0
        switch settings.distanceUnit {
        case .kilometers:
            let km = walk.distanceMeters / 1000.0
            return "\(formatMinutes(minutes / max(km, 0.001))) min/km"
        case .miles:
            let mi = walk.distanceMeters / 1609.344
            return "\(formatMinutes(minutes / max(mi, 0.001))) min/mi"
        }
    }

    private func formatMinutes(_ value: Double) -> String {
        let totalSeconds = Int((value * 60).rounded())
        let m = totalSeconds / 60
        let s = totalSeconds % 60
        return String(format: "%d:%02d", m, s)
    }

    private func formattedTimeMMSS(seconds: Int) -> String {
        let total = max(seconds, 0)
        let m = total / 60
        let s = total % 60
        return String(format: "%d:%02d", m, s)
    }

    private func distanceForHeader(meters: Double) -> (value: String, unit: String) {
        guard meters > 0 else {
            return (value: "0.00", unit: settings.distanceUnit == .miles ? "mi" : "km")
        }
        switch settings.distanceUnit {
        case .kilometers:
            return (value: String(format: "%.2f", meters / 1000), unit: "km")
        case .miles:
            return (value: String(format: "%.2f", meters / 1609.344), unit: "mi")
        }
    }

    private var sharePlaceholderText: String {
        "WalkyTrails – Share card coming soon."
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

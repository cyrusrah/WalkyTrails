//
//  WalkDetailView.swift
//  WalkyTrails
//

import CoreLocation
import MapKit
import SwiftUI

struct WalkDetailView: View {
    @EnvironmentObject var store: WalkStore
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var dogStore: DogProfileStore
    let walk: Walk
    @State private var isShowingEvents = false
    @State private var isShowingNotes = false

    private var routeCoords: [CLLocationCoordinate2D] {
        walk.routeForMap.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
    }

    private var plannedCoords: [CLLocationCoordinate2D] {
        walk.plannedRouteForMap.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
    }

    private var mapPosition: MapCameraPosition {
        let combined = routeCoords + plannedCoords
        if combined.isEmpty { return .automatic }
        return .region(WalkMapView.regionFitting(coordinates: combined))
    }

    var body: some View {
        GeometryReader { proxy in
            let safeBottom = proxy.safeAreaInsets.bottom

            ZStack {
                WTTheme.ColorToken.warmGrey.ignoresSafeArea()

                VStack(spacing: 12) {
                    if !routeCoords.isEmpty || !plannedCoords.isEmpty || walk.events.contains(where: { $0.coordinate != nil }) {
                        WTCard(padding: 0) {
                            WalkMapView(
                                routeCoordinates: routeCoords,
                                plannedRouteCoordinates: plannedCoords,
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
                        .padding(.horizontal, WTTheme.Spacing.lg)
                        .padding(.top, WTTheme.Spacing.md)
                    }

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
                    .padding(.horizontal, WTTheme.Spacing.lg)

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
                    .padding(.horizontal, WTTheme.Spacing.lg)

                    Spacer(minLength: 0)

                    HStack(spacing: WTTheme.Spacing.sm) {
                        Button("Done") { }
                            .wtButton(.secondary, size: .large)
                            .accessibilityLabel("Done")
                            .accessibilityHint("Returns to the previous screen")
                    }
                    .padding(.horizontal, WTTheme.Spacing.lg)
                    .padding(.bottom, safeBottom + 10)
                    .opacity(0) // keep spacing consistent with summary (buttons live elsewhere in history flow)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .background(WTTheme.ColorToken.warmGrey)
        .tint(WTTheme.ColorToken.brandOrange)
        .navigationTitle("Walk")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    if !walk.events.isEmpty {
                        Button {
                            isShowingEvents = true
                        } label: {
                            Label("View Events", systemImage: "list.bullet")
                        }
                    }

                    Button {
                        isShowingNotes = true
                    } label: {
                        Label("Notes", systemImage: "square.and.pencil")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                }
                .accessibilityLabel("More")
            }
        }
        .sheet(isPresented: $isShowingEvents) {
            eventsSheet
        }
        .sheet(isPresented: $isShowingNotes) {
            notesSheet
        }
    }

    private func eventListLabel(for event: WalkEvent) -> String {
        let typeStr = event.type.rawValue.capitalized
        guard let label = eventLabel(event: event, dogStore: dogStore) else { return typeStr }
        return "\(typeStr) (\(label))"
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

    private var eventsSheet: some View {
        NavigationStack {
            List {
                ForEach(walk.events) { event in
                    HStack(spacing: 10) {
                        if walk.dogIds.count > 1, let dogId = event.dogId, let dogColor = DogColors.color(for: dogId, in: walk.dogIds) {
                            Circle()
                                .fill(dogColor)
                                .frame(width: 8, height: 8)
                        }
                        Image(systemName: event.type.iconName)
                            .foregroundStyle(event.type.displayColor)
                        Text(eventListLabel(for: event))
                        Spacer()
                        Text(settings.formattedTime(event.timestamp))
                            .foregroundStyle(WTTheme.ColorToken.mutedText)
                    }
                }
            }
            .navigationTitle("Events")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { isShowingEvents = false }
                }
            }
        }
    }

    private var notesSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Add notes", text: Binding(
                        get: { walk.notes ?? "" },
                        set: { store.updateNotes(for: walk.id, notes: $0) }
                    ), axis: .vertical)
                    .lineLimit(2...6)
                }
            }
            .navigationTitle("Notes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { isShowingNotes = false }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        WalkDetailView(walk: Walk(
            startTime: Date().addingTimeInterval(-600),
            endTime: Date(),
            distanceMeters: 0,
            events: [
                WalkEvent(type: .pee, timestamp: Date().addingTimeInterval(-400), latitude: 37.78, longitude: -122.41),
                WalkEvent(type: .poop, timestamp: Date().addingTimeInterval(-200), latitude: 37.79, longitude: -122.42)
            ],
            routeCoordinates: [
                Coordinate(latitude: 37.77, longitude: -122.43),
                Coordinate(latitude: 37.78, longitude: -122.42),
                Coordinate(latitude: 37.79, longitude: -122.41)
            ]
        ))
        .environmentObject(WalkStore())
        .environmentObject(SettingsStore())
        .environmentObject(DogProfileStore())
    }
}

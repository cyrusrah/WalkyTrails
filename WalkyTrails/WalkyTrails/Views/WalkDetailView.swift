//
//  WalkDetailView.swift
//  WalkyTrails
//

import CoreLocation
import MapKit
import SwiftUI

struct WalkDetailView: View {
    @ObservedObject var store: WalkStore
    @ObservedObject var settings: SettingsStore
    @ObservedObject var dogStore: DogProfileStore
    let walk: Walk
    @State private var notesText: String = ""
    @State private var notesSaved = false
    @State private var showDeleteConfirmation = false

    private var walkDogNames: String {
        let names = walk.dogIds.compactMap { dogStore.dog(byId: $0)?.name }.filter { !$0.isEmpty }
        return names.joined(separator: ", ")
    }

    /// Summary text for the Dogs row: names if we have them, else "N dog(s) (no longer in profile)" so history isn't lost.
    private var dogsSummaryText: String {
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
        guard !walk.dogIds.isEmpty else { return "" }
        return walk.dogIds.count == 1 ? "1 dog (no longer in profile)" : "\(walk.dogIds.count) dogs (no longer in profile)"
    }

    private var routeCoords: [CLLocationCoordinate2D] {
        walk.routeForMap.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
    }

    private var mapPosition: MapCameraPosition {
        if routeCoords.isEmpty {
            return .automatic
        }
        let region = regionFitting(coordinates: routeCoords)
        return .region(region)
    }

    var body: some View {
        List {
            if !routeCoords.isEmpty || walk.events.contains(where: { $0.coordinate != nil }) {
                Section {
                    Map(initialPosition: mapPosition) {
                        if !routeCoords.isEmpty {
                            MapPolyline(coordinates: routeCoords)
                                .stroke(.tint, lineWidth: 4)
                        }
                        ForEach(walk.events.filter { $0.coordinate != nil }) { event in
                            if let coord = event.coordinate {
                                Annotation("", coordinate: CLLocationCoordinate2D(latitude: coord.latitude, longitude: coord.longitude)) {
                                    eventMarker(event: event)
                                }
                            }
                        }
                    }
                    .mapStyle(settings.mapStylePreference.mapStyle)
                    .frame(height: 200)
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Walk route map with event markers")
                }
            }

            Section {
                if let weather = walk.savedWeather {
                    HStack(spacing: 8) {
                        Image(systemName: weatherIcon(for: weather.weatherCode))
                            .foregroundStyle(.secondary)
                        Text(settings.formattedTemperature(celsius: weather.temperatureCelsius))
                            .fontWeight(.medium)
                        Text(weather.conditionDescription)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Weather: \(weather.conditionDescription), \(settings.formattedTemperature(celsius: weather.temperatureCelsius))")
                }
                Label(formattedDuration(walk.durationSeconds), systemImage: "clock")
                if walk.distanceMeters > 0 {
                    Label(settings.formattedDistance(walk.distanceMeters), systemImage: "location")
                }
                if !walk.dogIds.isEmpty {
                    Label(dogsSummaryText, systemImage: "pawprint")
                }
                Text(settings.formattedDate(walk.startTime))
                Text(settings.formattedTime(walk.startTime))
            } header: {
                Text("Summary")
            }

            Section {
                TextField("Add notes", text: $notesText, axis: .vertical)
                    .lineLimit(2...5)
                    .onChange(of: notesText) { _, new in
                        store.updateNotes(for: walk.id, notes: new)
                        notesSaved = true
                    }
                    .accessibilityLabel("Walk notes")
                    .accessibilityHint("Notes are saved automatically")
            } header: {
                Text("Notes")
            } footer: {
                if notesSaved { Text("Saved") .foregroundStyle(.secondary) }
            }

            if !walk.events.isEmpty {
                Section {
                    ForEach(walk.events) { event in
                        HStack(spacing: 10) {
                            if walk.dogIds.count > 1, let dogId = event.dogId, let dogColor = DogColors.color(for: dogId, in: walk.dogIds) {
                                Circle()
                                    .fill(dogColor)
                                    .frame(width: 8, height: 8)
                            }
                            Image(systemName: eventIcon(for: event.type))
                                .foregroundStyle(eventColor(for: event.type))
                            Text(eventLabel(for: event))
                            Spacer()
                            Text(settings.formattedTime(event.timestamp))
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Events")
                }
            }
        }
        .navigationTitle("Walk")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { notesText = walk.notes ?? "" }
    }

    private func regionFitting(coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
        guard !coordinates.isEmpty else {
            return MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 0, longitude: 0), span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        }
        var minLat = coordinates[0].latitude
        var maxLat = minLat
        var minLon = coordinates[0].longitude
        var maxLon = minLon
        for c in coordinates.dropFirst() {
            minLat = min(minLat, c.latitude)
            maxLat = max(maxLat, c.latitude)
            minLon = min(minLon, c.longitude)
            maxLon = max(maxLon, c.longitude)
        }
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max(maxLat - minLat, 0.002) * 1.4,
            longitudeDelta: max(maxLon - minLon, 0.002) * 1.4
        )
        return MKCoordinateRegion(center: center, span: span)
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

    @ViewBuilder
    private func eventMarker(event: WalkEvent) -> some View {
        Image(systemName: eventIcon(for: event.type))
            .font(.title2)
            .foregroundStyle(eventColor(for: event.type))
            .padding(8)
            .background(.background, in: Circle())
            .shadow(radius: 2)
            .overlay {
                if walk.dogIds.count > 1, let dogId = event.dogId ?? walk.dogIds.first, let color = DogColors.color(for: dogId, in: walk.dogIds) {
                    Circle()
                        .stroke(color, lineWidth: 3)
                        .padding(-4)
                }
            }
    }

    private func eventLabel(for event: WalkEvent) -> String {
        let typeStr = event.type.rawValue.capitalized
        guard let id = event.dogId else { return typeStr }
        guard let name = dogStore.dog(byId: id)?.name, !name.isEmpty else { return "\(typeStr) (no longer in profile)" }
        return "\(typeStr) (\(name))"
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
}

#Preview {
    NavigationStack {
        WalkDetailView(store: WalkStore(), settings: SettingsStore(), dogStore: DogProfileStore(), walk: Walk(
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
    }
}

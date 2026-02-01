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
    let walk: Walk
    @State private var notesText: String = ""
    @State private var notesSaved = false

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
                                    Image(systemName: eventIcon(for: event.type))
                                        .font(.title2)
                                        .foregroundStyle(eventColor(for: event.type))
                                        .padding(8)
                                        .background(.background, in: Circle())
                                        .shadow(radius: 2)
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
                Label(formattedDuration(walk.durationSeconds), systemImage: "clock")
                if walk.distanceMeters > 0 {
                    Label(settings.formattedDistance(walk.distanceMeters), systemImage: "location")
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
                        HStack {
                            Image(systemName: eventIcon(for: event.type))
                                .foregroundStyle(eventColor(for: event.type))
                            Text(event.type.rawValue.capitalized)
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
}

#Preview {
    NavigationStack {
        WalkDetailView(store: WalkStore(), settings: SettingsStore(), walk: Walk(
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

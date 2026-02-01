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
    @State private var notesText: String = ""
    @State private var notesSaved = false
    @State private var showDeleteConfirmation = false

    private var routeCoords: [CLLocationCoordinate2D] {
        walk.routeForMap.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
    }

    private var mapPosition: MapCameraPosition {
        if routeCoords.isEmpty { return .automatic }
        return .region(WalkMapView.regionFitting(coordinates: routeCoords))
    }

    var body: some View {
        List {
            if !routeCoords.isEmpty || walk.events.contains(where: { $0.coordinate != nil }) {
                Section {
                    WalkMapView(
                        routeCoordinates: routeCoords,
                        events: walk.events,
                        dogIds: walk.dogIds,
                        mapStyle: settings.mapStylePreference.mapStyle,
                        height: 200,
                        showUserLocation: false,
                        cameraPosition: mapPosition
                    )
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Walk route map with event markers")
                }
            }

            Section {
                if let weather = walk.savedWeather {
                    WeatherDisplayView(
                        temperatureCelsius: weather.temperatureCelsius,
                        conditionDescription: weather.conditionDescription,
                        suggestionMessage: nil,
                        settings: settings
                    )
                }
                Label(formattedDuration(seconds: walk.durationSeconds), systemImage: "clock")
                if walk.distanceMeters > 0 {
                    Label(settings.formattedDistance(walk.distanceMeters), systemImage: "location")
                }
                if !walk.dogIds.isEmpty {
                    Label(dogsSummaryText(walk: walk, dogStore: dogStore), systemImage: "pawprint")
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
                            Image(systemName: event.type.iconName)
                                .foregroundStyle(event.type.displayColor)
                            Text(eventListLabel(for: event))
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

    private func eventListLabel(for event: WalkEvent) -> String {
        let typeStr = event.type.rawValue.capitalized
        guard let label = eventLabel(event: event, dogStore: dogStore) else { return typeStr }
        return "\(typeStr) (\(label))"
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

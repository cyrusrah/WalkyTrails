//
//  WalkDetailView.swift
//  WalkyTrails
//

import CoreLocation
import MapKit
import SwiftUI

struct WalkDetailView: View {
    let walk: Walk

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
                                    Image(systemName: event.type == .pee ? "drop.fill" : "leaf.fill")
                                        .font(.title2)
                                        .foregroundStyle(event.type == .pee ? .blue : .brown)
                                        .padding(8)
                                        .background(.background, in: Circle())
                                        .shadow(radius: 2)
                                }
                            }
                        }
                    }
                    .mapStyle(.standard(elevation: .realistic))
                    .frame(height: 200)
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                }
            }

            Section {
                Label(formattedDuration(walk.durationSeconds), systemImage: "clock")
                if walk.distanceMeters > 0 {
                    Label(String(format: "%.2f km", walk.distanceMeters / 1000), systemImage: "location")
                }
                Text(walk.startTime, style: .date)
                Text(walk.startTime, style: .time)
            } header: {
                Text("Summary")
            }

            if !walk.events.isEmpty {
                Section {
                    ForEach(walk.events) { event in
                        HStack {
                            Image(systemName: event.type == .pee ? "drop.fill" : "leaf.fill")
                                .foregroundStyle(event.type == .pee ? .blue : .brown)
                            Text(event.type.rawValue.capitalized)
                            Spacer()
                            Text(event.timestamp, style: .time)
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
    }
}

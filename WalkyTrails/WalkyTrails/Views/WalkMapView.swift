//
//  WalkMapView.swift
//  WalkyTrails
//
//  Reusable map: route polyline + event markers. Optional user location and custom camera.
//

import CoreLocation
import MapKit
import SwiftUI

struct WalkMapView: View {
    /// Recorded GPS path (solid tint line).
    let routeCoordinates: [CLLocationCoordinate2D]
    /// Planned walking route from MapKit directions (dashed secondary line); drawn under the recorded path.
    var plannedRouteCoordinates: [CLLocationCoordinate2D] = []
    let events: [WalkEvent]
    let dogIds: [UUID]
    let mapStyle: MapStyle
    let height: CGFloat
    var showUserLocation: Bool = false
    var cameraPosition: MapCameraPosition?

    private var initialPosition: MapCameraPosition {
        if showUserLocation { return .userLocation(fallback: .automatic) }
        if let pos = cameraPosition { return pos }
        let combined = routeCoordinates + plannedRouteCoordinates
        if combined.isEmpty { return .automatic }
        return .region(Self.regionFitting(coordinates: combined))
    }

    var body: some View {
        Map(initialPosition: initialPosition) {
            if showUserLocation {
                UserAnnotation()
            }
            if !plannedRouteCoordinates.isEmpty {
                MapPolyline(coordinates: plannedRouteCoordinates)
                    .stroke(
                        .secondary,
                        style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round, dash: [8, 5])
                    )
            }
            if !routeCoordinates.isEmpty {
                MapPolyline(coordinates: routeCoordinates)
                    .stroke(.tint, lineWidth: 4)
            }
            ForEach(events.filter { $0.coordinate != nil }, id: \.id) { event in
                if let coord = event.coordinate {
                    Annotation("", coordinate: CLLocationCoordinate2D(latitude: coord.latitude, longitude: coord.longitude)) {
                        EventMarkerView(event: event, dogIds: dogIds)
                    }
                }
            }
        }
        .mapStyle(mapStyle)
        .frame(height: height)
    }

    static func regionFitting(coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
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
}

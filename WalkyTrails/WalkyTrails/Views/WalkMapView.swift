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
    struct UserMarker {
        let coordinate: CLLocationCoordinate2D
        let photoData: Data?
    }

    /// Recorded GPS path (solid tint line).
    let routeCoordinates: [CLLocationCoordinate2D]
    /// Planned walking route from MapKit directions (dashed secondary line); drawn under the recorded path.
    var plannedRouteCoordinates: [CLLocationCoordinate2D] = []
    let events: [WalkEvent]
    let dogIds: [UUID]
    let mapStyle: MapStyle
    let height: CGFloat
    var showUserLocation: Bool = false
    var userMarker: UserMarker?
    var cameraPosition: MapCameraPosition?
    var position: Binding<MapCameraPosition>?

    private var initialPosition: MapCameraPosition {
        if showUserLocation { return .userLocation(fallback: .automatic) }
        if let pos = cameraPosition { return pos }
        let combined = routeCoordinates + plannedRouteCoordinates
        if combined.isEmpty { return .automatic }
        return .region(Self.regionFitting(coordinates: combined))
    }

    var body: some View {
        Group {
            if let position {
                Map(position: position) {
                    mapContent
                }
            } else {
                Map(initialPosition: initialPosition) {
                    mapContent
                }
            }
        }
        .mapStyle(mapStyle)
        .mapControlVisibility(.hidden)
        .frame(height: height)
    }

    @MapContentBuilder
    private var mapContent: some MapContent {
        if let marker = userMarker {
            Annotation("", coordinate: marker.coordinate) {
                UserDogMarker(photoData: marker.photoData)
            }
        } else if showUserLocation {
            UserAnnotation()
        }
        if !plannedRouteCoordinates.isEmpty {
            MapPolyline(coordinates: plannedRouteCoordinates)
                .stroke(
                    WTTheme.ColorToken.stone,
                    style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round, dash: [8, 5])
                )
        }
        if !routeCoordinates.isEmpty {
            MapPolyline(coordinates: routeCoordinates)
                .stroke(WTTheme.ColorToken.route, lineWidth: 4)
        }
        ForEach(events.filter { $0.coordinate != nil }, id: \.id) { event in
            if let coord = event.coordinate {
                Annotation("", coordinate: CLLocationCoordinate2D(latitude: coord.latitude, longitude: coord.longitude)) {
                    EventMarkerView(event: event, dogIds: dogIds)
                }
            }
        }
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

private struct UserDogMarker: View {
    let photoData: Data?

    var body: some View {
        VStack(spacing: -6) {
            if let photoData, let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 58, height: 58)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(.white, lineWidth: 3))
                    .shadow(color: .black.opacity(0.12), radius: 14, x: 0, y: 8)
            } else {
                Circle()
                    .fill(.white)
                    .frame(width: 58, height: 58)
                    .overlay(Circle().stroke(.white, lineWidth: 3))
                    .shadow(color: .black.opacity(0.12), radius: 14, x: 0, y: 8)
                    .overlay(
                        Image(systemName: "pawprint.fill")
                            .foregroundStyle(WTTheme.ColorToken.forest)
                    )
            }

            // Small pointer above the position dot so the avatar does not cover the anchor.
            Circle()
                .fill(WTTheme.ColorToken.route)
                .frame(width: 6, height: 6)
                .shadow(color: .black.opacity(0.10), radius: 6, x: 0, y: 4)

            ZStack {
                Circle()
                    .fill(WTTheme.ColorToken.route)
                    .frame(width: 18, height: 18)
                Circle()
                    .stroke(.white, lineWidth: 3)
                    .frame(width: 24, height: 24)
                    .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 6)
            }
        }
        .allowsHitTesting(false)
    }
}

//
//  WalkingDirectionsService.swift
//  WalkyTrails
//

import CoreLocation
import MapKit

/// Builds a single walking polyline from ordered waypoints using `MKDirections` between each segment.
enum WalkingDirectionsService {

    /// Stitches walking routes; on failure for a leg, uses a straight segment `[from, to]`.
    static func stitchWalkingRoute(waypoints: [CLLocationCoordinate2D]) async -> [CLLocationCoordinate2D] {
        guard waypoints.count >= 2 else { return waypoints }
        var result: [CLLocationCoordinate2D] = []
        for i in 0..<(waypoints.count - 1) {
            let from = waypoints[i]
            let to = waypoints[i + 1]
            let segment = await walkingSegment(from: from, to: to)
            if result.isEmpty {
                result.append(contentsOf: segment)
            } else if let first = segment.first, let last = result.last, coordinatesEqual(first, last) {
                result.append(contentsOf: segment.dropFirst())
            } else {
                result.append(contentsOf: segment)
            }
        }
        return result
    }

    private static func walkingSegment(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) async -> [CLLocationCoordinate2D] {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: from))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: to))
        request.transportType = .walking

        return await withCheckedContinuation { continuation in
            MKDirections(request: request).calculate { response, _ in
                guard let route = response?.routes.first else {
                    continuation.resume(returning: [from, to])
                    return
                }
                continuation.resume(returning: route.polyline.coordinates)
            }
        }
    }

    private static func coordinatesEqual(_ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D) -> Bool {
        abs(a.latitude - b.latitude) < 1e-5 && abs(a.longitude - b.longitude) < 1e-5
    }
}

extension MKPolyline {
    var coordinates: [CLLocationCoordinate2D] {
        var coords = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid, count: pointCount)
        getCoordinates(&coords, range: NSRange(location: 0, length: pointCount))
        return coords
    }
}

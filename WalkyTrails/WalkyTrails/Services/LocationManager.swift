//
//  LocationManager.swift
//  WalkyTrails
//

import Foundation
import CoreLocation
import SwiftUI

/// Tracks location during a walk and accumulates distance (meters).
final class LocationManager: NSObject, ObservableObject {
    @Published var distanceMeters: Double = 0
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    /// Current location; updated while tracking.
    @Published var currentLocation: CLLocation?
    /// Route path so far; appended on each location update. Reset when starting a walk.
    @Published var routeCoordinates: [CLLocationCoordinate2D] = []

    private let manager = CLLocationManager()
    private var lastLocation: CLLocation?
    private var isTracking = false

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 5 // meters – avoid tiny jitter
        authorizationStatus = manager.authorizationStatus
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    /// Start tracking; resets distance and route.
    func startTracking() {
        guard CLLocationManager.locationServicesEnabled() else { return }
        distanceMeters = 0
        lastLocation = nil
        currentLocation = nil
        routeCoordinates = []
        isTracking = true
        manager.startUpdatingLocation()
    }

    /// Stop tracking.
    func stopTracking() {
        isTracking = false
        manager.stopUpdatingLocation()
    }

    private func addDistance(from newLocation: CLLocation) {
        guard isTracking else { return }
        if let last = lastLocation {
            let delta = newLocation.distance(from: last)
            if delta >= 0 && delta < 500 { // ignore huge jumps (e.g. simulator glitch)
                distanceMeters += delta
            }
        }
        lastLocation = newLocation
        currentLocation = newLocation
        routeCoordinates.append(newLocation.coordinate)
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last, location.horizontalAccuracy >= 0 else { return }
        addDistance(from: location)
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }
}

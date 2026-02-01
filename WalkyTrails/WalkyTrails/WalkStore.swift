//
//  WalkStore.swift
//  WalkyTrails
//

import CoreLocation
import Foundation
import SwiftUI

/// Persists and manages walks. Uses UserDefaults for v1.
final class WalkStore: ObservableObject {
    static let walksKey = "walkyTrails.savedWalks"

    @Published var walks: [Walk]
    @Published var currentWalk: Walk?
    @Published var walkToSummarize: Walk?

    init() {
        self.walks = Self.loadWalks()
        self.currentWalk = nil
        self.walkToSummarize = nil
    }

    private static func loadWalks() -> [Walk] {
        guard let data = UserDefaults.standard.data(forKey: walksKey) else { return [] }
        let decoder = JSONDecoder()
        return (try? decoder.decode([Walk].self, from: data)) ?? []
    }

    private func persistWalks() {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(walks) else { return }
        UserDefaults.standard.set(data, forKey: Self.walksKey)
    }

    func startWalk() {
        currentWalk = Walk()
    }

    /// End the current walk and store the route. Call with LocationManager.routeCoordinates.
    func endWalk(withRoute route: [CLLocationCoordinate2D] = []) {
        guard var walk = currentWalk else { return }
        let coords = route.map { Coordinate(latitude: $0.latitude, longitude: $0.longitude) }
        walk.end(route: coords)
        currentWalk = nil
        walkToSummarize = walk
    }

    func saveWalk() {
        guard let walk = walkToSummarize else { return }
        walks.insert(walk, at: 0)
        persistWalks()
        walkToSummarize = nil
    }

    func discardWalk() {
        walkToSummarize = nil
    }

    /// Add a pee/poop event; pass current location so it appears on the map.
    func addEventToCurrentWalk(_ type: WalkEvent.EventType, at coordinate: CLLocationCoordinate2D? = nil) {
        guard var walk = currentWalk else { return }
        let coord: Coordinate? = coordinate.map { Coordinate(latitude: $0.latitude, longitude: $0.longitude) }
        walk.addEvent(type, at: coord)
        currentWalk = walk
    }

    func updateCurrentWalk(_ walk: Walk) {
        currentWalk = walk
    }

    /// Update the current walk’s distance (from GPS). Call from LocationManager updates.
    func updateCurrentWalkDistance(_ meters: Double) {
        guard var walk = currentWalk else { return }
        walk.distanceMeters = meters
        currentWalk = walk
    }
}

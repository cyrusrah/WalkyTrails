//
//  WalkStore.swift
//  WalkyTrails
//

import CoreLocation
import Foundation
import SwiftUI

/// Persists and manages walks. Uses UserDefaults for v1.
/// Current walk is persisted so Siri Shortcuts can add events when app is in background.
final class WalkStore: ObservableObject {
    static let walksKey = "walkyTrails.savedWalks"
    static let currentWalkKey = "walkyTrails.currentWalk"

    @Published var walks: [Walk]
    @Published var currentWalk: Walk? {
        didSet { persistCurrentWalk() }
    }
    @Published var walkToSummarize: Walk?

    init() {
        self.walks = Self.loadWalks()
        self.currentWalk = Self.loadCurrentWalk()
        self.walkToSummarize = nil
    }

    /// Reload current walk from UserDefaults (e.g. after Siri added an event while app was in background).
    func reloadCurrentWalkFromStorage() {
        currentWalk = Self.loadCurrentWalk()
    }

    private static func loadCurrentWalk() -> Walk? {
        guard let data = UserDefaults.standard.data(forKey: currentWalkKey) else { return nil }
        return (try? JSONDecoder().decode(Walk.self, from: data))
    }

    private func persistCurrentWalk() {
        guard let walk = currentWalk else {
            UserDefaults.standard.removeObject(forKey: Self.currentWalkKey)
            return
        }
        guard let data = try? JSONEncoder().encode(walk) else { return }
        UserDefaults.standard.set(data, forKey: Self.currentWalkKey)
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

    func startWalk(dogIds: [UUID] = []) {
        currentWalk = Walk(dogIds: dogIds)
    }

    /// End the current walk and store the route. Call with LocationManager.routeCoordinates.
    func endWalk(withRoute route: [CLLocationCoordinate2D] = []) {
        guard var walk = currentWalk else { return }
        let coords = route.map { Coordinate(latitude: $0.latitude, longitude: $0.longitude) }
        walk.end(route: coords)
        currentWalk = nil
        persistCurrentWalk()
        walkToSummarize = walk
    }

    /// Saves the walk to history. Pass current weather to store with the walk for display in history.
    func saveWalk(weather: SavedWeather? = nil) {
        guard var walk = walkToSummarize else { return }
        walk.savedWeather = weather
        walks.insert(walk, at: 0)
        persistWalks()
        walkToSummarize = nil
    }

    func discardWalk() {
        walkToSummarize = nil
    }

    /// Set notes on the walk waiting to be saved (summary screen).
    func setNotesForWalkToSummarize(_ notes: String?) {
        guard var w = walkToSummarize else { return }
        let t = notes?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        w.notes = t.isEmpty ? nil : t
        walkToSummarize = w
    }

    /// Update notes for an already-saved walk (detail screen).
    func updateNotes(for walkId: UUID, notes: String?) {
        guard let idx = walks.firstIndex(where: { $0.id == walkId }) else { return }
        let t = notes?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        walks[idx].notes = t.isEmpty ? nil : t
        persistWalks()
    }

    /// Remove one saved walk from history.
    func deleteWalk(id: UUID) {
        walks.removeAll { $0.id == id }
        persistWalks()
    }

    /// Remove multiple saved walks by id.
    func deleteWalks(ids: Set<UUID>) {
        walks.removeAll { ids.contains($0.id) }
        persistWalks()
    }

    /// Remove all saved walks from history.
    func deleteAllWalks() {
        walks = []
        persistWalks()
    }

    /// Add a pee/poop/water/play event; pass current location and optional dog (for multi-dog walks).
    func addEventToCurrentWalk(_ type: WalkEvent.EventType, at coordinate: CLLocationCoordinate2D? = nil, dogId: UUID? = nil) {
        guard var walk = currentWalk else { return }
        let coord: Coordinate? = coordinate.map { Coordinate(latitude: $0.latitude, longitude: $0.longitude) }
        let resolvedDogId = dogId ?? walk.dogIds.first
        walk.addEvent(type, at: coord, dogId: resolvedDogId)
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

    // MARK: - Export

    private static let jsonDateEncoding: JSONEncoder.DateEncodingStrategy = .iso8601
    private static let jsonDateDecoding: JSONDecoder.DateDecodingStrategy = .iso8601

    /// Full backup envelope: user profile + dogs + walks. Use for JSON export.
    struct ExportEnvelope: Codable {
        let version: Int
        let exportedAt: Date
        var user: UserProfile?
        var dogs: [Dog]
        var walks: [Walk]

        init(version: Int, exportedAt: Date, user: UserProfile?, dogs: [Dog], walks: [Walk]) {
            self.version = version
            self.exportedAt = exportedAt
            self.user = user
            self.dogs = dogs
            self.walks = walks
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            version = try c.decode(Int.self, forKey: .version)
            exportedAt = try c.decode(Date.self, forKey: .exportedAt)
            user = try c.decodeIfPresent(UserProfile.self, forKey: .user)
            if let decodedDogs = try? c.decode([Dog].self, forKey: .dogs), !decodedDogs.isEmpty {
                dogs = decodedDogs
            } else if let legacyDog = try? c.decode(Dog.self, forKey: .dog), legacyDog.hasContent {
                dogs = [legacyDog]
            } else {
                dogs = []
            }
            walks = try c.decode([Walk].self, forKey: .walks)
        }

        func encode(to encoder: Encoder) throws {
            var c = encoder.container(keyedBy: CodingKeys.self)
            try c.encode(version, forKey: .version)
            try c.encode(exportedAt, forKey: .exportedAt)
            try c.encodeIfPresent(user, forKey: .user)
            try c.encode(dogs, forKey: .dogs)
            try c.encode(walks, forKey: .walks)
        }

        private enum CodingKeys: String, CodingKey {
            case version, exportedAt, user, dog, dogs, walks
        }
    }

    /// Encodes user profile, dogs, and walks as JSON (ISO8601 dates). Use for backup or share.
    func exportAsJSONData(user: UserProfile? = nil, dogs: [Dog] = []) -> Data? {
        let envelope = ExportEnvelope(
            version: 2,
            exportedAt: Date(),
            user: user?.hasContent == true ? user : nil,
            dogs: dogs,
            walks: walks
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = Self.jsonDateEncoding
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try? encoder.encode(envelope)
    }

    /// Exports all saved walks as CSV: one row per walk (Start, End, Duration (sec), Distance (m), Notes, Events).
    func exportAsCSV() -> String {
        var rows: [String] = []
        let header = "Start,End,Duration (sec),Distance (m),Notes,Events"
        rows.append(header)
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        for walk in walks {
            let start = dateFormatter.string(from: walk.startTime)
            let end = walk.endTime.map { dateFormatter.string(from: $0) } ?? ""
            let duration = String(format: "%.0f", walk.durationSeconds)
            let distance = String(format: "%.2f", walk.distanceMeters)
            let notes = escapeCSV(walk.notes ?? "")
            let events = walk.events.map(\.type.rawValue).joined(separator: "; ")
            rows.append([start, end, duration, distance, notes, events].joined(separator: ","))
        }
        return rows.joined(separator: "\n")
    }

    private func escapeCSV(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return value
    }

    // MARK: - Restore

    /// Decodes a previously exported JSON backup (ExportEnvelope). Returns nil if data is invalid.
    static func decodeBackup(_ data: Data) -> ExportEnvelope? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = Self.jsonDateDecoding
        return try? decoder.decode(ExportEnvelope.self, from: data)
    }

    /// Replaces all saved walks with the given array and persists. Use after decoding a backup.
    func replaceWalks(with newWalks: [Walk]) {
        walks = newWalks
        persistWalks()
    }
}

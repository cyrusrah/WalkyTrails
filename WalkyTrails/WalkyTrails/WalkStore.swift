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

    func startWalk() {
        currentWalk = Walk()
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

    func saveWalk() {
        guard let walk = walkToSummarize else { return }
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

    // MARK: - Export

    private static let jsonDateEncoding: JSONEncoder.DateEncodingStrategy = .iso8601
    private static let jsonDateDecoding: JSONDecoder.DateDecodingStrategy = .iso8601

    /// Full backup envelope: dog profile (optional) + all walks. Use for JSON export.
    struct ExportEnvelope: Codable {
        let version: Int
        let exportedAt: Date
        var dog: Dog?
        var walks: [Walk]
    }

    /// Encodes dog profile (if provided) and all walks as JSON (ISO8601 dates). Use for backup or share.
    /// Pass the current dog so the export can be used for full restore later.
    func exportAsJSONData(dog: Dog? = nil) -> Data? {
        let envelope = ExportEnvelope(
            version: 1,
            exportedAt: Date(),
            dog: dog?.hasContent == true ? dog : nil,
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

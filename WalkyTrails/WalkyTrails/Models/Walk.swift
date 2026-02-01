//
//  Walk.swift
//  WalkyTrails
//

import Foundation
import SwiftUI

/// A coordinate for route or event location. Codable for persistence.
struct Coordinate: Codable, Equatable {
    let latitude: Double
    let longitude: Double
}

/// Weather at time of save (for display in history). Codable for persistence.
struct SavedWeather: Codable, Equatable {
    let temperatureCelsius: Double
    let conditionDescription: String
    let weatherCode: Int
}

/// A single event logged during a walk (e.g. pee, poop).
struct WalkEvent: Codable, Identifiable {
    let id: UUID
    let type: EventType
    let timestamp: Date
    var latitude: Double?
    var longitude: Double?
    /// Which dog this event is for; nil for walks/events before per-dog logging.
    var dogId: UUID?

    init(
        id: UUID = UUID(),
        type: EventType,
        timestamp: Date = Date(),
        latitude: Double? = nil,
        longitude: Double? = nil,
        dogId: UUID? = nil
    ) {
        self.id = id
        self.type = type
        self.timestamp = timestamp
        self.latitude = latitude
        self.longitude = longitude
        self.dogId = dogId
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        type = try c.decode(EventType.self, forKey: .type)
        timestamp = try c.decode(Date.self, forKey: .timestamp)
        latitude = try c.decodeIfPresent(Double.self, forKey: .latitude)
        longitude = try c.decodeIfPresent(Double.self, forKey: .longitude)
        dogId = try c.decodeIfPresent(UUID.self, forKey: .dogId)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(type, forKey: .type)
        try c.encode(timestamp, forKey: .timestamp)
        try c.encodeIfPresent(latitude, forKey: .latitude)
        try c.encodeIfPresent(longitude, forKey: .longitude)
        try c.encodeIfPresent(dogId, forKey: .dogId)
    }

    private enum CodingKeys: String, CodingKey {
        case id, type, timestamp, latitude, longitude, dogId
    }

    /// Coordinate for map marker; nil if event has no location.
    var coordinate: Coordinate? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return Coordinate(latitude: lat, longitude: lon)
    }

    enum EventType: String, Codable, CaseIterable {
        case pee
        case poop
        case water
        case play

        /// SF Symbol name for list and map markers.
        var iconName: String {
            switch self {
            case .pee: return "drop.fill"
            case .poop: return "leaf.fill"
            case .water: return "cup.and.saucer.fill"
            case .play: return "tennisball.fill"
            }
        }

        /// Color for event icon and list.
        var displayColor: Color {
            switch self {
            case .pee: return .blue
            case .poop: return .brown
            case .water: return .cyan
            case .play: return .orange
            }
        }
    }
}

/// A recorded walk (in progress or completed).
struct Walk: Codable, Identifiable {
    let id: UUID
    let startTime: Date
    var endTime: Date?
    var distanceMeters: Double
    var events: [WalkEvent]
    /// Full path; nil for walks saved before route recording.
    var routeCoordinates: [Coordinate]?
    /// Optional free-text notes (e.g. "Sunny, met a friend").
    var notes: String?
    /// IDs of dogs on this walk; empty for walks saved before multi-dog.
    var dogIds: [UUID]
    /// Weather when the walk was saved (for display in history); nil for walks saved before this existed.
    var savedWeather: SavedWeather?

    var durationSeconds: TimeInterval {
        let end = endTime ?? Date()
        return end.timeIntervalSince(startTime)
    }

    var isInProgress: Bool {
        endTime == nil
    }

    /// Route for map display; empty if not recorded.
    var routeForMap: [Coordinate] {
        routeCoordinates ?? []
    }

    init(
        id: UUID = UUID(),
        startTime: Date = Date(),
        endTime: Date? = nil,
        distanceMeters: Double = 0,
        events: [WalkEvent] = [],
        routeCoordinates: [Coordinate]? = nil,
        notes: String? = nil,
        dogIds: [UUID] = [],
        savedWeather: SavedWeather? = nil
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.distanceMeters = distanceMeters
        self.events = events
        self.routeCoordinates = routeCoordinates
        self.notes = notes
        self.dogIds = dogIds
        self.savedWeather = savedWeather
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        startTime = try c.decode(Date.self, forKey: .startTime)
        endTime = try c.decodeIfPresent(Date.self, forKey: .endTime)
        distanceMeters = try c.decode(Double.self, forKey: .distanceMeters)
        events = try c.decode([WalkEvent].self, forKey: .events)
        routeCoordinates = try c.decodeIfPresent([Coordinate].self, forKey: .routeCoordinates)
        notes = try c.decodeIfPresent(String.self, forKey: .notes)
        dogIds = try c.decodeIfPresent([UUID].self, forKey: .dogIds) ?? []
        savedWeather = try c.decodeIfPresent(SavedWeather.self, forKey: .savedWeather)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(startTime, forKey: .startTime)
        try c.encodeIfPresent(endTime, forKey: .endTime)
        try c.encode(distanceMeters, forKey: .distanceMeters)
        try c.encode(events, forKey: .events)
        try c.encodeIfPresent(routeCoordinates, forKey: .routeCoordinates)
        try c.encodeIfPresent(notes, forKey: .notes)
        try c.encode(dogIds, forKey: .dogIds)
        try c.encodeIfPresent(savedWeather, forKey: .savedWeather)
    }

    private enum CodingKeys: String, CodingKey {
        case id, startTime, endTime, distanceMeters, events, routeCoordinates, notes, dogIds, savedWeather
    }

    mutating func end(route: [Coordinate]) {
        routeCoordinates = route
        endTime = Date()
    }

    mutating func addEvent(_ type: WalkEvent.EventType, at coordinate: Coordinate?, dogId: UUID? = nil) {
        var event = WalkEvent(type: type, dogId: dogId)
        if let c = coordinate {
            event.latitude = c.latitude
            event.longitude = c.longitude
        }
        events.append(event)
    }
}

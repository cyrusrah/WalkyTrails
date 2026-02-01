//
//  Walk.swift
//  WalkyTrails
//

import Foundation

/// A coordinate for route or event location. Codable for persistence.
struct Coordinate: Codable, Equatable {
    let latitude: Double
    let longitude: Double
}

/// A single event logged during a walk (e.g. pee, poop).
struct WalkEvent: Codable, Identifiable {
    let id: UUID
    let type: EventType
    let timestamp: Date
    var latitude: Double?
    var longitude: Double?

    init(
        id: UUID = UUID(),
        type: EventType,
        timestamp: Date = Date(),
        latitude: Double? = nil,
        longitude: Double? = nil
    ) {
        self.id = id
        self.type = type
        self.timestamp = timestamp
        self.latitude = latitude
        self.longitude = longitude
    }

    /// Coordinate for map marker; nil if event has no location.
    var coordinate: Coordinate? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return Coordinate(latitude: lat, longitude: lon)
    }

    enum EventType: String, Codable, CaseIterable {
        case pee
        case poop
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
        routeCoordinates: [Coordinate]? = nil
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.distanceMeters = distanceMeters
        self.events = events
        self.routeCoordinates = routeCoordinates
    }

    mutating func end(route: [Coordinate]) {
        routeCoordinates = route
        endTime = Date()
    }

    mutating func addEvent(_ type: WalkEvent.EventType, at coordinate: Coordinate?) {
        var event = WalkEvent(type: type)
        if let c = coordinate {
            event.latitude = c.latitude
            event.longitude = c.longitude
        }
        events.append(event)
    }
}

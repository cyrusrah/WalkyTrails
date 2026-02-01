//
//  Walk.swift
//  WalkyTrails
//

import Foundation

/// A single event logged during a walk (e.g. pee, poop).
struct WalkEvent: Codable, Identifiable {
    let id: UUID
    let type: EventType
    let timestamp: Date

    init(id: UUID = UUID(), type: EventType, timestamp: Date = Date()) {
        self.id = id
        self.type = type
        self.timestamp = timestamp
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

    var durationSeconds: TimeInterval {
        let end = endTime ?? Date()
        return end.timeIntervalSince(startTime)
    }

    var isInProgress: Bool {
        endTime == nil
    }

    init(
        id: UUID = UUID(),
        startTime: Date = Date(),
        endTime: Date? = nil,
        distanceMeters: Double = 0,
        events: [WalkEvent] = []
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.distanceMeters = distanceMeters
        self.events = events
    }

    mutating func end() {
        endTime = Date()
    }

    mutating func addEvent(_ type: WalkEvent.EventType) {
        events.append(WalkEvent(type: type))
    }
}

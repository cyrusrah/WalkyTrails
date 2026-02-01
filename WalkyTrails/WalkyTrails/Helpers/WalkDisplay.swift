//
//  WalkDisplay.swift
//  WalkyTrails
//
//  Single source for walk-related formatting and display text (duration, dogs summary, event labels).
//

import Foundation
import SwiftUI

// MARK: - Duration

/// Duration from seconds: "5 min 30 sec".
func formattedDuration(seconds: TimeInterval) -> String {
    let m = Int(seconds) / 60
    let s = Int(seconds) % 60
    return String(format: "%d min %d sec", m, s)
}

/// Elapsed time from start date to now: "12:34" (minutes:seconds).
func formattedElapsed(from start: Date, now: Date = Date()) -> String {
    let interval = now.timeIntervalSince(start)
    let minutes = Int(interval) / 60
    let seconds = Int(interval) % 60
    return String(format: "%d:%02d", minutes, seconds)
}

// MARK: - Dogs and events

/// "Rex, Luna" or "2 dog(s) (no longer in profile)" or "".
func dogsSummaryText(walk: Walk, dogStore: DogProfileStore) -> String {
    if walk.dogIds.isEmpty { return "" }
    let names = walk.dogIds.compactMap { dogStore.dog(byId: $0)?.name }.filter { !$0.isEmpty }
    if names.isEmpty {
        return "\(walk.dogIds.count) dog(s) (no longer in profile)"
    }
    return names.joined(separator: ", ")
}

/// Dog name for event, or "No longer in profile", or nil if event has no dogId.
func eventLabel(event: WalkEvent, dogStore: DogProfileStore) -> String? {
    guard let id = event.dogId else { return nil }
    if let dog = dogStore.dog(byId: id), !dog.name.isEmpty { return dog.name }
    return "No longer in profile"
}

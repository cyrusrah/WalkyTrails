//
//  WalkyTrailsIntents.swift
//  WalkyTrails
//
//  Siri Shortcuts: log pee, poop, water, or play during a walk without touching the screen.
//

import AppIntents
import Foundation

// MARK: - Shared persistence (same key as WalkStore)

private let currentWalkKey = "walkyTrails.currentWalk"

private func loadCurrentWalk() -> Walk? {
    guard let data = UserDefaults.standard.data(forKey: currentWalkKey) else { return nil }
    return try? JSONDecoder().decode(Walk.self, from: data)
}

private func saveCurrentWalk(_ walk: Walk?) {
    if let walk = walk {
        if let data = try? JSONEncoder().encode(walk) { UserDefaults.standard.set(data, forKey: currentWalkKey) }
    } else {
        UserDefaults.standard.removeObject(forKey: currentWalkKey)
    }
}

private func addEventToCurrentWalk(_ type: WalkEvent.EventType) -> Bool {
    guard var walk = loadCurrentWalk(), walk.endTime == nil else { return false }
    walk.addEvent(type, at: nil)
    saveCurrentWalk(walk)
    return true
}

// MARK: - Log Pee

struct LogPeeIntent: AppIntent {
    static var title: LocalizedStringResource = "Log pee"
    static var description = IntentDescription("Add a pee event to your current walk in WalkyTrails.")
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult {
        if addEventToCurrentWalk(.pee) {
            return .result()
        }
        throw LogWalkEventError.noWalkInProgress
    }
}

// MARK: - Log Poop

struct LogPoopIntent: AppIntent {
    static var title: LocalizedStringResource = "Log poop"
    static var description = IntentDescription("Add a poop event to your current walk in WalkyTrails.")
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult {
        if addEventToCurrentWalk(.poop) {
            return .result()
        }
        throw LogWalkEventError.noWalkInProgress
    }
}

// MARK: - Log Water

struct LogWaterIntent: AppIntent {
    static var title: LocalizedStringResource = "Log water"
    static var description = IntentDescription("Add a water event to your current walk in WalkyTrails.")
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult {
        if addEventToCurrentWalk(.water) {
            return .result()
        }
        throw LogWalkEventError.noWalkInProgress
    }
}

// MARK: - Log Play

struct LogPlayIntent: AppIntent {
    static var title: LocalizedStringResource = "Log play"
    static var description = IntentDescription("Add a play event to your current walk in WalkyTrails.")
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult {
        if addEventToCurrentWalk(.play) {
            return .result()
        }
        throw LogWalkEventError.noWalkInProgress
    }
}

// MARK: - Error

enum LogWalkEventError: Error {
    case noWalkInProgress
}

extension LogWalkEventError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .noWalkInProgress: return "No walk in progress. Start a walk in WalkyTrails first."
        }
    }
}

// MARK: - App Shortcuts (so Siri discovers these)

struct WalkyTrailsShortcuts: AppShortcutsProvider {
    @AppShortcutsBuilder
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogPeeIntent(),
            phrases: [
                "Log pee in \(.applicationName)",
                "\(.applicationName) log pee",
                "Record pee in \(.applicationName)",
                "Log a pee in \(.applicationName)"
            ],
            shortTitle: "Log pee",
            systemImageName: "drop"
        )
        AppShortcut(
            intent: LogPoopIntent(),
            phrases: [
                "Log poop in \(.applicationName)",
                "\(.applicationName) log poop",
                "Record poop in \(.applicationName)",
                "Log a poop in \(.applicationName)"
            ],
            shortTitle: "Log poop",
            systemImageName: "leaf"
        )
        AppShortcut(
            intent: LogWaterIntent(),
            phrases: [
                "Log water in \(.applicationName)",
                "\(.applicationName) log water",
                "Record water in \(.applicationName)",
                "Log water in \(.applicationName)"
            ],
            shortTitle: "Log water",
            systemImageName: "cup.and.saucer"
        )
        AppShortcut(
            intent: LogPlayIntent(),
            phrases: [
                "Log play in \(.applicationName)",
                "\(.applicationName) log play",
                "Record play in \(.applicationName)",
                "Log play in \(.applicationName)"
            ],
            shortTitle: "Log play",
            systemImageName: "tennisball"
        )
    }
}

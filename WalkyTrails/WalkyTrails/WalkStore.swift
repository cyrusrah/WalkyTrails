//
//  WalkStore.swift
//  WalkyTrails
//

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

    func endWalk() {
        guard var walk = currentWalk else { return }
        walk.end()
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

    func addEventToCurrentWalk(_ type: WalkEvent.EventType) {
        guard var walk = currentWalk else { return }
        walk.addEvent(type)
        currentWalk = walk
    }

    func updateCurrentWalk(_ walk: Walk) {
        currentWalk = walk
    }
}

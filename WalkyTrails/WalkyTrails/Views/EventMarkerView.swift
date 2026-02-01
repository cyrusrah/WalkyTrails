//
//  EventMarkerView.swift
//  WalkyTrails
//
//  Reusable event marker for map annotations (icon + optional dog ring).
//

import MapKit
import SwiftUI

struct EventMarkerView: View {
    let event: WalkEvent
    let dogIds: [UUID]

    var body: some View {
        let ringColor = event.dogId.flatMap { DogColors.color(for: $0, in: dogIds) }
        ZStack {
            Image(systemName: self.iconName(for: event.type))
                .font(.title2)
                .foregroundStyle(self.displayColor(for: event.type))
                .padding(8)
                .background(.background, in: Circle())
                .shadow(radius: 2)
            if let color = ringColor {
                Circle()
                    .stroke(color, lineWidth: 3)
                    .frame(width: 44, height: 44)
            }
        }
        .accessibilityHidden(true)
    }

    private func iconName(for type: WalkEvent.EventType) -> String {
        switch type {
        case .pee: return "drop.fill"
        case .poop: return "leaf.fill"
        case .water: return "cup.and.saucer.fill"
        case .play: return "tennisball.fill"
        }
    }

    private func displayColor(for type: WalkEvent.EventType) -> Color {
        switch type {
        case .pee: return .blue
        case .poop: return .brown
        case .water: return .cyan
        case .play: return .orange
        }
    }
}

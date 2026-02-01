//
//  DuringWalkView.swift
//  WalkyTrails
//

import AppIntents
import CoreLocation
import MapKit
import SwiftUI

struct DuringWalkView: View {
    @ObservedObject var store: WalkStore
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var settings: SettingsStore

    private var currentWalk: Walk? { store.currentWalk }

    var body: some View {
        VStack(spacing: 0) {
            if let walk = currentWalk {
                walkMap(walk: walk)
                walkControls(walk: walk)
            }
        }
        .onChange(of: locationManager.distanceMeters) { _, newDistance in
            store.updateCurrentWalkDistance(newDistance)
        }
    }

    @ViewBuilder
    private func walkMap(walk: Walk) -> some View {
        Map(initialPosition: .userLocation(fallback: .automatic)) {
            UserAnnotation()
            if !locationManager.routeCoordinates.isEmpty {
                MapPolyline(coordinates: locationManager.routeCoordinates)
                    .stroke(.tint, lineWidth: 4)
            }
            ForEach(walk.events.filter { $0.coordinate != nil }, id: \.id) { event in
                if let coord = event.coordinate {
                    Annotation("", coordinate: CLLocationCoordinate2D(latitude: coord.latitude, longitude: coord.longitude)) {
                        eventMarker(event.type)
                    }
                }
            }
        }
        .mapStyle(settings.mapStylePreference.mapStyle)
        .frame(height: 220)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Walk map showing route and event markers")
        .accessibilityHint("Shows your current path and where you logged pee, poop, water, or play")
    }

    @ViewBuilder
    private func walkControls(walk: Walk) -> some View {
        VStack(spacing: 16) {
            Text("Walk in progress")
                .font(.headline)
                .foregroundStyle(.secondary)
                .accessibilityAddTraits(.isHeader)
            TimelineView(.periodic(from: .now, by: 1)) { context in
                Text(formattedDuration(walk.startTime, now: context.date))
                    .font(.system(.largeTitle, design: .monospaced))
                    .contentTransition(.numericText())
                    .accessibilityLabel("Elapsed time")
                    .accessibilityValue(formattedDuration(walk.startTime, now: context.date))
            }
            if locationManager.distanceMeters > 0 {
                Text(settings.formattedDistance(locationManager.distanceMeters))
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Distance walked")
                    .accessibilityValue(settings.formattedDistance(locationManager.distanceMeters))
            }
            eventButtons
            Spacer(minLength: 8)
            endWalkButton
        }
        .padding()
    }

    private var eventButtons: some View {
        HStack(spacing: 12) {
            Button {
                store.addEventToCurrentWalk(.pee, at: locationManager.currentLocation?.coordinate)
                LogPeeIntent().donate()
            } label: { Label("Pee", systemImage: "drop") }
            .buttonStyle(.bordered)
            .accessibilityLabel("Log pee")
            .accessibilityHint("Records a pee event at current location")
            Button {
                store.addEventToCurrentWalk(.poop, at: locationManager.currentLocation?.coordinate)
                LogPoopIntent().donate()
            } label: { Label("Poop", systemImage: "leaf") }
            .buttonStyle(.bordered)
            .accessibilityLabel("Log poop")
            .accessibilityHint("Records a poop event at current location")
            Button {
                store.addEventToCurrentWalk(.water, at: locationManager.currentLocation?.coordinate)
                LogWaterIntent().donate()
            } label: { Label("Water", systemImage: "cup.and.saucer") }
            .buttonStyle(.bordered)
            .accessibilityLabel("Log water")
            .accessibilityHint("Records a water break at current location")
            Button {
                store.addEventToCurrentWalk(.play, at: locationManager.currentLocation?.coordinate)
                LogPlayIntent().donate()
            } label: { Label("Play", systemImage: "tennisball") }
            .buttonStyle(.bordered)
            .accessibilityLabel("Log play")
            .accessibilityHint("Records a play event at current location")
        }
    }

    private var endWalkButton: some View {
        Button(role: .destructive) {
            store.updateCurrentWalkDistance(locationManager.distanceMeters)
            store.endWalk(withRoute: locationManager.routeCoordinates)
        } label: {
            Label("End Walk", systemImage: "stop.circle.fill")
                .font(.title3)
                .frame(maxWidth: .infinity)
                .padding()
        }
        .buttonStyle(.borderedProminent)
        .padding(.horizontal)
        .accessibilityLabel("End walk")
        .accessibilityHint("Stops the walk and shows summary to save or discard")
    }

    @ViewBuilder
    private func eventMarker(_ type: WalkEvent.EventType) -> some View {
        Image(systemName: eventIcon(for: type))
            .font(.title2)
            .foregroundStyle(eventColor(for: type))
            .padding(8)
            .background(.background, in: Circle())
            .shadow(radius: 2)
            .accessibilityHidden(true) // Parent annotation has label
    }

    private func eventIcon(for type: WalkEvent.EventType) -> String {
        switch type {
        case .pee: return "drop.fill"
        case .poop: return "leaf.fill"
        case .water: return "cup.and.saucer.fill"
        case .play: return "tennisball.fill"
        }
    }

    private func eventColor(for type: WalkEvent.EventType) -> Color {
        switch type {
        case .pee: return .blue
        case .poop: return .brown
        case .water: return .cyan
        case .play: return .orange
        }
    }

    private func formattedDuration(_ from: Date, now: Date = Date()) -> String {
        let interval = now.timeIntervalSince(from)
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    DuringWalkView(store: {
        let s = WalkStore()
        s.startWalk()
        return s
    }(), locationManager: LocationManager(), settings: SettingsStore())
}

//
//  DuringWalkView.swift
//  WalkyTrails
//

import CoreLocation
import MapKit
import SwiftUI

struct DuringWalkView: View {
    @ObservedObject var store: WalkStore
    @ObservedObject var locationManager: LocationManager

    private var currentWalk: Walk? { store.currentWalk }

    var body: some View {
        VStack(spacing: 0) {
            if let walk = currentWalk {
                Map(initialPosition: .userLocation(fallback: .automatic)) {
                    UserAnnotation()
                    if !locationManager.routeCoordinates.isEmpty {
                        MapPolyline(coordinates: locationManager.routeCoordinates)
                            .stroke(.tint, lineWidth: 4)
                    }
                    ForEach(walk.events.filter { $0.coordinate != nil }) { event in
                        if let coord = event.coordinate {
                            Annotation("", coordinate: CLLocationCoordinate2D(latitude: coord.latitude, longitude: coord.longitude)) {
                                eventMarker(event.type)
                            }
                        }
                    }
                }
                .mapStyle(.standard(elevation: .realistic))
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)

                VStack(spacing: 16) {
                    Text("Walk in progress")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        Text(formattedDuration(walk.startTime, now: context.date))
                            .font(.system(.largeTitle, design: .monospaced))
                    }
                    if locationManager.distanceMeters > 0 {
                        Text(formattedDistance(locationManager.distanceMeters))
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                    HStack(spacing: 16) {
                        Button {
                            store.addEventToCurrentWalk(.pee, at: locationManager.currentLocation?.coordinate)
                        } label: {
                            Label("Pee", systemImage: "drop")
                        }
                        .buttonStyle(.bordered)
                        Button {
                            store.addEventToCurrentWalk(.poop, at: locationManager.currentLocation?.coordinate)
                        } label: {
                            Label("Poop", systemImage: "leaf")
                        }
                        .buttonStyle(.bordered)
                    }
                    Spacer(minLength: 8)
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
                }
                .padding()
            }
        }
        .onChange(of: locationManager.distanceMeters) { _, newDistance in
            store.updateCurrentWalkDistance(newDistance)
        }
    }

    @ViewBuilder
    private func eventMarker(_ type: WalkEvent.EventType) -> some View {
        Image(systemName: type == .pee ? "drop.fill" : "leaf.fill")
            .font(.title2)
            .foregroundStyle(type == .pee ? .blue : .brown)
            .padding(8)
            .background(.background, in: Circle())
            .shadow(radius: 2)
    }

    private func formattedDistance(_ meters: Double) -> String {
        if meters >= 1000 {
            return String(format: "%.2f km", meters / 1000)
        } else {
            return String(format: "%.0f m", meters)
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
    }(), locationManager: LocationManager())
}

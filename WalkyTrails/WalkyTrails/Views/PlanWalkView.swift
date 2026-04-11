//
//  PlanWalkView.swift
//  WalkyTrails
//

import CoreLocation
import MapKit
import SwiftUI

private struct PlanWaypoint: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

/// MapKit walking directions between user-placed waypoints, then start an active walk with the planned polyline.
struct PlanWalkView: View {
    let dogIds: [UUID]
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: WalkStore
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var settings: SettingsStore

    @State private var waypointPins: [PlanWaypoint] = []
    @State private var isBuildingRoute = false
    @State private var routeErrorMessage: String?
    /// Explicit camera so the map does not default to a world-scale view.
    @State private var mapCameraPosition: MapCameraPosition = .region(Self.defaultPlanningRegion)
    /// After first GPS-based center while waypoints are empty, ignore further location drift.
    @State private var didLockPlanningCameraFromLocation = false

    /// Fallback when GPS is not ready yet (~few city blocks; replaced after first location fix).
    private static let defaultPlanningRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.78, longitude: -122.42),
        span: MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04)
    )

    var body: some View {
        VStack(spacing: 0) {
            mapSection
            VStack(alignment: .leading, spacing: 12) {
                Text("Tap the map to add stops in order. You need at least two points. We build a walking route along paths and streets between them.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if let msg = routeErrorMessage {
                    Text(msg)
                        .font(.footnote)
                        .foregroundStyle(.orange)
                }
                Button("Use my location as first stop") {
                    addCurrentLocationAsWaypoint()
                }
                .buttonStyle(.bordered)
                .disabled(locationManager.currentLocation == nil || isBuildingRoute)
                HStack(spacing: 12) {
                    Button("Remove last") {
                        _ = waypointPins.popLast()
                        routeErrorMessage = nil
                    }
                    .disabled(waypointPins.isEmpty || isBuildingRoute)
                    Button("Clear all") {
                        waypointPins.removeAll()
                        routeErrorMessage = nil
                    }
                    .disabled(waypointPins.isEmpty || isBuildingRoute)
                }
            }
            .padding()
            Spacer(minLength: 0)
        }
        .navigationTitle("Plan walk")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
                .disabled(isBuildingRoute)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Start walk") {
                    Task { await startWalkWithPlannedRoute() }
                }
                .disabled(waypointPins.count < 2 || isBuildingRoute)
                .fontWeight(.semibold)
            }
        }
        .overlay {
            if isBuildingRoute {
                ZStack {
                    Color.black.opacity(0.25)
                    ProgressView("Building route…")
                        .padding(24)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
                .ignoresSafeArea()
            }
        }
        .onAppear {
            locationManager.requestPermission()
            locationManager.startPreviewLocationUpdates()
            refreshPlanningMapCamera()
        }
        .onChange(of: waypointPins.map(\.id)) { _, _ in
            if waypointPins.isEmpty {
                didLockPlanningCameraFromLocation = false
            }
            refreshPlanningMapCamera()
        }
        .onChange(of: locationManager.currentLocation) { _, _ in
            guard waypointPins.isEmpty, !didLockPlanningCameraFromLocation else { return }
            refreshPlanningMapCamera()
        }
        .onDisappear {
            if store.currentWalk == nil {
                locationManager.stopPreviewLocationUpdates()
            }
        }
    }

    private var mapSection: some View {
        MapReader { proxy in
            Map(position: $mapCameraPosition) {
                UserAnnotation()
                ForEach(Array(waypointPins.enumerated()), id: \.element.id) { index, pin in
                    Annotation("", coordinate: pin.coordinate) {
                        ZStack {
                            Circle()
                                .fill(Color.accentColor)
                                .frame(width: 28, height: 28)
                            Text("\(index + 1)")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white)
                        }
                        .accessibilityLabel("Waypoint \(index + 1)")
                    }
                }
            }
            .mapStyle(settings.mapStylePreference.mapStyle)
            .onTapGesture { position in
                guard !isBuildingRoute, let coord = proxy.convert(position, from: .local) else { return }
                waypointPins.append(PlanWaypoint(coordinate: coord))
                routeErrorMessage = nil
            }
        }
        .frame(height: 340)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Map for planning")
        .accessibilityHint("Double tap and drag to explore. Tap once to add a waypoint.")
    }

    /// Keeps planning map at a walkable zoom: waypoints > user location > default region.
    private func refreshPlanningMapCamera() {
        if waypointPins.count >= 2 {
            mapCameraPosition = .region(WalkMapView.regionFitting(coordinates: waypointPins.map(\.coordinate)))
            return
        }
        if waypointPins.count == 1 {
            let c = waypointPins[0].coordinate
            mapCameraPosition = .region(
                MKCoordinateRegion(center: c, span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02))
            )
            return
        }
        if let loc = locationManager.currentLocation,
           loc.horizontalAccuracy > 0, loc.horizontalAccuracy < 3000 {
            mapCameraPosition = .region(
                MKCoordinateRegion(center: loc.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.022, longitudeDelta: 0.022))
            )
            didLockPlanningCameraFromLocation = true
            return
        }
        mapCameraPosition = .region(Self.defaultPlanningRegion)
    }

    private func addCurrentLocationAsWaypoint() {
        guard let coord = locationManager.currentLocation?.coordinate else {
            routeErrorMessage = "Location not available yet — wait a moment or check permissions."
            return
        }
        waypointPins.insert(PlanWaypoint(coordinate: coord), at: 0)
        routeErrorMessage = nil
        refreshPlanningMapCamera()
    }

    @MainActor
    private func startWalkWithPlannedRoute() async {
        guard waypointPins.count >= 2 else { return }
        isBuildingRoute = true
        routeErrorMessage = nil
        let coords = waypointPins.map(\.coordinate)
        let stitched = await WalkingDirectionsService.stitchWalkingRoute(waypoints: coords)
        isBuildingRoute = false
        let planned = stitched.map { Coordinate(latitude: $0.latitude, longitude: $0.longitude) }
        guard planned.count >= 2 else {
            routeErrorMessage = "Could not build a route. Try different points or check network."
            return
        }
        store.startWalk(dogIds: dogIds, plannedRouteCoordinates: planned)
        dismiss()
    }
}

#Preview {
    NavigationStack {
        PlanWalkView(dogIds: [])
            .environmentObject(WalkStore())
            .environmentObject(LocationManager())
            .environmentObject(SettingsStore())
    }
}

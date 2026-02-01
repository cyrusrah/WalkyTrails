//
//  SettingsStore.swift
//  WalkyTrails
//

import MapKit
import SwiftUI

/// Distance unit preference.
enum DistanceUnit: String, Codable, CaseIterable {
    case kilometers = "km"
    case miles = "mi"

    var displayName: String {
        switch self {
        case .kilometers: return "Kilometers"
        case .miles: return "Miles"
        }
    }
}

/// Date display style for walk dates.
enum DateStylePreference: String, Codable, CaseIterable {
    case short   // e.g. 1/31/26
    case medium  // e.g. Jan 31, 2026
    case long    // e.g. January 31, 2026

    var displayName: String {
        switch self {
        case .short: return "Short"
        case .medium: return "Medium"
        case .long: return "Long"
        }
    }

    var dateStyle: DateFormatter.Style {
        switch self {
        case .short: return .short
        case .medium: return .medium
        case .long: return .long
        }
    }
}

/// Map style preference.
enum MapStylePreference: String, Codable, CaseIterable {
    case standard
    case hybrid
    case imagery

    var displayName: String {
        switch self {
        case .standard: return "Standard"
        case .hybrid: return "Hybrid"
        case .imagery: return "Satellite"
        }
    }

    @available(iOS 17.0, *)
    var mapStyle: MapStyle {
        switch self {
        case .standard: return .standard(elevation: .realistic)
        case .hybrid: return .hybrid(elevation: .realistic)
        case .imagery: return .imagery(elevation: .realistic)
        }
    }
}

/// Persists app settings. Uses UserDefaults.
final class SettingsStore: ObservableObject {
    static let distanceUnitKey = "walkyTrails.distanceUnit"
    static let dateStyleKey = "walkyTrails.dateStyle"
    static let mapStyleKey = "walkyTrails.mapStyle"

    @Published var distanceUnit: DistanceUnit {
        didSet { UserDefaults.standard.set(distanceUnit.rawValue, forKey: Self.distanceUnitKey) }
    }
    @Published var dateStyle: DateStylePreference {
        didSet { UserDefaults.standard.set(dateStyle.rawValue, forKey: Self.dateStyleKey) }
    }
    @Published var mapStylePreference: MapStylePreference {
        didSet { UserDefaults.standard.set(mapStylePreference.rawValue, forKey: Self.mapStyleKey) }
    }

    init() {
        self.distanceUnit = (UserDefaults.standard.string(forKey: Self.distanceUnitKey)).flatMap { DistanceUnit(rawValue: $0) } ?? .kilometers
        self.dateStyle = (UserDefaults.standard.string(forKey: Self.dateStyleKey)).flatMap { DateStylePreference(rawValue: $0) } ?? .medium
        self.mapStylePreference = (UserDefaults.standard.string(forKey: Self.mapStyleKey)).flatMap { MapStylePreference(rawValue: $0) } ?? .standard
    }

    /// Formatted distance string for the given meters (uses current unit).
    func formattedDistance(_ meters: Double) -> String {
        switch distanceUnit {
        case .kilometers:
            if meters >= 1000 {
                return String(format: "%.2f km", meters / 1000)
            } else {
                return String(format: "%.0f m", meters)
            }
        case .miles:
            let miles = meters / 1609.344
            if miles >= 1 {
                return String(format: "%.2f mi", miles)
            } else {
                let feet = meters * 3.28084
                return String(format: "%.0f ft", feet)
            }
        }
    }

    /// Formatted distance for stats (e.g. "12.5 km" or "7.8 mi") — always in the chosen unit, no m/ft for small values in stats context.
    func formattedDistanceShort(_ meters: Double) -> String {
        switch distanceUnit {
        case .kilometers:
            return String(format: "%.1f km", meters / 1000)
        case .miles:
            return String(format: "%.1f mi", meters / 1609.344)
        }
    }

    private lazy var dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = dateStyle.dateStyle
        f.timeStyle = .none
        return f
    }()

    private lazy var timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .short
        return f
    }()

    /// Formatted date string (date only) using current preference.
    func formattedDate(_ date: Date) -> String {
        dateFormatter.dateStyle = dateStyle.dateStyle
        return dateFormatter.string(from: date)
    }

    /// Formatted time string (time only).
    func formattedTime(_ date: Date) -> String {
        return timeFormatter.string(from: date)
    }
}

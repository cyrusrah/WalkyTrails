//
//  WeatherService.swift
//  WalkyTrails
//

import Foundation
import SwiftUI

/// Current weather from Open-Meteo (no API key). Snapshot can be saved with a walk.
struct WeatherSnapshot {
    let temperatureCelsius: Double
    let conditionDescription: String
    let weatherCode: Int
}

/// Rule-based suggestion (e.g. hot, cold, rain soon).
struct WeatherSuggestion {
    let message: String
}

final class WeatherService: ObservableObject {
    @Published var currentWeather: WeatherSnapshot?
    @Published var suggestion: WeatherSuggestion?

    private var overrideSnapshot: WeatherSnapshot?
    private var temperatureUnit: String = "celsius"

    static func mockSnapshot(debugModeRaw: String?) -> WeatherSnapshot? {
        guard let raw = debugModeRaw else { return nil }
        switch raw {
        case "hot":
            return WeatherSnapshot(temperatureCelsius: 35, conditionDescription: "Clear", weatherCode: 0)
        case "cold":
            return WeatherSnapshot(temperatureCelsius: -5, conditionDescription: "Clear", weatherCode: 0)
        case "rain":
            return WeatherSnapshot(temperatureCelsius: 12, conditionDescription: "Rain", weatherCode: 61)
        default: return nil
        }
    }

    func setOverride(_ snapshot: WeatherSnapshot?) {
        overrideSnapshot = snapshot
        if let s = snapshot {
            currentWeather = s
            suggestion = suggestionFor(snapshot: s)
        } else {
            suggestion = nil
        }
    }

    func clearOverride() {
        overrideSnapshot = nil
    }

    func setTemperatureUnit(_ unit: String) {
        temperatureUnit = unit
    }

    func load(latitude: Double, longitude: Double, temperatureUnit: String = "celsius") {
        self.temperatureUnit = temperatureUnit
        if overrideSnapshot != nil { return }
        let url = URL(string: "https://api.open-meteo.com/v1/forecast?latitude=\(latitude)&longitude=\(longitude)&current=temperature_2m,weather_code&timezone=auto")!
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let current = json["current"] as? [String: Any],
                  let temp = current["temperature_2m"] as? Double,
                  let code = current["weather_code"] as? Int else { return }
            let desc = Self.conditionDescription(for: code)
            let snapshot = WeatherSnapshot(temperatureCelsius: temp, conditionDescription: desc, weatherCode: code)
            DispatchQueue.main.async {
                self?.currentWeather = snapshot
                self?.suggestion = self?.suggestionFor(snapshot: snapshot)
            }
        }.resume()
    }

    private static func conditionDescription(for code: Int) -> String {
        switch code {
        case 0: return "Clear"
        case 1, 2, 3: return "Partly cloudy"
        case 45, 48: return "Foggy"
        case 51...67: return "Drizzle"
        case 71...77: return "Snow"
        case 80...82: return "Rain"
        case 85, 86: return "Snow"
        case 95...99: return "Thunderstorm"
        default: return "Cloudy"
        }
    }

    private func suggestionFor(snapshot: WeatherSnapshot) -> WeatherSuggestion? {
        let temp = snapshot.temperatureCelsius
        if temp >= 32 { return WeatherSuggestion(message: "Hot — keep it short and shady.") }
        if temp < 0 { return WeatherSuggestion(message: "Cold — keep it short and warm up after.") }
        if snapshot.weatherCode >= 61 && snapshot.weatherCode <= 67 {
            return WeatherSuggestion(message: "Rain — consider a shorter walk.")
        }
        return nil
    }

    /// For saving with a walk (SavedWeather).
    var currentWeatherForSave: SavedWeather? {
        guard let w = currentWeather ?? overrideSnapshot else { return nil }
        return SavedWeather(temperatureCelsius: w.temperatureCelsius, conditionDescription: w.conditionDescription, weatherCode: w.weatherCode)
    }
}

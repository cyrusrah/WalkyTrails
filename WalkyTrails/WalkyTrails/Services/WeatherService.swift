//
//  WeatherService.swift
//  WalkyTrails
//

import Foundation

/// Snapshot of current weather (and next-hour precipitation) for display and suggestions.
struct WeatherSnapshot {
    let temperatureCelsius: Double
    let feelsLikeCelsius: Double?
    let weatherCode: Int
    let conditionDescription: String
    /// Precipitation in mm expected in the next hour (from hourly forecast).
    let precipitationNextHourMm: Double?
    /// Precipitation probability 0...100 for next hour.
    let precipitationProbabilityNextHour: Int?
}

// MARK: - Open-Meteo API (no API key required)

private struct OpenMeteoResponse: Decodable {
    let current: Current?
    let hourly: Hourly?

    struct Current: Decodable {
        let temperature_2m: Double?
        let apparent_temperature: Double?
        let weather_code: Int?
        let precipitation: Double?
    }

    struct Hourly: Decodable {
        let time: [String]?
        let precipitation: [Double]?
        let precipitation_probability: [Int]?
    }
}

/// Maps WMO weather code to short description for UI.
private func conditionDescription(for code: Int) -> String {
    switch code {
    case 0: return "Clear"
    case 1: return "Mainly clear"
    case 2: return "Partly cloudy"
    case 3: return "Overcast"
    case 45, 48: return "Foggy"
    case 51, 53, 55: return "Drizzle"
    case 56, 57: return "Freezing drizzle"
    case 61, 63, 65: return "Rain"
    case 66, 67: return "Freezing rain"
    case 71, 73, 75, 77: return "Snow"
    case 80, 81, 82: return "Showers"
    case 85, 86: return "Snow showers"
    case 95: return "Thunderstorm"
    case 96, 99: return "Thunderstorm with hail"
    default: return "Unknown"
    }
}

/// Fetches current weather from Open-Meteo. No API key required.
final class WeatherService: ObservableObject {
    @Published private(set) var currentWeather: WeatherSnapshot?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let session: URLSession
    private let decoder = JSONDecoder()

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// Debug/testing: show a mock snapshot instead of fetching (e.g. to test Hot/Cold/Rain suggestions).
    func setOverride(_ snapshot: WeatherSnapshot?) {
        currentWeather = snapshot
        isLoading = false
        errorMessage = nil
    }

    /// Clear debug override so the next load fetches real weather.
    func clearOverride() {
        currentWeather = nil
    }

#if DEBUG
    /// Returns a mock snapshot for the given debug mode raw value ("simulateHot", "simulateCold", "simulateRain"); nil for "live" or unknown.
    static func mockSnapshot(debugModeRaw: String) -> WeatherSnapshot? {
        switch debugModeRaw {
        case "simulateHot":
            return WeatherSnapshot(temperatureCelsius: 35, feelsLikeCelsius: 38, weatherCode: 0, conditionDescription: "Clear", precipitationNextHourMm: nil, precipitationProbabilityNextHour: nil)
        case "simulateCold":
            return WeatherSnapshot(temperatureCelsius: -5, feelsLikeCelsius: -8, weatherCode: 0, conditionDescription: "Clear", precipitationNextHourMm: nil, precipitationProbabilityNextHour: nil)
        case "simulateRain":
            return WeatherSnapshot(temperatureCelsius: 15, feelsLikeCelsius: 14, weatherCode: 61, conditionDescription: "Rain", precipitationNextHourMm: 2.0, precipitationProbabilityNextHour: 70)
        default:
            return nil
        }
    }
#endif

    /// Fetches weather for the given coordinates. Pass temperatureUnit "celsius" or "fahrenheit"; API returns values in that unit (we always parse and store as Celsius for internal use).
    func load(latitude: Double, longitude: Double, temperatureUnit: String = "celsius") {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "current", value: "temperature_2m,apparent_temperature,weather_code,precipitation"),
            URLQueryItem(name: "hourly", value: "precipitation_probability,precipitation"),
            URLQueryItem(name: "temperature_unit", value: temperatureUnit),
            URLQueryItem(name: "timezone", value: "auto"),
            URLQueryItem(name: "forecast_hours", value: "2")
        ]
        guard let url = components.url else {
            isLoading = false
            return
        }

        let task = session.dataTask(with: url) { [weak self] data, _, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    return
                }
                guard let data = data else {
                    self?.errorMessage = "No data"
                    return
                }
                do {
                    let response = try self?.decoder.decode(OpenMeteoResponse.self, from: data)
                    self?.currentWeather = self?.parseSnapshot(from: response, temperatureUnit: temperatureUnit)
                    self?.errorMessage = nil
                } catch {
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
        task.resume()
    }
}

// MARK: - Walk suggestions (rule-based)

enum WeatherSuggestion {
    /// One-line suggestion for dog walkers; nil if no rule applies. Uses Celsius internally.
    static func suggestion(for weather: WeatherSnapshot?) -> String? {
        guard let w = weather else { return nil }
        if let rain = rainSoon(w) { return rain }
        if let hot = hot(w) { return hot }
        if let cold = cold(w) { return cold }
        return nil
    }

    private static func rainSoon(_ w: WeatherSnapshot) -> String? {
        let prob = w.precipitationProbabilityNextHour ?? 0
        let mm = w.precipitationNextHourMm ?? 0
        if prob >= 50 || mm >= 0.5 { return "Rain soon — consider a shorter walk." }
        return nil
    }

    private static func hot(_ w: WeatherSnapshot) -> String? {
        let feels = w.feelsLikeCelsius ?? w.temperatureCelsius
        if feels >= 32 { return "Hot — keep it short and shady." }
        return nil
    }

    private static func cold(_ w: WeatherSnapshot) -> String? {
        if w.temperatureCelsius < 0 { return "Cold — keep it short and warm up after." }
        return nil
    }
}

// MARK: - Private parsing

private extension WeatherService {
    func parseSnapshot(from response: OpenMeteoResponse?, temperatureUnit: String) -> WeatherSnapshot? {
        guard let current = response?.current else { return nil }
        let temp = current.temperature_2m ?? 0
        let tempCelsius = temperatureUnit == "fahrenheit" ? (temp - 32) * 5 / 9 : temp
        let feels = current.apparent_temperature
        let feelsCelsius: Double? = feels.map { temperatureUnit == "fahrenheit" ? ($0 - 32) * 5 / 9 : $0 }
        let code = current.weather_code ?? 0

        var precipNextHour: Double?
        var precipProbNextHour: Int?
        if let hourly = response?.hourly,
           let times = hourly.time,
           let precip = hourly.precipitation,
           let prob = hourly.precipitation_probability,
           times.count >= 2, precip.count >= 2, prob.count >= 2 {
            precipNextHour = precip[1]
            precipProbNextHour = prob[1]
        }

        return WeatherSnapshot(
            temperatureCelsius: tempCelsius,
            feelsLikeCelsius: feelsCelsius,
            weatherCode: code,
            conditionDescription: conditionDescription(for: code),
            precipitationNextHourMm: precipNextHour,
            precipitationProbabilityNextHour: precipProbNextHour
        )
    }
}

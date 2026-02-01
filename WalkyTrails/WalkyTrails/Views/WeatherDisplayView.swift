//
//  WeatherDisplayView.swift
//  WalkyTrails
//
//  Reusable weather row: temperature + condition, optional suggestion line.
//

import SwiftUI

struct WeatherDisplayView: View {
    let temperatureCelsius: Double
    let conditionDescription: String
    var suggestionMessage: String? = nil
    @ObservedObject var settings: SettingsStore

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Image(systemName: "cloud.sun")
                    .foregroundStyle(.secondary)
                Text(settings.formattedTemperature(celsius: temperatureCelsius) + " · " + conditionDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Weather: \(settings.formattedTemperature(celsius: temperatureCelsius)), \(conditionDescription)")
            if let message = suggestionMessage {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

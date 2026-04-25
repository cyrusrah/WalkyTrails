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
                    .foregroundStyle(WTTheme.ColorToken.mutedText)
                Text(settings.formattedTemperature(celsius: temperatureCelsius) + " · " + conditionDescription)
                    .font(WTTheme.Typography.callout)
                    .foregroundStyle(WTTheme.ColorToken.mutedText)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: WTTheme.Radius.sm, style: .continuous)
                    .fill(.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: WTTheme.Radius.sm, style: .continuous)
                            .stroke(WTTheme.ColorToken.stone, lineWidth: WTTheme.Stroke.hairline)
                    )
            )
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Weather: \(settings.formattedTemperature(celsius: temperatureCelsius)), \(conditionDescription)")
            if let message = suggestionMessage {
                Text(message)
                    .font(WTTheme.Typography.caption)
                    .foregroundStyle(WTTheme.ColorToken.mutedText)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

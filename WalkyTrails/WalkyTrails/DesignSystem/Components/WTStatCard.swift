import SwiftUI

struct WTStatCard: View {
    let value: String
    let label: String
    var footer: String? = nil
    var accent: SwiftUI.Color? = nil

    var body: some View {
        WTCard {
            VStack(alignment: .leading, spacing: 10) {
                Text(label.uppercased())
                    .font(WTTheme.Typography.statLabel)
                    .foregroundStyle(WTTheme.ColorToken.mutedText)
                    .kerning(0.7)

                Text(value)
                    .font(WTTheme.Typography.statValue)
                    .foregroundStyle(WTTheme.ColorToken.charcoal)

                if let footer {
                    Text(footer)
                        .font(WTTheme.Typography.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .overlay(alignment: .topTrailing) {
                if let accent {
                    Circle()
                        .fill(accent)
                        .frame(width: 8, height: 8)
                        .padding(.top, 4)
                }
            }
        }
    }
}


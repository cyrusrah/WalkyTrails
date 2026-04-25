import SwiftUI

struct WTChip: View {
    let title: String
    var systemImage: String?
    var isSelected: Bool = false
    var action: (() -> Void)?

    var body: some View {
        Button {
            action?()
        } label: {
            HStack(spacing: 6) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .imageScale(.small)
                }
                Text(title)
                    .lineLimit(1)
            }
            .font(.system(.callout, design: .default).weight(.semibold))
            .foregroundStyle(isSelected ? .white : WTTheme.ColorToken.charcoal)
            .padding(.vertical, 9)
            .padding(.horizontal, 12)
            .background(
                Capsule(style: .continuous)
                    .fill(isSelected ? WTTheme.ColorToken.forest : .white)
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(WTTheme.ColorToken.stone, lineWidth: WTTheme.Stroke.hairline)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}


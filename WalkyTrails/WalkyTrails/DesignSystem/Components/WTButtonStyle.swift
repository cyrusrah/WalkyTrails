import SwiftUI

enum WTButtonVariant {
    case primary
    case secondary
    case destructiveOutline
}

enum WTButtonSize {
    case large
    case medium
    case small

    var verticalPadding: CGFloat {
        switch self {
        case .large: return 14
        case .medium: return 12
        case .small: return 10
        }
    }

    var horizontalPadding: CGFloat {
        switch self {
        case .large: return 16
        case .medium: return 14
        case .small: return 12
        }
    }

    var font: Font {
        switch self {
        case .large: return .system(.title3, design: .default).weight(.semibold)
        case .medium: return .system(.body, design: .default).weight(.semibold)
        case .small: return .system(.callout, design: .default).weight(.semibold)
        }
    }
}

struct WTButtonStyle: ButtonStyle {
    let variant: WTButtonVariant
    let size: WTButtonSize
    var isFullWidth: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        configuration.label
            .font(size.font)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .padding(.vertical, size.verticalPadding)
            .padding(.horizontal, size.horizontalPadding)
            .foregroundStyle(foregroundColor(pressed: pressed))
            .background(background(pressed: pressed))
            .clipShape(RoundedRectangle(cornerRadius: WTTheme.Radius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: WTTheme.Radius.md, style: .continuous)
                    .stroke(borderColor(pressed: pressed), lineWidth: WTTheme.Stroke.hairline)
            )
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }

    private func foregroundColor(pressed: Bool) -> SwiftUI.Color {
        switch variant {
        case .primary:
            return .white
        case .secondary:
            return WTTheme.ColorToken.charcoal
        case .destructiveOutline:
            return WTTheme.ColorToken.brandOrange
        }
    }

    @ViewBuilder
    private func background(pressed: Bool) -> some View {
        switch variant {
        case .primary:
            WTTheme.ColorToken.brandOrange.opacity(pressed ? 0.92 : 1)
        case .secondary:
            SwiftUI.Color.white.opacity(pressed ? 0.95 : 1)
        case .destructiveOutline:
            SwiftUI.Color.white.opacity(pressed ? 0.95 : 1)
        }
    }

    private func borderColor(pressed: Bool) -> SwiftUI.Color {
        switch variant {
        case .primary:
            return .clear
        case .secondary:
            return WTTheme.ColorToken.stone
        case .destructiveOutline:
            return WTTheme.ColorToken.brandOrange.opacity(0.55)
        }
    }
}

extension View {
    func wtButton(_ variant: WTButtonVariant, size: WTButtonSize = .medium, fullWidth: Bool = true) -> some View {
        buttonStyle(WTButtonStyle(variant: variant, size: size, isFullWidth: fullWidth))
    }
}


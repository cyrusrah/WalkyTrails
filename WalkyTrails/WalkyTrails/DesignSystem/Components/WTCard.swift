import SwiftUI

struct WTCard<Content: View>: View {
    private let content: Content
    private let padding: CGFloat

    init(padding: CGFloat = WTTheme.Spacing.md, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.padding = padding
    }

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(WTTheme.ColorToken.warmGrey.opacity(0.001)) // keep hit-testing consistent
            .background(
                RoundedRectangle(cornerRadius: WTTheme.Radius.md, style: .continuous)
                    .fill(.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: WTTheme.Radius.md, style: .continuous)
                            .stroke(WTTheme.ColorToken.stone, lineWidth: WTTheme.Stroke.hairline)
                    )
                    .shadow(
                        color: .black.opacity(WTTheme.Shadow.opacity),
                        radius: WTTheme.Shadow.radius,
                        x: 0,
                        y: WTTheme.Shadow.y
                    )
            )
    }
}


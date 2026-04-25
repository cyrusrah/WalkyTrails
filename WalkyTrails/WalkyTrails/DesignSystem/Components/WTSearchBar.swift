import SwiftUI

struct WTSearchBar: View {
    @Binding var text: String
    var placeholder: String = "Search trails, parks, places…"

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(WTTheme.ColorToken.mutedText)

            TextField(placeholder, text: $text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .foregroundStyle(WTTheme.ColorToken.charcoal)
        }
        .padding(.vertical, 11)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: WTTheme.Radius.md, style: .continuous)
                .fill(.white)
                .overlay(
                    RoundedRectangle(cornerRadius: WTTheme.Radius.md, style: .continuous)
                        .stroke(WTTheme.ColorToken.stone, lineWidth: WTTheme.Stroke.hairline)
                )
        )
    }
}


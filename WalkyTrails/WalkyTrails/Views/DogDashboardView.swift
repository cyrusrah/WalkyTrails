import SwiftUI

struct DogDashboardView: View {
    enum Tab: String, CaseIterable {
        case overview = "Overview"
        case health = "Health"
        case badges = "Badges"
    }

    @EnvironmentObject var store: WalkStore
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var dogStore: DogProfileStore

    let dogId: UUID

    @State private var tab: Tab = .overview

    private var dog: Dog? { dogStore.dog(byId: dogId) }

    private var walksForDog: [Walk] {
        store.walks.filter { $0.dogIds.contains(dogId) }
    }

    private var weekRange: (start: Date, end: Date) {
        let cal = Calendar.current
        let now = Date()
        let start = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? cal.startOfDay(for: now)
        let end = cal.date(byAdding: .day, value: 7, to: start) ?? now
        return (start, end)
    }

    private var walksThisWeek: [Walk] {
        let r = weekRange
        return walksForDog.filter { $0.startTime >= r.start && $0.startTime < r.end }
    }

    private var thisWeekWalkCount: Int { walksThisWeek.count }
    private var thisWeekDistanceMeters: Double { walksThisWeek.reduce(0) { $0 + $1.distanceMeters } }
    private var thisWeekDurationSeconds: Int { Int(walksThisWeek.reduce(0.0) { $0 + $1.durationSeconds }) }

    private var recentWalks: [Walk] { Array(walksForDog.prefix(3)) }

    var body: some View {
        ZStack {
            WTTheme.ColorToken.warmGrey.ignoresSafeArea()

            VStack(spacing: 0) {
                heroHeader

                segmentedTabs
                    .padding(.horizontal, WTTheme.Spacing.lg)
                    .padding(.top, -22)

                Group {
                    switch tab {
                    case .overview:
                        overviewTab
                    case .health:
                        placeholderTab(title: "Health")
                    case .badges:
                        placeholderTab(title: "Badges")
                    }
                }
                .padding(.top, WTTheme.Spacing.md)

                Spacer(minLength: 0)
            }
        }
        .tint(WTTheme.ColorToken.brandOrange)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    if let d = dog {
                        DogProfileView(initialDog: d, isOnboarding: false)
                    } else {
                        DogProfileView(initialDog: nil, isOnboarding: false)
                    }
                } label: {
                    Image(systemName: "pencil")
                        .foregroundStyle(.white)
                }
                .accessibilityLabel("Edit dog profile")
            }
        }
    }

    private var heroHeader: some View {
        ZStack(alignment: .topTrailing) {
            WTTheme.ColorToken.forest
                .frame(height: 280)
                .overlay(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(WTTheme.ColorToken.warmGrey)
                        .frame(height: 40)
                        .offset(y: 20)
                }

            VStack(spacing: 10) {
                dogAvatar

                VStack(spacing: 4) {
                    Text(dog?.name.isEmpty == false ? dog!.name : "Your dog")
                        .font(.system(.title, design: .default).weight(.bold))
                        .foregroundStyle(.white)

                    Text(subtitleText)
                        .font(WTTheme.Typography.callout)
                        .foregroundStyle(.white.opacity(0.85))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 46)
        }
    }

    private var segmentedTabs: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.self) { t in
                Button {
                    withAnimation(.easeOut(duration: 0.18)) { tab = t }
                } label: {
                    VStack(spacing: 8) {
                        Text(t.rawValue)
                            .font(.system(.callout, design: .default).weight(.semibold))
                            .foregroundStyle(tab == t ? WTTheme.ColorToken.charcoal : WTTheme.ColorToken.mutedText)
                            .frame(maxWidth: .infinity)

                        Capsule()
                            .fill(tab == t ? WTTheme.ColorToken.brandOrange : .clear)
                            .frame(height: 3)
                    }
                    .padding(.top, 12)
                }
                .buttonStyle(.plain)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: WTTheme.Radius.md, style: .continuous)
                .fill(.white)
                .overlay(
                    RoundedRectangle(cornerRadius: WTTheme.Radius.md, style: .continuous)
                        .stroke(WTTheme.ColorToken.stone, lineWidth: WTTheme.Stroke.hairline)
                )
        )
    }

    private var overviewTab: some View {
        VStack(alignment: .leading, spacing: WTTheme.Spacing.md) {
            WTCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("This Week")
                        .font(WTTheme.Typography.sectionTitle)
                        .foregroundStyle(WTTheme.ColorToken.charcoal)

                    HStack(spacing: 0) {
                        weekMetric(value: "\(thisWeekWalkCount)", label: "Walks")
                        Divider().overlay(WTTheme.ColorToken.stone)
                        weekMetric(value: settings.formattedDistanceShort(thisWeekDistanceMeters), label: "Distance")
                        Divider().overlay(WTTheme.ColorToken.stone)
                        weekMetric(value: formattedDurationShort(seconds: thisWeekDurationSeconds), label: "Time")
                    }
                }
            }
            .padding(.horizontal, WTTheme.Spacing.lg)

            WTCard {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Activity This Week")
                        .font(WTTheme.Typography.sectionTitle)
                        .foregroundStyle(WTTheme.ColorToken.charcoal)
                    weekBars
                        .frame(height: 84)
                }
            }
            .padding(.horizontal, WTTheme.Spacing.lg)

            WTCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Recent Walks")
                            .font(WTTheme.Typography.sectionTitle)
                            .foregroundStyle(WTTheme.ColorToken.charcoal)
                        Spacer()
                        NavigationLink {
                            WalkHistoryView()
                        } label: {
                            Text("See all")
                                .font(WTTheme.Typography.callout.weight(.semibold))
                                .foregroundStyle(WTTheme.ColorToken.mutedText)
                        }
                    }

                    VStack(spacing: 10) {
                        ForEach(recentWalks) { walk in
                            recentWalkRow(walk: walk)
                            if walk.id != recentWalks.last?.id {
                                Divider().overlay(WTTheme.ColorToken.stone)
                            }
                        }
                        if recentWalks.isEmpty {
                            Text("No walks yet.")
                                .font(WTTheme.Typography.callout)
                                .foregroundStyle(WTTheme.ColorToken.mutedText)
                        }
                    }
                }
            }
            .padding(.horizontal, WTTheme.Spacing.lg)
        }
    }

    private func placeholderTab(title: String) -> some View {
        WTCard {
            ContentUnavailableView(
                title,
                systemImage: "sparkles",
                description: Text("Coming soon.")
            )
        }
        .padding(.horizontal, WTTheme.Spacing.lg)
    }

    private var dogAvatar: some View {
        Group {
            if let data = dog?.photoData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 124, height: 124)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(.white.opacity(0.18))
                    .frame(width: 124, height: 124)
                    .overlay(
                        Image(systemName: "pawprint.fill")
                            .font(.system(size: 44, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.9))
                    )
            }
        }
        .overlay(Circle().stroke(.white.opacity(0.7), lineWidth: 3))
        .shadow(color: .black.opacity(0.18), radius: 18, x: 0, y: 10)
    }

    private var subtitleText: String {
        let breed = dog?.breed.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if breed.isEmpty { return " " }
        return "\(breed) • Walk stats"
    }

    private func weekMetric(value: String, label: String) -> some View {
        VStack(alignment: .center, spacing: 4) {
            Text(value)
                .font(.system(.title3, design: .default).weight(.bold))
                .foregroundStyle(WTTheme.ColorToken.charcoal)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
            Text(label)
                .font(WTTheme.Typography.caption)
                .foregroundStyle(WTTheme.ColorToken.mutedText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
    }

    private var weekBars: some View {
        let cal = Calendar.current
        let start = weekRange.start
        let days = (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: start) }
        let dailyCounts: [Int] = days.map { d in
            walksThisWeek.filter { cal.isDate($0.startTime, inSameDayAs: d) }.count
        }
        let maxCount = max(dailyCounts.max() ?? 1, 1)
        let labels = ["M", "T", "W", "T", "F", "S", "S"]

        return HStack(alignment: .bottom, spacing: 10) {
            ForEach(0..<7, id: \.self) { idx in
                VStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(barColor(count: dailyCounts[idx], maxCount: maxCount))
                        .frame(height: max(10, CGFloat(dailyCounts[idx]) / CGFloat(maxCount) * 54))
                    Text(labels[idx])
                        .font(WTTheme.Typography.caption)
                        .foregroundStyle(WTTheme.ColorToken.mutedText)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func barColor(count: Int, maxCount: Int) -> Color {
        if count <= 0 {
            return WTTheme.ColorToken.stone.opacity(0.9)
        }
        if count >= maxCount {
            return WTTheme.ColorToken.brandOrange
        }
        let t = CGFloat(count) / CGFloat(max(maxCount, 1)) // 0..1
        let opacity = 0.45 + (0.45 * t) // 0.45..0.90
        return WTTheme.ColorToken.forest.opacity(opacity)
    }

    private func recentWalkRow(walk: Walk) -> some View {
        NavigationLink {
            WalkDetailView(walk: walk)
        } label: {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: WTTheme.Radius.sm, style: .continuous)
                    .fill(WTTheme.ColorToken.warmGrey)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: "pawprint.fill")
                            .foregroundStyle(WTTheme.ColorToken.mutedText)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(settings.formattedDate(walk.startTime))
                        .font(.system(.callout, design: .default).weight(.semibold))
                        .foregroundStyle(WTTheme.ColorToken.charcoal)
                    Text("• \(settings.formattedDistanceShort(walk.distanceMeters))")
                        .font(WTTheme.Typography.caption)
                        .foregroundStyle(WTTheme.ColorToken.mutedText)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(WTTheme.ColorToken.mutedText)
            }
        }
        .buttonStyle(.plain)
    }

    private func formattedDurationShort(seconds: Int) -> String {
        let total = max(seconds, 0)
        let hrs = total / 3600
        let mins = (total % 3600) / 60
        if hrs > 0 { return "\(hrs)h \(mins)m" }
        return "\(mins)m"
    }
}

#Preview {
    NavigationStack {
        DogDashboardView(dogId: UUID())
            .environmentObject(WalkStore())
            .environmentObject(SettingsStore())
            .environmentObject(DogProfileStore())
    }
}


//
//  WalkHistoryView.swift
//  WalkyTrails
//

import SwiftUI

struct WalkHistoryView: View {
    @EnvironmentObject var store: WalkStore
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var dogStore: DogProfileStore
    @State private var selectedDogId: UUID?
    @State private var showDeleteAllConfirmation = false

    private var filteredWalks: [Walk] {
        guard let id = selectedDogId else { return store.walks }
        return store.walks.filter { $0.dogIds.contains(id) }
    }

    var body: some View {
        historyContent
        .scrollContentBackground(.hidden)
        .background(WTTheme.ColorToken.warmGrey)
        .tint(WTTheme.ColorToken.brandOrange)
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !store.walks.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Delete all", role: .destructive) {
                        showDeleteAllConfirmation = true
                    }
                    .accessibilityLabel("Delete all walk history")
                }
            }
        }
        .confirmationDialog("Delete all walk history?", isPresented: $showDeleteAllConfirmation, titleVisibility: .visible) {
            Button("Delete all", role: .destructive) {
                store.deleteAllWalks()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This cannot be undone. All saved walks will be removed.")
        }
    }

    @ViewBuilder
    private var historyContent: some View {
        if store.walks.isEmpty {
            ContentUnavailableView(
                "No walks yet",
                systemImage: "figure.walk",
                description: Text("Start a walk from the home screen to see your history here.")
            )
        } else {
            walksList
        }
    }

    private var walksList: some View {
        List {
            if dogStore.dogs.count > 1 {
                Section {
                    Picker("Filter by dog", selection: $selectedDogId) {
                        Text("All dogs").tag(Optional<UUID>.none)
                        ForEach(dogStore.dogs) { dog in
                            Text(dog.name.isEmpty ? "Unnamed" : dog.name).tag(Optional(dog.id))
                        }
                    }
                    .pickerStyle(.menu)
                }
                .listRowBackground(Color.clear)
            }
            ForEach(filteredWalks) { walk in
                NavigationLink {
                    WalkDetailView(walk: walk)
                } label: {
                    walkRow(walk: walk)
                }
                .accessibilityLabel(accessibilityLabel(for: walk))
                .accessibilityHint("Opens walk details")
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
            .onDelete { indexSet in
                let ids = Set(indexSet.map { filteredWalks[$0].id })
                store.deleteWalks(ids: ids)
            }
        }
        .listStyle(.plain)
    }

    private func walkRow(walk: Walk) -> some View {
        WTCard {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(settings.formattedDate(walk.startTime))
                        .font(.system(.headline, design: .default).weight(.semibold))
                        .foregroundStyle(WTTheme.ColorToken.charcoal)
                    Spacer()
                    if walk.distanceMeters > 0 {
                        Text(settings.formattedDistanceShort(walk.distanceMeters))
                            .font(.system(.callout, design: .default).weight(.semibold))
                            .foregroundStyle(WTTheme.ColorToken.mutedText)
                    }
                }

                Text(formattedDuration(seconds: walk.durationSeconds))
                    .font(WTTheme.Typography.callout)
                    .foregroundStyle(WTTheme.ColorToken.mutedText)

                if !walk.events.isEmpty {
                    Text("\(walk.events.count) event(s)")
                        .font(WTTheme.Typography.caption)
                        .foregroundStyle(WTTheme.ColorToken.mutedText)
                }
            }
        }
        .padding(.vertical, WTTheme.Spacing.xxs)
    }

    private func accessibilityLabel(for walk: Walk) -> String {
        "Walk on \(settings.formattedDate(walk.startTime)), \(formattedDuration(seconds: walk.durationSeconds))\(walk.events.isEmpty ? "" : ", \(walk.events.count) events")"
    }
}

#Preview {
    NavigationStack {
        WalkHistoryView()
        .environmentObject({
            let s = WalkStore()
            s.walks = [
                Walk(startTime: Date().addingTimeInterval(-3600), endTime: Date(), distanceMeters: 0),
                Walk(startTime: Date().addingTimeInterval(-86400), endTime: Date().addingTimeInterval(-82800), distanceMeters: 0)
            ]
            return s
        }())
        .environmentObject(SettingsStore())
        .environmentObject(DogProfileStore())
    }
}

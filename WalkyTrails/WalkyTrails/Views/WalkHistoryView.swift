//
//  WalkHistoryView.swift
//  WalkyTrails
//

import SwiftUI

struct WalkHistoryView: View {
    @ObservedObject var store: WalkStore
    @ObservedObject var settings: SettingsStore
    @ObservedObject var dogStore: DogProfileStore
    @State private var selectedDogId: UUID?
    @State private var showDeleteAllConfirmation = false

    private var filteredWalks: [Walk] {
        guard let id = selectedDogId else { return store.walks }
        return store.walks.filter { $0.dogIds.contains(id) }
    }

    var body: some View {
        Group {
            if store.walks.isEmpty {
                ContentUnavailableView(
                    "No walks yet",
                    systemImage: "figure.walk",
                    description: Text("Start a walk from the home screen to see your history here.")
                )
            } else {
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
                    }
                    ForEach(filteredWalks) { walk in
                        NavigationLink {
                            WalkDetailView(store: store, settings: settings, dogStore: dogStore, walk: walk)
                        } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(settings.formattedDate(walk.startTime))
                                .font(.headline)
                            Text(formattedDuration(walk.durationSeconds))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            if !walk.events.isEmpty {
                                Text("\(walk.events.count) event(s)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                        .accessibilityLabel("Walk on \(settings.formattedDate(walk.startTime)), \(formattedDuration(walk.durationSeconds))\(walk.events.isEmpty ? "" : ", \(walk.events.count) events")")
                        .accessibilityHint("Opens walk details")
                    }
                    .onDelete { indexSet in
                        let ids = Set(indexSet.map { filteredWalks[$0].id })
                        store.deleteWalks(ids: ids)
                    }
                }
                .listStyle(.plain)
            }
        }
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

    private func formattedDuration(_ seconds: TimeInterval) -> String {
        let m = Int(seconds) / 60
        let s = Int(seconds) % 60
        return String(format: "%d min %d sec", m, s)
    }
}

#Preview {
    NavigationStack {
        WalkHistoryView(store: {
            let s = WalkStore()
            s.walks = [
                Walk(startTime: Date().addingTimeInterval(-3600), endTime: Date(), distanceMeters: 0),
                Walk(startTime: Date().addingTimeInterval(-86400), endTime: Date().addingTimeInterval(-82800), distanceMeters: 0)
            ]
            return s
        }(), settings: SettingsStore(), dogStore: DogProfileStore())
    }
}

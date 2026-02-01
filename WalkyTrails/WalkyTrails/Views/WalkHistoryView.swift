//
//  WalkHistoryView.swift
//  WalkyTrails
//

import SwiftUI

struct WalkHistoryView: View {
    @ObservedObject var store: WalkStore
    @ObservedObject var settings: SettingsStore
    @ObservedObject var dogStore: DogProfileStore

    @State private var showDeleteAllConfirmation = false

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
                    ForEach(store.walks) { walk in
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
                    .onDelete(perform: deleteWalks)
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !store.walks.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .destructive) {
                        showDeleteAllConfirmation = true
                    } label: {
                        Text("Delete all")
                    }
                    .accessibilityLabel("Delete all walks")
                    .accessibilityHint("Removes all walk history after confirmation")
                }
            }
        }
        .confirmationDialog("Delete all walks?", isPresented: $showDeleteAllConfirmation, titleVisibility: .visible) {
            Button("Delete all", role: .destructive) {
                store.deleteAllWalks()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This cannot be undone. All walk history will be removed.")
        }
    }

    private func deleteWalks(at offsets: IndexSet) {
        let ids = Set(offsets.map { store.walks[$0].id })
        store.deleteWalks(ids: ids)
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

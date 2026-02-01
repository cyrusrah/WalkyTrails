//
//  SettingsView.swift
//  WalkyTrails
//

import MapKit
import SwiftUI
import UniformTypeIdentifiers

/// Wraps a URL for use as sheet(item:).
private struct ShareableExport: Identifiable {
    let id = UUID()
    let url: URL
}

struct SettingsView: View {
    @ObservedObject var settings: SettingsStore
    @ObservedObject var store: WalkStore
    @ObservedObject var dogStore: DogProfileStore

    @State private var shareableExport: ShareableExport?
    @State private var exportError: String?
    @State private var showExportError = false

    @State private var showRestorePicker = false
    @State private var pendingRestore: WalkStore.ExportEnvelope?
    @State private var showRestoreConfirmation = false
    @State private var restoreError: String?
    @State private var showRestoreError = false
    @State private var showRestoreSuccess = false

    var body: some View {
        Form {
            Section {
                Picker("Distance unit", selection: $settings.distanceUnit) {
                    ForEach(DistanceUnit.allCases, id: \.rawValue) { unit in
                        Text(unit.displayName).tag(unit)
                    }
                }
            } header: {
                Text("Units")
            } footer: {
                Text("Used for distance on walks, summary, and stats.")
            }

            Section {
                Picker("Date format", selection: $settings.dateStyle) {
                    ForEach(DateStylePreference.allCases, id: \.rawValue) { style in
                        Text(style.displayName).tag(style)
                    }
                }
            } header: {
                Text("Date format")
            } footer: {
                Text("How walk dates appear in history and detail.")
            }

            Section {
                Picker("Map style", selection: $settings.mapStylePreference) {
                    ForEach(MapStylePreference.allCases, id: \.rawValue) { style in
                        Text(style.displayName).tag(style)
                    }
                }
            } header: {
                Text("Map")
            } footer: {
                Text("Default style for the map during and after walks.")
            }

            Section {
                Button {
                    exportAsJSON(store: store)
                } label: {
                    Label("Export as JSON", systemImage: "doc.text")
                }
                .accessibilityLabel("Export as JSON")
                .accessibilityHint("Saves or shares walk history and dog profile as a backup file")
                Button {
                    exportAsCSV(store: store)
                } label: {
                    Label("Export as CSV", systemImage: "table")
                }
                .accessibilityLabel("Export walk history as CSV")
                .accessibilityHint("Saves or shares all walks as a spreadsheet file")
                Button {
                    showRestorePicker = true
                } label: {
                    Label("Restore from backup", systemImage: "square.and.arrow.down")
                }
                .accessibilityLabel("Restore from backup")
                .accessibilityHint("Pick a previously exported JSON backup to replace current data")
            } header: {
                Text("Export")
            } footer: {
                Text("JSON includes walk history and dog profile (for backup). CSV is walks only. Restore replaces current walks and dog profile with the backup.")
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $shareableExport) { item in
            ShareSheet(activityItems: [item.url])
        }
        .alert("Export failed", isPresented: $showExportError) {
            Button("OK") { showExportError = false; exportError = nil }
        } message: {
            if let msg = exportError { Text(msg) }
        }
        .fileImporter(
            isPresented: $showRestorePicker,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            handleRestoreFileResult(result)
        }
        .alert("Restore from backup?", isPresented: $showRestoreConfirmation) {
            Button("Cancel", role: .cancel) {
                pendingRestore = nil
            }
            Button("Replace", role: .destructive) {
                applyRestore()
            }
        } message: {
            if let envelope = pendingRestore {
                let dogLine = (envelope.dog?.hasContent == true)
                    ? ", dog profile (\(envelope.dog?.name ?? ""))"
                    : ""
                Text("This will replace your current walk history and dog profile with the backup: \(envelope.walks.count) walk(s)\(dogLine). This cannot be undone.")
            }
        }
        .alert("Restore failed", isPresented: $showRestoreError) {
            Button("OK") { showRestoreError = false; restoreError = nil }
        } message: {
            if let msg = restoreError { Text(msg) }
        }
        .alert("Restore complete", isPresented: $showRestoreSuccess) {
            Button("OK") { showRestoreSuccess = false }
        } message: {
            Text("Walk history and dog profile have been restored from the backup.")
        }
    }

    private func exportAsJSON(store: WalkStore) {
        let dog = dogStore.dog.hasContent ? dogStore.dog : nil
        guard let data = store.exportAsJSONData(dog: dog) else {
            exportError = "Could not encode walk data."
            showExportError = true
            return
        }
        let filename = "walkyTrails_walks_\(dateForFilename()).json"
        writeAndShare(data: data, filename: filename, type: UTType.json)
    }

    private func exportAsCSV(store: WalkStore) {
        let csv = store.exportAsCSV()
        guard let data = csv.data(using: .utf8) else {
            exportError = "Could not encode CSV."
            return
        }
        let filename = "walkyTrails_walks_\(dateForFilename()).csv"
        writeAndShare(data: data, filename: filename, type: UTType.commaSeparatedText)
    }

    private func dateForFilename() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmm"
        return formatter.string(from: Date())
    }

    private func writeAndShare(data: Data, filename: String, type: UTType) {
        let tmp = FileManager.default.temporaryDirectory
        let fileURL = tmp.appendingPathComponent(filename)
        do {
            try data.write(to: fileURL)
            shareableExport = ShareableExport(url: fileURL)
        } catch {
            exportError = error.localizedDescription
            showExportError = true
        }
    }

    private func handleRestoreFileResult(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else {
                restoreError = "No file selected."
                showRestoreError = true
                return
            }
            guard url.startAccessingSecurityScopedResource() else {
                restoreError = "Could not access the selected file."
                showRestoreError = true
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }
            do {
                let data = try Data(contentsOf: url)
                guard let envelope = WalkStore.decodeBackup(data) else {
                    restoreError = "This file is not a valid WalkyTrails backup."
                    showRestoreError = true
                    return
                }
                pendingRestore = envelope
                showRestoreConfirmation = true
            } catch {
                restoreError = error.localizedDescription
                showRestoreError = true
            }
        case .failure(let error):
            restoreError = error.localizedDescription
            showRestoreError = true
        }
    }

    private func applyRestore() {
        guard let envelope = pendingRestore else { return }
        store.replaceWalks(with: envelope.walks)
        if let dog = envelope.dog, dog.hasContent {
            dogStore.save(dog)
        }
        pendingRestore = nil
        showRestoreSuccess = true
    }
}

#Preview {
    NavigationStack {
        SettingsView(settings: SettingsStore(), store: WalkStore(), dogStore: DogProfileStore())
    }
}

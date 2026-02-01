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
    @ObservedObject var userStore: UserProfileStore
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
            youSection
            dogsSection
            unitsSection
            dateSection
            mapSection
            weatherTestingSection
            exportSection
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
            Text(restoreConfirmationMessage)
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

    private var youSection: some View {
        Section {
            NavigationLink {
                UserProfileView(userStore: userStore, isOnboarding: false)
            } label: {
                Label("Your profile", systemImage: "person.circle")
            }
        } header: {
            Text("You")
        } footer: {
            Text("Your name and photo (for later community features).")
        }
    }

    private var dogsSection: some View {
        Section {
            ForEach(dogStore.dogs) { dog in
                NavigationLink {
                    DogProfileView(dogStore: dogStore, initialDog: dog, isOnboarding: false)
                } label: {
                    Text(dog.name.isEmpty ? "Unnamed dog" : dog.name)
                }
            }
            NavigationLink {
                DogProfileView(dogStore: dogStore, initialDog: nil, isOnboarding: false)
            } label: {
                Label("Add dog", systemImage: "plus.circle")
            }
        } header: {
            Text("Dogs")
        } footer: {
            Text("Choose who's walking when you start a walk.")
        }
    }

    private var unitsSection: some View {
        Section {
            Picker("Distance unit", selection: $settings.distanceUnit) {
                ForEach(DistanceUnit.allCases, id: \.rawValue) { unit in
                    Text(unit.displayName).tag(unit)
                }
            }
            Picker("Temperature", selection: $settings.temperatureUnit) {
                ForEach(TemperatureUnit.allCases, id: \.rawValue) { unit in
                    Text(unit.displayName).tag(unit)
                }
            }
        } header: {
            Text("Units")
        } footer: {
            Text("Distance is used for walks, summary, and stats. Temperature is used for weather on during-walk and summary.")
        }
    }

    private var dateSection: some View {
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
    }

    private var mapSection: some View {
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
    }

#if DEBUG
    private var weatherTestingSection: some View {
        Section {
            Picker("Weather (testing)", selection: $settings.weatherDebugMode) {
                ForEach(WeatherDebugMode.allCases, id: \.rawValue) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
        } header: {
            Text("Weather suggestions (testing)")
        } footer: {
            Text("Simulate hot, cold, or rain-soon to test suggestion text on during-walk and summary. Use \"Live weather\" for real data.")
        }
    }
#else
    @ViewBuilder private var weatherTestingSection: some View {
        EmptyView()
    }
#endif

    private var exportSection: some View {
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
            Text("JSON includes your profile, dogs, and walk history. CSV is walks only. Restore replaces your profile, dogs, and walks.")
        }
    }

    private var restoreConfirmationMessage: String {
        guard let envelope = pendingRestore else { return "" }
        let userLine = envelope.user?.hasContent == true ? ", your profile" : ""
        let dogsLine = envelope.dogs.isEmpty ? "" : ", \(envelope.dogs.count) dog(s)"
        return "This will replace your profile, dogs, and walk history with the backup: \(envelope.walks.count) walk(s)\(userLine)\(dogsLine). This cannot be undone."
    }

    private func exportAsJSON(store: WalkStore) {
        let user = userStore.user.hasContent ? userStore.user : nil
        guard let data = store.exportAsJSONData(user: user, dogs: dogStore.dogs) else {
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
        if let user = envelope.user, user.hasContent {
            userStore.save(user)
        }
        dogStore.replaceDogs(with: envelope.dogs)
        store.replaceWalks(with: envelope.walks)
        pendingRestore = nil
        showRestoreSuccess = true
    }
}

#Preview {
    NavigationStack {
        SettingsView(settings: SettingsStore(), store: WalkStore(), userStore: UserProfileStore(), dogStore: DogProfileStore())
    }
}

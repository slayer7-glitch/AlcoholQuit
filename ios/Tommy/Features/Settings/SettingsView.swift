import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: AppStore
    @State private var confirmErase = false
    @State private var exportURL: URL?
    @State private var exportError = false
    var body: some View {
        NavigationStack {
            Form {
                Section("Your journey") {
                    DatePicker("Start date", selection: $store.quitDate, displayedComponents: .date)
                    TextField("Your reason", text: $store.reason, axis: .vertical)
                    Picker("Companion", selection: $store.companion) {
                        ForEach(Companion.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                }
                Section("Reminders") { NavigationLink("Daily reminder") { ReminderSettingsView() } }
                Section("Your data") {
                    NavigationLink("Account & cloud sync") { AuthenticationView() }
                    Text("Entries are stored on this device. Cloud sync is optional and requires a configured server.").font(.footnote)
                    Button("Prepare data export") {
                        do { exportURL = try store.export() } catch { exportError = true }
                    }
                    if let exportURL { ShareLink("Share JSON export", item: exportURL) }
                    Button("Erase local data", role: .destructive) { confirmErase = true }.disabled(store.syncing)
                }
                Section("Help & privacy") {
                    NavigationLink("Safety guidance") { SafetyView() }
                    Text("This build uses no advertising or analytics SDKs. Exported files contain personal information: share them carefully. Device backups may retain app data according to your iOS backup settings.").font(.footnote)
                }
            }.navigationTitle("Settings")
                .confirmationDialog("Erase all entries and preferences on this device? This cannot be undone.", isPresented: $confirmErase, titleVisibility: .visible) {
                    Button("Erase everything", role: .destructive) { store.erase() }
                }
                .alert("Export couldn't be created", isPresented: $exportError) { Button("OK", role: .cancel) {} }
        }
    }
}

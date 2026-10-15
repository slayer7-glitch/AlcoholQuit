import SwiftUI

@main
struct AlcoholQuitApp: App {
    @StateObject private var store = AppStore()
    @Environment(\.scenePhase) private var scenePhase
    var body: some Scene {
        WindowGroup {
            Group {
                if store.onboarded {
                    TabView {
                        HomeView().tabItem { Label("Home", systemImage: "house.fill") }
                        ProgressViewScreen().tabItem { Label("Progress", systemImage: "chart.bar.fill") }
                        SettingsView().tabItem { Label("Settings", systemImage: "gearshape.fill") }
                    }
                } else { OnboardingView() }
            }.environmentObject(store).tint(.teal)
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active { Task { await store.synchronize() } }
                }
                .alert("Storage needs attention", isPresented: Binding(get: { store.storageError != nil }, set: { if !$0 { store.storageError = nil } })) {
                    Button("OK") { store.storageError = nil }
                } message: { Text(store.storageError ?? "") }
        }
    }
}

import SwiftUI

@main
struct TommyApp: App {
    @StateObject private var store: AppStore
    init() {
        #if DEBUG && targetEnvironment(simulator)
        if ProcessInfo.processInfo.arguments.contains("--screenshot-screen") {
            let url = FileManager.default.temporaryDirectory.appending(path: "Screenshots/" + UUID().uuidString + "/state.json")
            let preview = AppStore(storageURL: url)
            preview.reason = "More energy for the people and things I love."
            preview.quitDate = Calendar.current.date(byAdding: .day, value: -7, to: .now)!
            preview.save(CheckIn(mood: "Okay", drinkingStatus: "No", note: "A walk outside helped today."))
            _store = StateObject(wrappedValue: preview)
            return
        }
        #endif
        _store = StateObject(wrappedValue: AppStore())
    }
    private var screenshotScreen: String? {
        #if DEBUG && targetEnvironment(simulator)
        let args = ProcessInfo.processInfo.arguments
        if let index = args.firstIndex(of: "--screenshot-screen"), args.indices.contains(index + 1) { return args[index + 1] }
        #endif
        return nil
    }
    @Environment(\.scenePhase) private var scenePhase
    var body: some Scene {
        WindowGroup {
            Group {
                #if DEBUG && targetEnvironment(simulator)
                if let screen = screenshotScreen {
                    ScreenshotPreview(screen: screen)
                } else {
                    appContent
                }
                #else
                appContent
                #endif
            }.environmentObject(store).tint(.teal)
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active && screenshotScreen == nil { Task { await store.synchronize() } }
                }
                .alert("Storage needs attention", isPresented: Binding(get: { store.storageError != nil }, set: { if !$0 { store.storageError = nil } })) {
                    Button("OK") { store.storageError = nil }
                } message: { Text(store.storageError ?? "") }
        }
    }
    @ViewBuilder private var appContent: some View {
        if store.onboarded {
                    TabView {
                        HomeView().tabItem { Label("Home", systemImage: "house.fill") }
                        ProgressViewScreen().tabItem { Label("Progress", systemImage: "chart.bar.fill") }
                        SettingsView().tabItem { Label("Settings", systemImage: "gearshape.fill") }
                    }
                } else { OnboardingView() }
    }
}

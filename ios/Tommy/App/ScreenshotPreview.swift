#if DEBUG && targetEnvironment(simulator)
import SwiftUI

/// Simulator-only routes for deterministic CI screenshots. Never shipped on devices.
struct ScreenshotPreview: View {
    let screen: String
    var body: some View {
        Group {
            switch screen {
            case "onboarding": OnboardingView()
            case "home", "progress", "settings":
                TabView(selection: .constant(screen)) {
                    HomeView().tabItem { Label("Home", systemImage: "house.fill") }.tag("home")
                    ProgressViewScreen().tabItem { Label("Progress", systemImage: "chart.bar.fill") }.tag("progress")
                    SettingsView().tabItem { Label("Settings", systemImage: "gearshape.fill") }.tag("settings")
                }
            case "check-in": NavigationStack { CheckInView() }
            case "craving-support": NavigationStack { CravingSupportView() }
            case "authentication": NavigationStack { AuthenticationView() }
            case "safety": NavigationStack { SafetyView() }
            default: Text("Unknown screenshot screen")
            }
        }
    }
}
#endif

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var store: AppStore
    @State private var acknowledged = false
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HeroView(companion: store.companion)
                        Text("A fresh start. Your way.").font(.largeTitle.bold())
                        Text("Small steps, gentle support, and space to begin again.")
                    }.padding(.vertical)
                }
                Section("First, your safety") {
                    Text("Stopping suddenly can be dangerous if you drink heavily or have had withdrawal before. Get medical guidance before stopping. This app provides wellness support, not medical treatment.")
                    NavigationLink("Read safety guidance") { SafetyView() }
                    Toggle("I've read this safety notice", isOn: $acknowledged)
                }
                Section("Make it yours") {
                    Picker("Your companion", selection: $store.companion) {
                        ForEach(Companion.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    DatePicker("Start date", selection: $store.quitDate, displayedComponents: .date)
                    TextField("Your reason (optional)", text: $store.reason, axis: .vertical)
                }
                Section {
                    Button("Begin my journey") { store.onboarded = true }
                        .font(.headline).disabled(!acknowledged)
                    Text("No account needed. Your entries stay on this device.").font(.footnote).foregroundStyle(.secondary)
                }
            }.navigationTitle("Welcome")
        }
    }
}

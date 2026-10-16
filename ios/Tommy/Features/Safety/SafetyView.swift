import SwiftUI

struct SafetyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Your safety comes first").font(.largeTitle.bold())
                Text("Stopping alcohol suddenly can cause dangerous withdrawal, especially if you drink heavily or have experienced withdrawal before. Speak with a qualified clinician about a safe plan before stopping.")
                SupportCard {
                    Text("Get urgent medical help").font(.title2.bold())
                    Text("Seizures, hallucinations, or severe confusion can be signs of a medical emergency. Contact your local emergency services immediately. Don't wait for this app to respond.")
                }
                Text("Tommy provides general wellness support. It does not diagnose conditions, manage withdrawal, or replace professional care. Nobody monitors your entries or dispatches help.")
                Text("If you feel unsafe or at risk of harming yourself, contact local emergency services or a crisis service in your region.")
                Text("Draft safety content: clinical review is required before public release.").font(.footnote).foregroundStyle(.secondary)
            }.padding(24)
        }.navigationTitle("Safety & help")
    }
}

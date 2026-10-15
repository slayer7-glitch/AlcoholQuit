import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: AppStore
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    HStack { Spacer(); HeroView(companion: store.companion); Spacer() }
                    Text("One day at a time.").font(.largeTitle.bold())
                    Text("You don't have to do everything today. Just take your next step.").foregroundStyle(.secondary)
                    SupportCard {
                        Text(store.quitDate > .now ? "Your next chapter is ahead" : "\(store.days) days since your start").font(.title2.bold())
                        Text(store.quitDate > .now ? "Use this time to prepare support and speak with a clinician if needed." : "Every honest check-in is a step forward.")
                    }
                    NavigationLink { CravingSupportView() } label: {
                        Label("Help with a craving", systemImage: "heart.fill").font(.headline).frame(maxWidth: .infinity).padding(10)
                    }.buttonStyle(.borderedProminent)
                    NavigationLink { CheckInView() } label: {
                        Label("Today's check-in", systemImage: "checkmark.circle").font(.headline).frame(maxWidth: .infinity).padding(10)
                    }.buttonStyle(.bordered)
                    if !store.reason.isEmpty { SupportCard { Text("YOUR REASON").font(.caption.bold()); Text(store.reason) } }
                    NavigationLink("Safety & getting help") { SafetyView() }
                }.padding(24)
            }.navigationTitle("Today")
        }
    }
}

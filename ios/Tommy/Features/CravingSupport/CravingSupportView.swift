import SwiftUI

struct CravingSupportView: View {
    @EnvironmentObject private var store: AppStore
    @State private var end: Date?
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("Let's take a moment.").font(.largeTitle.bold())
                Text("An urge can change. Give yourself a little room before your next decision.")
                SupportCard {
                    Text("Find your surroundings").font(.title2.bold())
                    Text("Notice 5 things you can see, 4 you can feel, and 3 you can hear. Go at your own pace.")
                }
                SupportCard {
                    Text("Five-minute pause").font(.title2.bold())
                    if let end {
                        TimelineView(.periodic(from: .now, by: 1)) { context in
                            let remaining = max(0, Int(ceil(end.timeIntervalSince(context.date))))
                            Text(remaining == 0 ? "You made room for yourself." : String(format: "%d:%02d", remaining / 60, remaining % 60)).font(.largeTitle.monospacedDigit())
                        }
                        Button("Reset timer") { self.end = nil }
                    } else { Button("Start a gentle pause") { end = .now.addingTimeInterval(300) }.buttonStyle(.borderedProminent) }
                }
                SupportCard {
                    Text("Try one small change").font(.title2.bold())
                    Text("Move to a comfortable place, have a non-alcoholic drink, or reach out to someone you trust using your phone.")
                }
                if !store.reason.isEmpty { SupportCard { Text("Your reason").font(.headline); Text(store.reason) } }
                NavigationLink("Safety & urgent help") { SafetyView() }
            }.padding(24)
        }.navigationTitle("Craving support")
    }
}

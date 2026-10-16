import SwiftUI

struct ProgressViewScreen: View {
    @EnvironmentObject private var store: AppStore
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("\(store.alcoholFreeDays) recorded alcohol-free days").font(.title2.bold())
                    Text("Missing or private answers don't count as alcohol-free days. Your history stays with you after a setback.").font(.footnote)
                }
                Section("Your check-ins") {
                    if store.entries.isEmpty { ContentUnavailableView("Your story starts here", systemImage: "book", description: Text("Your check-ins will appear here.")) }
                    ForEach(store.entries.sorted { $0.date > $1.date }) { entry in
                        NavigationLink { CheckInView(existing: entry) } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(entry.date, style: .date).font(.headline)
                                Text("\(entry.mood) · Drinking: \(entry.drinkingStatus)").font(.subheadline)
                                if !entry.note.isEmpty { Text(entry.note).lineLimit(2).foregroundStyle(.secondary) }
                            }.padding(.vertical, 4)
                        }
                    }
                }
            }.navigationTitle("Your progress")
        }
    }
}

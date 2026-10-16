import SwiftUI

struct CheckInView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    var existing: CheckIn? = nil
    @State private var mood = "Okay"
    @State private var status = "Prefer not to say"
    @State private var note = ""
    @State private var saved = false
    var body: some View {
        Form {
            Section("How are you feeling?") {
                Picker("Mood", selection: $mood) { ForEach(["Great", "Okay", "Low", "Overwhelmed"], id: \.self) { Text($0) } }
            }
            Section("Did you drink today?") {
                Picker("Your answer", selection: $status) { ForEach(["No", "Yes", "Prefer not to say"], id: \.self) { Text($0) } }
                if status == "Yes" { Text("One difficult moment doesn't erase your effort. What would help right now?") }
            }
            Section("A note to yourself (optional)") { TextEditor(text: $note).frame(minHeight: 120) }
            Section {
                Button("Save check-in") {
                    store.save(CheckIn(id: existing?.id ?? UUID(), date: existing?.date ?? .now, mood: mood, drinkingStatus: status, note: note))
                    if store.storageError == nil { saved = true }
                }
                Text("Saved privately on this device. You can edit it later.").font(.footnote).foregroundStyle(.secondary)
            }
        }.navigationTitle(existing == nil ? "Check in" : "Edit check-in")
            .onAppear {
                let entry = existing ?? store.entries.first(where: { Calendar.current.isDateInToday($0.date) })
                if let entry { mood = entry.mood; status = entry.drinkingStatus; note = entry.note }
            }
            .alert("Check-in saved", isPresented: $saved) { Button("Done") { dismiss() } }
    }
}

import SwiftUI
import UserNotifications

struct ReminderSettingsView: View {
    @State private var time = Date.now
    @State private var message: String?
    var body: some View {
        Form {
            Section("A gentle daily reminder") {
                DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
                Text("Lock-screen wording is discreet: ‘A moment for you’. Notifications never include your entries or mention alcohol.")
                Button("Enable daily reminder") {
                    Task {
                        do {
                            let center = UNUserNotificationCenter.current()
                            guard try await center.requestAuthorization(options: [.alert, .sound]) else {
                                message = "Notifications are off. You can allow them in iOS Settings."; return
                            }
                            let content = UNMutableNotificationContent()
                            content.title = "A moment for you"
                            content.body = "Take a breath and check in with yourself."
                            let components = Calendar.current.dateComponents([.hour, .minute], from: time)
                            let request = UNNotificationRequest(identifier: "daily-check-in", content: content, trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: true))
                            try await center.add(request)
                            message = "Daily reminder scheduled."
                        } catch { message = "The reminder couldn't be scheduled. Please try again." }
                    }
                }
                Button("Turn off reminder") {
                    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily-check-in"])
                    message = "Daily reminder is off."
                }
            }
            if let message { Text(message) }
        }.navigationTitle("Reminders")
            .task {
                let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
                if let trigger = requests.first(where: { $0.identifier == "daily-check-in" })?.trigger as? UNCalendarNotificationTrigger,
                   let next = trigger.nextTriggerDate() { time = next }
            }
    }
}

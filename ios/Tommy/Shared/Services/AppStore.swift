import Foundation
import SwiftUI
import UserNotifications

@MainActor
final class AppStore: ObservableObject {
    @Published var entries: [CheckIn] = [] { didSet { persist() } }
    @Published var quitDate: Date = .now { didSet { persist() } }
    @Published var companion: Companion = .boy { didSet { persist() } }
    @Published var onboarded = false { didSet { persist() } }
    @Published var reason = "" { didSet { persist() } }
    @Published var storageError: String?
    @Published var syncMessage: String?
    @Published var syncing = false
    @Published private(set) var accountID: String?
    private var revisions: [String: Int] = [:]
    private var pending: Set<String> = []
    private var cursor = 0
    private var canWrite = true
    private let url: URL
    private struct Snapshot: Codable {
        var entries: [CheckIn]; var quitDate: Date; var companion: Companion
        var onboarded: Bool; var reason: String
        var accountID: String?; var revisions: [String: Int]?; var pending: Set<String>?; var cursor: Int?
    }
    init(storageURL: URL? = nil) {
        url = storageURL ?? URL.applicationSupportDirectory.appending(path: "AlcoholQuit/state.json")
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        do {
            let state = try JSONDecoder().decode(Snapshot.self, from: Data(contentsOf: url))
            entries = state.entries; quitDate = state.quitDate; companion = state.companion
            onboarded = state.onboarded; reason = state.reason
            accountID = state.accountID; revisions = state.revisions ?? [:]; pending = state.pending ?? []; cursor = state.cursor ?? 0
        } catch { canWrite = false; storageError = "Your saved data could not be opened. Please keep the app data and try again." }
    }
    private func persist() {
        guard canWrite else { return }
        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(Snapshot(entries: entries, quitDate: quitDate, companion: companion, onboarded: onboarded, reason: reason, accountID: accountID, revisions: revisions, pending: pending, cursor: cursor))
            try data.write(to: url, options: [.atomic, .completeFileProtection])
        } catch { storageError = "Changes could not be saved on this device. Please try again." }
    }
    var days: Int { max(0, Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: quitDate), to: Calendar.current.startOfDay(for: .now)).day ?? 0) }
    var alcoholFreeDays: Int { entries.filter { $0.drinkingStatus == "No" }.count }
    func save(_ entry: CheckIn) {
        guard canWrite else { storageError = "Storage could not be opened. Export or recover your data before making changes."; return }
        if let index = entries.firstIndex(where: { $0.id == entry.id || $0.dayKey == entry.dayKey }) {
            var updated = entry; updated.id = entries[index].id; updated.recordedDay = entries[index].dayKey; pending.insert(updated.id.uuidString.lowercased()); entries[index] = updated
        } else { var recorded = entry; recorded.recordedDay = entry.dayKey; pending.insert(entry.id.uuidString.lowercased()); entries.append(recorded) }
    }
    func erase() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily-check-in"])
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ["daily-check-in"])
        try? FileManager.default.removeItem(at: FileManager.default.temporaryDirectory.appending(path: "Tommy-export.json"))
        canWrite = true; accountID = nil; revisions = [:]; pending = []; cursor = 0
        entries = []; reason = ""; quitDate = .now; companion = .boy; onboarded = false
        Task { await CloudClient.shared.clear() }
    }
    func attachAccount(_ id: String) throws {
        if let accountID, accountID != id { throw CloudFailure(message: "Another account owns this device's records. Export your data and sign out before switching accounts.") }
        accountID = id
        for entry in entries where revisions[entry.id.uuidString.lowercased()] == nil { pending.insert(entry.id.uuidString.lowercased()) }
        persist()
    }
    func synchronize() async {
        guard let syncingAccount = accountID, !syncing, canWrite else { return }
        syncing = true
        defer { syncing = false }
        do {
            guard await CloudClient.shared.session()?.userId == syncingAccount else { throw CloudFailure(message: "Please sign in to the account linked to this device.") }
            // Upload first; conflicts stop without discarding either copy.
            let formatter = DateFormatter(); formatter.calendar = Calendar(identifier: .gregorian)
            formatter.locale = Locale(identifier: "en_US_POSIX"); formatter.dateFormat = "yyyy-MM-dd"
            for id in Array(pending) {
                guard let entry = entries.first(where: { $0.id.uuidString.lowercased() == id }) else { continue }
                let result: CloudWrite = try await CloudClient.shared.send("/v1/check-ins/" + id, method: "PUT", body: ["localDate": entry.dayKey, "mood": entry.mood, "drinkingStatus": entry.drinkingStatus, "note": entry.note, "revision": revisions[id] ?? 0])
                guard accountID == syncingAccount else { return }
                revisions[id] = result.revision
                // Keep edits made while this network request was in flight pending.
                if let current = entries.first(where: { $0.id == entry.id }), current.note == entry.note, current.mood == entry.mood, current.drinkingStatus == entry.drinkingStatus { pending.remove(id) }
                persist()
            }
            var more = true
            while more {
                let page: CloudPage = try await CloudClient.shared.send("/v1/sync?cursor=\(cursor)")
                guard accountID == syncingAccount else { return }
                for change in page.changes {
                    guard !pending.contains(change.id), let uuid = UUID(uuidString: change.id), let date = formatter.date(from: change.localDate) else { throw CloudFailure(message: "Cloud data conflicts with a pending edit. Your entries were kept; sync again after saving.") }
                    if let oldRevision = revisions[change.id], oldRevision > change.revision { continue }
                    if let duplicate = entries.first(where: { $0.dayKey == change.localDate && $0.id != uuid }), !change.deleted {
                        throw CloudFailure(message: "Two entries exist for the same day (\(duplicate.date.formatted(date: .abbreviated, time: .omitted))). Export your entries before resolving the conflict.")
                    }
                    entries.removeAll { $0.id == uuid }
                    if !change.deleted { entries.append(CheckIn(id: uuid, date: date, mood: change.mood, drinkingStatus: change.drinkingStatus, note: change.note, recordedDay: change.localDate)) }
                    revisions[change.id] = change.revision
                }
                cursor = page.cursor; more = page.hasMore; persist()
            }
            syncMessage = pending.isEmpty ? "All check-ins synchronized." : "Some edits are still pending. Sync again when ready."
        } catch { syncMessage = error.localizedDescription }
    }
    func export() throws -> URL {
        let destination = FileManager.default.temporaryDirectory.appending(path: "Tommy-export.json")
        try JSONEncoder().encode(Snapshot(entries: entries, quitDate: quitDate, companion: companion, onboarded: onboarded, reason: reason, accountID: accountID, revisions: revisions, pending: pending, cursor: cursor)).write(to: destination, options: [.atomic, .completeFileProtection])
        return destination
    }
}

import Foundation

struct CheckIn: Identifiable, Codable {
    var id: UUID = UUID()
    var date: Date = .now
    var mood: String
    var drinkingStatus: String
    var note: String
    var recordedDay: String? = nil
    var dayKey: String {
        if let recordedDay { return recordedDay }
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

enum Companion: String, CaseIterable, Codable {
    case boy = "Boy hero", girl = "Girl hero", neutral = "No mascot"
}

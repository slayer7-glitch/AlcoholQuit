import XCTest
@testable import Tommy

@MainActor
final class AppStoreTests: XCTestCase {
    private func location() -> URL {
        FileManager.default.temporaryDirectory.appending(path: UUID().uuidString + "/state.json")
    }
    func testDailyCheckInEditsReplaceRatherThanDuplicate() {
        let url = location()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let store = AppStore(storageURL: url)
        let original = CheckIn(mood: "Okay", drinkingStatus: "No", note: "First")
        store.save(original)
        store.save(CheckIn(mood: "Low", drinkingStatus: "Yes", note: "Updated"))
        XCTAssertEqual(store.entries.count, 1)
        XCTAssertEqual(store.entries.first?.id, original.id)
        XCTAssertEqual(store.alcoholFreeDays, 0)
        let restored = AppStore(storageURL: url)
        XCTAssertEqual(restored.entries.first?.note, "Updated")
        XCTAssertNil(restored.storageError)
    }
    func testPrivateAnswersDoNotCountAsAlcoholFree() {
        let url = location()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let store = AppStore(storageURL: url)
        store.save(CheckIn(mood: "Okay", drinkingStatus: "Prefer not to say", note: ""))
        XCTAssertEqual(store.alcoholFreeDays, 0)
        store.save(CheckIn(mood: "Okay", drinkingStatus: "No", note: ""))
        XCTAssertEqual(store.alcoholFreeDays, 1)
    }
    func testCorruptDataIsNotOverwritten() throws {
        let url = location()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let corrupt = Data("not json".utf8)
        try corrupt.write(to: url)
        let store = AppStore(storageURL: url)
        XCTAssertNotNil(store.storageError)
        store.save(CheckIn(mood: "Okay", drinkingStatus: "No", note: ""))
        XCTAssertEqual(try Data(contentsOf: url), corrupt)
    }
    func testFutureQuitDateNeverProducesNegativeProgress() {
        let url = location()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let store = AppStore(storageURL: url)
        store.quitDate = Calendar.current.date(byAdding: .day, value: 5, to: .now)!
        XCTAssertEqual(store.days, 0)
    }
}

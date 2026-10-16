import Foundation
import Security

struct CloudSession: Codable { let token: String; let expiresAt: Int; let userId: String }
struct CloudChange: Codable {
    let id: String; let localDate: String; let mood: String; let drinkingStatus: String
    let note: String; let revision: Int; let deleted: Bool
}
struct CloudPage: Codable { let changes: [CloudChange]; let cursor: Int; let hasMore: Bool }
struct CloudWrite: Codable { let id: String; let revision: Int }
struct CloudFailure: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

actor CloudClient {
    static let shared = CloudClient()
    private let key = "com.alcoholquit.session"
    func session() -> CloudSession? {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: key, kSecAttrAccount as String: "current", kSecReturnData as String: true]
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess, let data = result as? Data else { return nil }
        return try? JSONDecoder().decode(CloudSession.self, from: data)
    }
    func store(_ session: CloudSession) throws {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: key, kSecAttrAccount as String: "current"]
        SecItemDelete(query as CFDictionary)
        var item = query; item[kSecValueData as String] = try JSONEncoder().encode(session)
        item[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        guard SecItemAdd(item as CFDictionary, nil) == errSecSuccess else { throw CloudFailure(message: "Your secure session couldn't be saved.") }
    }
    func clear() {
        SecItemDelete([kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: key, kSecAttrAccount as String: "current"] as CFDictionary)
    }
    func send<T: Decodable>(_ path: String, method: String = "GET", body: [String: Any]? = nil, authenticated: Bool = true) async throws -> T {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: "APIBaseURL") as? String,
              let base = URL(string: raw), base.scheme == "https", base.host != nil,
              let url = URL(string: path, relativeTo: base) else {
            throw CloudFailure(message: "Cloud sync isn't configured in this build. Your data remains on this device.")
        }
        var request = URLRequest(url: url); request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if authenticated {
            guard let session = session(), session.expiresAt > Int(Date.now.timeIntervalSince1970) else { throw CloudFailure(message: "Please sign in again to synchronize. Your local entries are safe.") }
            request.setValue("Bearer " + session.token, forHTTPHeaderField: "Authorization")
        }
        if let body { request.httpBody = try JSONSerialization.data(withJSONObject: body) }
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let response = response as? HTTPURLResponse else { throw CloudFailure(message: "The server didn't respond. Try again later.") }
        guard (200..<300).contains(response.statusCode) else {
            if response.statusCode == 409 { throw CloudFailure(message: "An entry conflicts with cloud data. Your local version has been kept. Export your data before resolving this on another device.") }
            if response.statusCode == 401 { throw CloudFailure(message: "Please sign in again. Your local entries are safe.") }
            throw CloudFailure(message: "Cloud request failed (\(response.statusCode)). Please try again.")
        }
        if response.statusCode == 204 { return try JSONDecoder().decode(T.self, from: Data("{}".utf8)) }
        return try JSONDecoder().decode(T.self, from: data)
    }
}
struct EmptyResponse: Decodable {}

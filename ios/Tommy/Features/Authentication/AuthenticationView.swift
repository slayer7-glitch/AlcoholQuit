import SwiftUI
import AuthenticationServices
import CryptoKit
import Security

struct AuthenticationView: View {
    @EnvironmentObject private var store: AppStore
    @State private var consent = false
    @State private var nonce = ""
    @State private var message: String?
    @State private var busy = false
    @State private var confirmLogout = false
    @State private var confirmDeletion = false
    var body: some View {
        Form {
            Section("Optional cloud account") {
                Text("Core tools work without an account. If you enable sync, check-ins and private notes are sent to your configured Cloudflare backend. Cloud data can be deleted below.")
                Toggle("I agree to upload my entries for cloud sync", isOn: $consent)
                SignInWithAppleButton(.signIn) { request in
                    var bytes = [UInt8](repeating: 0, count: 32)
                    guard SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes) == errSecSuccess else { message = "Secure sign-in couldn't start."; return }
                    nonce = bytes.map { String(format: "%02x", $0) }.joined()
                    request.nonce = SHA256.hash(data: Data(nonce.utf8)).map { String(format: "%02x", $0) }.joined()
                } onCompletion: { result in
                    switch result {
                    case .success(let authorization):
                        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                              let data = credential.identityToken, let token = String(data: data, encoding: .utf8), !nonce.isEmpty else { message = "Apple didn't return a valid sign-in credential."; return }
                        busy = true
                        Task {
                            defer { busy = false }
                            do {
                                let session: CloudSession = try await CloudClient.shared.send("/v1/auth/apple", method: "POST", body: ["identityToken": token, "nonce": nonce], authenticated: false)
                                try store.attachAccount(session.userId)
                                try await CloudClient.shared.store(session)
                                await store.synchronize()
                                message = store.syncMessage
                            } catch { message = error.localizedDescription }
                        }
                    case .failure(let error): message = error.localizedDescription
                    }
                }.frame(height: 50).disabled(!consent || busy || store.syncing)
                if busy { ProgressView() }
            }
            if store.accountID != nil {
                Section("Synchronization") {
                    Text(store.syncMessage ?? "Your account is linked. Tap below to sync pending entries.")
                    Button("Sync now") { Task { await store.synchronize() } }.disabled(store.syncing)
                    Button("Sign out and erase this device", role: .destructive) { confirmLogout = true }.disabled(store.syncing)
                    Button("Delete cloud account", role: .destructive) { confirmDeletion = true }.disabled(store.syncing)
                }
            }
            if let message { Section { Text(message) } }
        }.navigationTitle("Account & sync")
            .confirmationDialog("Export unsynced entries first. Signing out erases local entries to protect your privacy.", isPresented: $confirmLogout, titleVisibility: .visible) {
                Button("Sign out and erase", role: .destructive) {
                    Task {
                        do {
                            let _: EmptyResponse = try await CloudClient.shared.send("/v1/auth/logout", method: "POST")
                            await CloudClient.shared.clear(); store.erase()
                        } catch { message = error.localizedDescription }
                    }
                }
            }
            .confirmationDialog("Delete cloud account and all local entries? Active cloud data is deleted immediately. Provider backups may retain data according to the deployment's backup policy.", isPresented: $confirmDeletion, titleVisibility: .visible) {
                Button("Delete account and data", role: .destructive) {
                    Task {
                        do {
                            let _: EmptyResponse = try await CloudClient.shared.send("/v1/me", method: "DELETE")
                            await CloudClient.shared.clear(); store.erase()
                        } catch { message = error.localizedDescription }
                    }
                }
            }
    }
}

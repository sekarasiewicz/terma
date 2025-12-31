import Foundation
import LocalAuthentication
@preconcurrency import KeychainAccess

enum KeychainError: Error, LocalizedError {
    case authenticationFailed
    case authenticationCancelled

    var errorDescription: String? {
        switch self {
        case .authenticationFailed:
            return "Biometric authentication failed"
        case .authenticationCancelled:
            return "Authentication was cancelled"
        }
    }
}

final class KeychainService: Sendable {
    static let shared = KeychainService()

    nonisolated(unsafe) private let keychain: Keychain

    private init() {
        keychain = Keychain(service: "dev.karasiewicz.terma")
            .accessibility(.whenUnlocked)
    }

    func authenticateIfRequired() async throws {
        guard AppSettings.shared.biometricEnabled else { return }

        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            // Biometrics not available, fall back silently
            return
        }

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Authenticate to access server credentials"
            )
            if !success {
                throw KeychainError.authenticationFailed
            }
        } catch let laError as LAError {
            if laError.code == .userCancel || laError.code == .appCancel {
                throw KeychainError.authenticationCancelled
            }
            // Other errors (e.g., biometry lockout) - allow fallback
        }
    }

    func savePassword(_ password: String, for key: String) throws {
        try keychain.set(password, key: key)
    }

    func getPassword(for key: String) throws -> String? {
        try keychain.get(key)
    }

    func deletePassword(for key: String) throws {
        try keychain.remove(key)
    }

    func savePrivateKey(_ privateKey: Data, for key: String) throws {
        try keychain.set(privateKey, key: key)
    }

    func getPrivateKey(for key: String) throws -> Data? {
        try keychain.getData(key)
    }

    func deletePrivateKey(for key: String) throws {
        try keychain.remove(key)
    }

    func savePassphrase(_ passphrase: String, for key: String) throws {
        try keychain.set(passphrase, key: key)
    }

    func getPassphrase(for key: String) throws -> String? {
        try keychain.get(key)
    }

    func deletePassphrase(for key: String) throws {
        try keychain.remove(key)
    }

    func deleteAllCredentials(for profile: ServerProfile) throws {
        try deletePassword(for: profile.keychainPasswordKey)
        try deletePrivateKey(for: profile.keychainPrivateKeyKey)
        try deletePassphrase(for: profile.keychainPassphraseKey)
    }
}

import Foundation
import KeychainAccess

final class KeychainService: Sendable {
    static let shared = KeychainService()

    private let keychain: Keychain

    private init() {
        keychain = Keychain(service: "dev.karasiewicz.terma")
            .accessibility(.whenUnlocked)
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

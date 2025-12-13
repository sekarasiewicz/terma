import Foundation
import SwiftUI
import UniformTypeIdentifiers

@Observable
@MainActor
final class ServerEditViewModel {
    var name: String = ""
    var host: String = ""
    var port: String = "22"
    var username: String = ""
    var authMethod: AuthMethod = .password
    var password: String = ""
    var privateKeyData: Data?
    var privateKeyName: String = ""
    var passphrase: String = ""

    var showingKeyImporter = false
    var errorMessage: String?
    var showingError = false

    private var existingProfile: ServerProfile?
    private let storage = ProfileStorage.shared
    private let keychain = KeychainService.shared

    var isEditing: Bool {
        existingProfile != nil
    }

    var navigationTitle: String {
        isEditing ? "Edit Server" : "Add Server"
    }

    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !host.trimmingCharacters(in: .whitespaces).isEmpty &&
        !username.trimmingCharacters(in: .whitespaces).isEmpty &&
        (Int(port) ?? 0) > 0 &&
        (Int(port) ?? 0) <= 65535 &&
        hasValidCredentials
    }

    private var hasValidCredentials: Bool {
        switch authMethod {
        case .password:
            return !password.isEmpty
        case .sshKey:
            return privateKeyData != nil
        }
    }

    func loadProfile(_ profile: ServerProfile?) {
        guard let profile = profile else { return }

        existingProfile = profile
        name = profile.name
        host = profile.host
        port = String(profile.port)
        username = profile.username
        authMethod = profile.authMethod
        privateKeyName = profile.privateKeyName ?? ""

        do {
            if let savedPassword = try keychain.getPassword(for: profile.keychainPasswordKey) {
                password = savedPassword
            }
            if let savedKey = try keychain.getPrivateKey(for: profile.keychainPrivateKeyKey) {
                privateKeyData = savedKey
            }
            if let savedPassphrase = try keychain.getPassphrase(for: profile.keychainPassphraseKey) {
                passphrase = savedPassphrase
            }
        } catch {
            print("Failed to load credentials: \(error)")
        }
    }

    func save() -> Bool {
        guard canSave else { return false }

        let profile: ServerProfile
        if let existing = existingProfile {
            profile = existing
            profile.name = name.trimmingCharacters(in: .whitespaces)
            profile.host = host.trimmingCharacters(in: .whitespaces)
            profile.port = Int(port) ?? 22
            profile.username = username.trimmingCharacters(in: .whitespaces)
            profile.authMethod = authMethod
            profile.privateKeyName = authMethod == .sshKey ? privateKeyName : nil
        } else {
            profile = ServerProfile(
                name: name.trimmingCharacters(in: .whitespaces),
                host: host.trimmingCharacters(in: .whitespaces),
                port: Int(port) ?? 22,
                username: username.trimmingCharacters(in: .whitespaces),
                authMethod: authMethod,
                privateKeyName: authMethod == .sshKey ? privateKeyName : nil
            )
            storage.addProfile(profile)
        }

        do {
            try keychain.deleteAllCredentials(for: profile)

            switch authMethod {
            case .password:
                try keychain.savePassword(password, for: profile.keychainPasswordKey)
            case .sshKey:
                if let keyData = privateKeyData {
                    try keychain.savePrivateKey(keyData, for: profile.keychainPrivateKeyKey)
                }
                if !passphrase.isEmpty {
                    try keychain.savePassphrase(passphrase, for: profile.keychainPassphraseKey)
                }
            }

            storage.saveContext()
            return true
        } catch {
            errorMessage = "Failed to save credentials: \(error.localizedDescription)"
            showingError = true
            return false
        }
    }

    func importKey(from result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            guard url.startAccessingSecurityScopedResource() else {
                errorMessage = "Cannot access the selected file"
                showingError = true
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }

            do {
                let data = try Data(contentsOf: url)
                privateKeyData = data
                privateKeyName = url.lastPathComponent
            } catch {
                errorMessage = "Failed to read key file: \(error.localizedDescription)"
                showingError = true
            }
        case .failure(let error):
            errorMessage = "Failed to import key: \(error.localizedDescription)"
            showingError = true
        }
    }

    func clearPrivateKey() {
        privateKeyData = nil
        privateKeyName = ""
        passphrase = ""
    }
}

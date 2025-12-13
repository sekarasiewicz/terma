import Foundation
import SwiftData

@Model
final class ServerProfile {
    var id: UUID
    var name: String
    var host: String
    var port: Int
    var username: String
    var authMethod: AuthMethod
    var privateKeyName: String?
    var createdAt: Date
    var lastConnectedAt: Date?

    init(
        id: UUID = UUID(),
        name: String,
        host: String,
        port: Int = 22,
        username: String,
        authMethod: AuthMethod = .password,
        privateKeyName: String? = nil,
        createdAt: Date = Date(),
        lastConnectedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.host = host
        self.port = port
        self.username = username
        self.authMethod = authMethod
        self.privateKeyName = privateKeyName
        self.createdAt = createdAt
        self.lastConnectedAt = lastConnectedAt
    }

    var keychainPasswordKey: String {
        "terma.password.\(id.uuidString)"
    }

    var keychainPrivateKeyKey: String {
        "terma.privatekey.\(id.uuidString)"
    }

    var keychainPassphraseKey: String {
        "terma.passphrase.\(id.uuidString)"
    }

    var displayHost: String {
        if port == 22 {
            return host
        }
        return "\(host):\(port)"
    }
}

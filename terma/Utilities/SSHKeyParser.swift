import Foundation
import Crypto

enum SSHKeyType {
    case ed25519
    case rsa
    case unknown
}

struct SSHKeyParser {
    static func detectKeyType(from data: Data) -> SSHKeyType {
        guard let content = String(data: data, encoding: .utf8) else {
            return .unknown
        }

        if content.contains("OPENSSH PRIVATE KEY") {
            if content.contains("ssh-ed25519") || detectOpenSSHKeyType(content) == .ed25519 {
                return .ed25519
            }
            return .rsa
        }

        if content.contains("RSA PRIVATE KEY") {
            return .rsa
        }

        if content.contains("PRIVATE KEY") {
            return .rsa
        }

        return .unknown
    }

    private static func detectOpenSSHKeyType(_ content: String) -> SSHKeyType {
        let lines = content.components(separatedBy: .newlines)
        for line in lines {
            if line.contains("ssh-ed25519") {
                return .ed25519
            }
            if line.contains("ssh-rsa") {
                return .rsa
            }
        }
        return .unknown
    }

    static func parseOpenSSHPrivateKey(_ data: Data, passphrase: String?) throws -> Data {
        return data
    }
}

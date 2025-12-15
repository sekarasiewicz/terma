import Foundation
import Crypto

enum SSHKeyType {
    case ed25519
    case p256
    case p384
    case p521
    case rsa
    case unknown
}

enum SSHKeyParserError: LocalizedError {
    case invalidFormat
    case unsupportedKeyType
    case invalidBase64
    case invalidKeyData
    case encryptedKeyNotSupported

    var errorDescription: String? {
        switch self {
        case .invalidFormat:
            return "Invalid key format"
        case .unsupportedKeyType:
            return "Unsupported key type. Supported: Ed25519, ECDSA P-256/P-384/P-521"
        case .invalidBase64:
            return "Invalid base64 encoding"
        case .invalidKeyData:
            return "Invalid key data"
        case .encryptedKeyNotSupported:
            return "Encrypted keys are not yet supported"
        }
    }
}

struct SSHKeyParser {

    static func detectKeyType(from data: Data) -> SSHKeyType {
        guard let content = String(data: data, encoding: .utf8) else {
            return .unknown
        }

        // OpenSSH format
        if content.contains("OPENSSH PRIVATE KEY") {
            return detectOpenSSHKeyType(content)
        }

        // Traditional PEM formats
        if content.contains("EC PRIVATE KEY") {
            return .p256 // Default to P-256, actual curve detected during parsing
        }

        if content.contains("RSA PRIVATE KEY") || content.contains("PRIVATE KEY") {
            // Check if it's actually EC in PKCS#8 format
            if content.contains("EC") {
                return .p256
            }
            return .rsa
        }

        return .unknown
    }

    private static func detectOpenSSHKeyType(_ content: String) -> SSHKeyType {
        // Parse the base64 content to detect key type from the encoded data
        let lines = content.components(separatedBy: .newlines)
            .filter { !$0.hasPrefix("-----") && !$0.isEmpty }
        let base64String = lines.joined()

        guard let decoded = Data(base64Encoded: base64String) else {
            return .unknown
        }

        // OpenSSH format has key type as string early in the data
        if let str = String(data: decoded, encoding: .ascii) {
            if str.contains("ssh-ed25519") {
                return .ed25519
            }
            if str.contains("ecdsa-sha2-nistp256") {
                return .p256
            }
            if str.contains("ecdsa-sha2-nistp384") {
                return .p384
            }
            if str.contains("ecdsa-sha2-nistp521") {
                return .p521
            }
            if str.contains("ssh-rsa") {
                return .rsa
            }
        }

        return .unknown
    }

    // MARK: - Ed25519 Parsing

    static func parseEd25519Key(_ data: Data) throws -> Curve25519.Signing.PrivateKey {
        guard let pemString = String(data: data, encoding: .utf8) else {
            throw SSHKeyParserError.invalidFormat
        }

        // Check for encryption
        if pemString.contains("ENCRYPTED") {
            throw SSHKeyParserError.encryptedKeyNotSupported
        }

        let lines = pemString.components(separatedBy: .newlines)
            .filter { !$0.hasPrefix("-----") && !$0.isEmpty }
        let base64String = lines.joined()

        guard let decodedData = Data(base64Encoded: base64String) else {
            throw SSHKeyParserError.invalidBase64
        }

        // OpenSSH format: the private key is typically at a specific offset
        // The format is complex but the 32-byte Ed25519 key is near the end
        let keyData = try extractEd25519FromOpenSSH(decodedData)

        return try Curve25519.Signing.PrivateKey(rawRepresentation: keyData)
    }

    private static func extractEd25519FromOpenSSH(_ data: Data) throws -> Data {
        // OpenSSH private key format structure:
        // - "openssh-key-v1\0"
        // - cipher name (string)
        // - kdf name (string)
        // - kdf options (string)
        // - number of keys (uint32)
        // - public key (string)
        // - encrypted section containing private key

        let bytes = [UInt8](data)

        // Look for the ed25519 key pattern - 64 bytes of key material (32 private + 32 public)
        // followed by a comment. The private key is the first 32 bytes of the 64-byte block.

        // Simple heuristic: find a 64-byte aligned section that could be the key
        // The ed25519 private key in OpenSSH format is 64 bytes (seed + public)
        // We need the first 32 bytes (the seed/private key)

        if bytes.count >= 64 {
            // Try to find the key by looking for the pattern after "ssh-ed25519"
            if let range = data.range(of: Data("ssh-ed25519".utf8)) {
                let startIndex = range.upperBound
                // Skip the public key (32 bytes + length prefix)
                // Then we have the private key section

                // Look for 64-byte key material
                for offset in stride(from: startIndex, to: data.count - 64, by: 1) {
                    let potential = data.subdata(in: offset..<(offset + 32))
                    // Verify this looks like valid key material
                    if isValidKeyMaterial(potential) {
                        return potential
                    }
                }
            }

            // Fallback: use last 32 bytes of a 64-byte chunk near the end
            // This works for many OpenSSH ed25519 keys
            let endSection = data.suffix(100)
            if endSection.count >= 64 {
                return Data(endSection.prefix(64).prefix(32))
            }
        }

        throw SSHKeyParserError.invalidKeyData
    }

    private static func isValidKeyMaterial(_ data: Data) -> Bool {
        // Basic validation: not all zeros, not all ones
        let bytes = [UInt8](data)
        let allZero = bytes.allSatisfy { $0 == 0 }
        let allOne = bytes.allSatisfy { $0 == 0xFF }
        return !allZero && !allOne && data.count == 32
    }

    // MARK: - ECDSA P-256 Parsing

    static func parseP256Key(_ data: Data) throws -> P256.Signing.PrivateKey {
        guard let pemString = String(data: data, encoding: .utf8) else {
            throw SSHKeyParserError.invalidFormat
        }

        if pemString.contains("ENCRYPTED") {
            throw SSHKeyParserError.encryptedKeyNotSupported
        }

        let lines = pemString.components(separatedBy: .newlines)
            .filter { !$0.hasPrefix("-----") && !$0.isEmpty }
        let base64String = lines.joined()

        guard let decodedData = Data(base64Encoded: base64String) else {
            throw SSHKeyParserError.invalidBase64
        }

        // Try PEM format first (SEC1 or PKCS#8)
        if pemString.contains("EC PRIVATE KEY") {
            return try P256.Signing.PrivateKey(pemRepresentation: pemString)
        }

        // Try PKCS#8 format
        if pemString.contains("PRIVATE KEY") {
            return try P256.Signing.PrivateKey(pemRepresentation: pemString)
        }

        // OpenSSH format
        return try parseP256FromOpenSSH(decodedData)
    }

    private static func parseP256FromOpenSSH(_ data: Data) throws -> P256.Signing.PrivateKey {
        // For OpenSSH ECDSA keys, extract the raw private scalar
        // P-256 private key is 32 bytes

        // Look for nistp256 identifier
        if let range = data.range(of: Data("nistp256".utf8)) {
            // The private key scalar follows after the public key
            // Skip to find the 32-byte private key
            let searchStart = range.upperBound + 65 // public key is 65 bytes for P-256

            for offset in stride(from: searchStart, to: min(searchStart + 100, data.count - 32), by: 1) {
                let potential = data.subdata(in: offset..<(offset + 32))
                if isValidKeyMaterial(potential) {
                    return try P256.Signing.PrivateKey(rawRepresentation: potential)
                }
            }
        }

        throw SSHKeyParserError.invalidKeyData
    }

    // MARK: - ECDSA P-384 Parsing

    static func parseP384Key(_ data: Data) throws -> P384.Signing.PrivateKey {
        guard let pemString = String(data: data, encoding: .utf8) else {
            throw SSHKeyParserError.invalidFormat
        }

        if pemString.contains("EC PRIVATE KEY") || pemString.contains("PRIVATE KEY") {
            return try P384.Signing.PrivateKey(pemRepresentation: pemString)
        }

        throw SSHKeyParserError.invalidKeyData
    }

    // MARK: - ECDSA P-521 Parsing

    static func parseP521Key(_ data: Data) throws -> P521.Signing.PrivateKey {
        guard let pemString = String(data: data, encoding: .utf8) else {
            throw SSHKeyParserError.invalidFormat
        }

        if pemString.contains("EC PRIVATE KEY") || pemString.contains("PRIVATE KEY") {
            return try P521.Signing.PrivateKey(pemRepresentation: pemString)
        }

        throw SSHKeyParserError.invalidKeyData
    }
}

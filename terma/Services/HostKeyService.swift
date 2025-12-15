import Foundation
import NIOSSH
import CryptoKit

enum HostKeyVerificationResult {
    case trusted
    case unknown(fingerprint: String)
    case changed(oldFingerprint: String, newFingerprint: String)
}

final class HostKeyService: @unchecked Sendable {
    static let shared = HostKeyService()

    private let userDefaults: UserDefaults
    private let storageKey = "terma.knownHosts"
    private let lock = NSLock()

    private init() {
        self.userDefaults = UserDefaults.standard
    }

    func verify(host: String, port: Int, hostKey: NIOSSHPublicKey) -> HostKeyVerificationResult {
        let fingerprint = calculateFingerprint(hostKey)
        let key = hostIdentifier(host: host, port: port)

        lock.lock()
        defer { lock.unlock() }

        let knownHosts = getKnownHosts()

        if let storedFingerprint = knownHosts[key] {
            if storedFingerprint == fingerprint {
                return .trusted
            } else {
                return .changed(oldFingerprint: storedFingerprint, newFingerprint: fingerprint)
            }
        }

        return .unknown(fingerprint: fingerprint)
    }

    func trustHost(host: String, port: Int, hostKey: NIOSSHPublicKey) {
        let fingerprint = calculateFingerprint(hostKey)
        let key = hostIdentifier(host: host, port: port)

        lock.lock()
        defer { lock.unlock() }

        var knownHosts = getKnownHosts()
        knownHosts[key] = fingerprint
        saveKnownHosts(knownHosts)
    }

    func removeHost(host: String, port: Int) {
        let key = hostIdentifier(host: host, port: port)

        lock.lock()
        defer { lock.unlock() }

        var knownHosts = getKnownHosts()
        knownHosts.removeValue(forKey: key)
        saveKnownHosts(knownHosts)
    }

    func getStoredFingerprint(host: String, port: Int) -> String? {
        let key = hostIdentifier(host: host, port: port)

        lock.lock()
        defer { lock.unlock() }

        return getKnownHosts()[key]
    }

    private func hostIdentifier(host: String, port: Int) -> String {
        if port == 22 {
            return host.lowercased()
        }
        return "\(host.lowercased()):\(port)"
    }

    private func calculateFingerprint(_ hostKey: NIOSSHPublicKey) -> String {
        let keyDescription = String(describing: hostKey)
        let keyData = Data(keyDescription.utf8)
        let hash = SHA256.hash(data: keyData)
        return hash.map { String(format: "%02x", $0) }.joined(separator: ":")
    }

    private func getKnownHosts() -> [String: String] {
        userDefaults.dictionary(forKey: storageKey) as? [String: String] ?? [:]
    }

    private func saveKnownHosts(_ hosts: [String: String]) {
        userDefaults.set(hosts, forKey: storageKey)
    }
}

extension String {
    var shortFingerprint: String {
        let components = self.split(separator: ":")
        if components.count > 8 {
            return components.prefix(8).joined(separator: ":") + "..."
        }
        return self
    }
}

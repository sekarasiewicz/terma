import Foundation

enum AuthMethod: String, Codable, CaseIterable {
    case password
    case sshKey

    var displayName: String {
        switch self {
        case .password:
            return "Password"
        case .sshKey:
            return "SSH Key"
        }
    }
}

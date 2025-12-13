import Foundation

enum ConnectionState: Equatable {
    case disconnected
    case connecting
    case authenticating
    case connected
    case failed(String)

    var isConnected: Bool {
        if case .connected = self {
            return true
        }
        return false
    }

    var isConnecting: Bool {
        switch self {
        case .connecting, .authenticating:
            return true
        default:
            return false
        }
    }

    var statusText: String {
        switch self {
        case .disconnected:
            return "Disconnected"
        case .connecting:
            return "Connecting..."
        case .authenticating:
            return "Authenticating..."
        case .connected:
            return "Connected"
        case .failed(let error):
            return "Failed: \(error)"
        }
    }
}

@Observable
final class TerminalSession: Identifiable {
    let id: UUID
    let profile: ServerProfile
    var connectionState: ConnectionState = .disconnected
    var title: String

    init(id: UUID = UUID(), profile: ServerProfile) {
        self.id = id
        self.profile = profile
        self.title = profile.name
    }
}

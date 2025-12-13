import SwiftUI

struct ConnectionStatusBadge: View {
    let state: ConnectionState

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)

            if state.isConnecting {
                ProgressView()
                    .scaleEffect(0.7)
            }

            Text(statusText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }

    private var statusColor: Color {
        switch state {
        case .disconnected:
            return .gray
        case .connecting, .authenticating:
            return .orange
        case .connected:
            return .green
        case .failed:
            return .red
        }
    }

    private var statusText: String {
        switch state {
        case .disconnected:
            return "Disconnected"
        case .connecting:
            return "Connecting"
        case .authenticating:
            return "Authenticating"
        case .connected:
            return "Connected"
        case .failed:
            return "Failed"
        }
    }
}

#Preview("Connected") {
    ConnectionStatusBadge(state: .connected)
}

#Preview("Connecting") {
    ConnectionStatusBadge(state: .connecting)
}

#Preview("Failed") {
    ConnectionStatusBadge(state: .failed("Test error"))
}

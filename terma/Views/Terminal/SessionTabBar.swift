import SwiftUI

struct SessionTabBar: View {
    @Binding var sessions: [TerminalSession]
    @Binding var selectedSession: TerminalSession?
    let onClose: (TerminalSession) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 2) {
                ForEach(sessions) { session in
                    SessionTab(
                        session: session,
                        isSelected: selectedSession?.id == session.id,
                        onSelect: {
                            selectedSession = session
                        },
                        onClose: {
                            onClose(session)
                        }
                    )
                }
            }
            .padding(.horizontal, 8)
        }
        .frame(height: 36)
        .background(Color(.systemGray6))
    }
}

struct SessionTab: View {
    let session: TerminalSession
    let isSelected: Bool
    let onSelect: () -> Void
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)

            Text(session.title)
                .font(.caption)
                .lineLimit(1)

            Button {
                onClose()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(isSelected ? Color(.systemBackground) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .onTapGesture {
            onSelect()
        }
    }

    private var statusColor: Color {
        switch session.connectionState {
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
}

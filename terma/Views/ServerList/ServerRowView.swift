import SwiftUI

struct ServerRowView: View {
    let profile: ServerProfile
    let onConnect: () -> Void
    let onEdit: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "server.rack")
                .font(.title2)
                .foregroundStyle(.secondary)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(profile.name)
                    .font(.headline)

                HStack(spacing: 4) {
                    Text("\(profile.username)@\(profile.displayHost)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text("•")
                        .foregroundStyle(.tertiary)

                    Image(systemName: profile.authMethod == .password ? "key.fill" : "lock.shield.fill")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            Button {
                onConnect()
            } label: {
                Image(systemName: "terminal")
                    .font(.title3)
            }
            .buttonStyle(.bordered)
            .tint(.accentColor)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .contextMenu {
            Button {
                onConnect()
            } label: {
                Label("Connect", systemImage: "terminal")
            }

            Button {
                onEdit()
            } label: {
                Label("Edit", systemImage: "pencil")
            }
        }
    }
}

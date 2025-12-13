import SwiftUI
import UniformTypeIdentifiers

struct KeyImportView: View {
    @Binding var privateKeyData: Data?
    @Binding var privateKeyName: String
    @Binding var passphrase: String
    @Binding var showingKeyImporter: Bool
    let onClear: () -> Void

    var body: some View {
        Section {
            if privateKeyData != nil {
                HStack {
                    Image(systemName: "key.fill")
                        .foregroundStyle(.green)
                    Text(privateKeyName.isEmpty ? "Private Key" : privateKeyName)
                        .lineLimit(1)
                    Spacer()
                    Button("Remove", role: .destructive) {
                        onClear()
                    }
                    .font(.subheadline)
                }

                SecureFieldWithToggle(title: "Passphrase (if encrypted)", text: $passphrase)
            } else {
                Button {
                    showingKeyImporter = true
                } label: {
                    HStack {
                        Image(systemName: "doc.badge.plus")
                        Text("Import Private Key")
                    }
                }
            }
        } header: {
            Text("SSH Key")
        } footer: {
            Text("Supports OpenSSH format keys (Ed25519, RSA)")
        }
    }
}

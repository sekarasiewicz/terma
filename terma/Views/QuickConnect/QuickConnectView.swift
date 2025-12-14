import SwiftUI

struct QuickConnectView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var host = ""
    @State private var port = "22"
    @State private var username = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var isConnecting = false
    @State private var errorMessage: String?

    var onConnect: (ServerProfile, String) -> Void

    private var isValid: Bool {
        !host.trimmingCharacters(in: .whitespaces).isEmpty &&
        !username.trimmingCharacters(in: .whitespaces).isEmpty &&
        !password.isEmpty &&
        Int(port) != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Host", text: $host)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)

                    TextField("Port", text: $port)
                        .keyboardType(.numberPad)

                    TextField("Username", text: $username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Text("Server")
                }

                Section {
                    HStack {
                        if showPassword {
                            TextField("Password", text: $password)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                        } else {
                            SecureField("Password", text: $password)
                        }

                        Button {
                            showPassword.toggle()
                        } label: {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("Authentication")
                } footer: {
                    Text("For SSH key authentication, save a server profile first.")
                        .font(.caption)
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Quick Connect")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        connect()
                    } label: {
                        if isConnecting {
                            ProgressView()
                        } else {
                            Text("Connect")
                        }
                    }
                    .disabled(!isValid || isConnecting)
                }
            }
        }
    }

    private func connect() {
        guard let portNumber = Int(port) else {
            errorMessage = "Invalid port number"
            return
        }

        isConnecting = true
        errorMessage = nil

        let profile = ServerProfile(
            name: "\(username)@\(host)",
            host: host.trimmingCharacters(in: .whitespaces),
            port: portNumber,
            username: username.trimmingCharacters(in: .whitespaces),
            authMethod: .password
        )

        onConnect(profile, password)
        dismiss()
    }
}

#Preview {
    QuickConnectView { profile, password in
        print("Connecting to \(profile.host)")
    }
}

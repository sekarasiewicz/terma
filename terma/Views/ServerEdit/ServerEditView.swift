import SwiftUI
import UniformTypeIdentifiers

struct ServerEditView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = ServerEditViewModel()

    let profile: ServerProfile?

    var body: some View {
        NavigationStack {
            Form {
                Section("Server Details") {
                    TextField("Name", text: $viewModel.name)
                        .textContentType(.name)

                    TextField("Host", text: $viewModel.host)
                        .textContentType(.URL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)

                    TextField("Port", text: $viewModel.port)
                        .keyboardType(.numberPad)

                    TextField("Username", text: $viewModel.username)
                        .textContentType(.username)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }

                Section("Authentication") {
                    Picker("Method", selection: $viewModel.authMethod) {
                        ForEach(AuthMethod.allCases, id: \.self) { method in
                            Text(method.displayName).tag(method)
                        }
                    }

                    if viewModel.authMethod == .password {
                        SecureFieldWithToggle(title: "Password", text: $viewModel.password)
                    }
                }

                if viewModel.authMethod == .sshKey {
                    KeyImportView(
                        privateKeyData: $viewModel.privateKeyData,
                        privateKeyName: $viewModel.privateKeyName,
                        passphrase: $viewModel.passphrase,
                        showingKeyImporter: $viewModel.showingKeyImporter,
                        onClear: viewModel.clearPrivateKey
                    )
                }
            }
            .navigationTitle(viewModel.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if viewModel.save() {
                            dismiss()
                        }
                    }
                    .disabled(!viewModel.canSave)
                }
            }
            .fileImporter(
                isPresented: $viewModel.showingKeyImporter,
                allowedContentTypes: [.item],
                allowsMultipleSelection: false
            ) { result in
                if case .success(let urls) = result, let url = urls.first {
                    viewModel.importKey(from: .success(url))
                } else if case .failure(let error) = result {
                    viewModel.importKey(from: .failure(error))
                }
            }
            .alert("Error", isPresented: $viewModel.showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "An unknown error occurred")
            }
            .onAppear {
                viewModel.loadProfile(profile)
            }
        }
    }
}

#Preview("Add Server") {
    ServerEditView(profile: nil)
}

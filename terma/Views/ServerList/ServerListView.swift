import SwiftUI
import LocalAuthentication

struct ServerListView: View {
    @State private var viewModel = ServerListViewModel()
    @State private var biometricEnabled = AppSettings.shared.biometricEnabled
    @State private var biometricAvailable = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.profiles.isEmpty {
                    emptyStateView
                } else {
                    profileListView
                }
            }
            .navigationTitle("Servers")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        if biometricAvailable {
                            Toggle(isOn: $biometricEnabled) {
                                Label("Require Face ID", systemImage: "faceid")
                            }
                            .onChange(of: biometricEnabled) { _, newValue in
                                AppSettings.shared.biometricEnabled = newValue
                            }
                        }

                        Button {
                            viewModel.showQuickConnect()
                        } label: {
                            Label("Quick Connect", systemImage: "bolt")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.addNewProfile()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingQuickConnect) {
                QuickConnectView { profile, password in
                    viewModel.quickConnect(profile: profile, password: password)
                }
            }
            .sheet(isPresented: $viewModel.showingAddSheet) {
                viewModel.onProfileSaved()
            } content: {
                ServerEditView(profile: nil)
            }
            .sheet(isPresented: $viewModel.showingEditSheet) {
                viewModel.onProfileSaved()
            } content: {
                if let profile = viewModel.profileToEdit {
                    ServerEditView(profile: profile)
                }
            }
            .fullScreenCover(isPresented: $viewModel.showingTerminal) {
                if let session = viewModel.activeSession {
                    TerminalContainerView(session: session)
                }
            }
            .onAppear {
                viewModel.loadProfiles()
                checkBiometricAvailability()
            }
        }
    }

    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Servers", systemImage: "server.rack")
        } description: {
            Text("Add a server to connect via SSH")
        } actions: {
            HStack(spacing: 16) {
                Button {
                    viewModel.showQuickConnect()
                } label: {
                    Label("Quick Connect", systemImage: "bolt")
                }
                .buttonStyle(.bordered)

                Button {
                    viewModel.addNewProfile()
                } label: {
                    Text("Add Server")
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private var profileListView: some View {
        List {
            ForEach(viewModel.profiles) { profile in
                ServerRowView(
                    profile: profile,
                    onConnect: { viewModel.connectToProfile(profile) },
                    onEdit: { viewModel.editProfile(profile) }
                )
            }
            .onDelete { offsets in
                viewModel.deleteProfiles(at: offsets)
            }
        }
        .listStyle(.insetGrouped)
    }

    private func checkBiometricAvailability() {
        let context = LAContext()
        var error: NSError?
        biometricAvailable = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
}

#Preview {
    ServerListView()
}

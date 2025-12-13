import SwiftUI

struct ServerListView: View {
    @State private var viewModel = ServerListViewModel()

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
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.addNewProfile()
                    } label: {
                        Image(systemName: "plus")
                    }
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
            }
        }
    }

    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Servers", systemImage: "server.rack")
        } description: {
            Text("Add a server to connect via SSH")
        } actions: {
            Button {
                viewModel.addNewProfile()
            } label: {
                Text("Add Server")
            }
            .buttonStyle(.borderedProminent)
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
}

#Preview {
    ServerListView()
}

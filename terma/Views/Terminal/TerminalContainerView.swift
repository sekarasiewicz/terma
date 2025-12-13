import SwiftUI

struct TerminalContainerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: TerminalViewModel
    @State private var showingExtraKeys = true
    @State private var ctrlActive = false
    @State private var altActive = false

    init(session: TerminalSession) {
        _viewModel = State(initialValue: TerminalViewModel(session: session))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TerminalViewRepresentable(viewModel: viewModel)
                    .ignoresSafeArea(.keyboard)

                if showingExtraKeys {
                    ExtraKeysBar(
                        viewModel: viewModel,
                        ctrlActive: $ctrlActive,
                        altActive: $altActive
                    )
                }
            }
            .navigationTitle(viewModel.session.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        viewModel.disconnect()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }

                ToolbarItem(placement: .principal) {
                    ConnectionStatusBadge(state: viewModel.connectionState)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showingExtraKeys.toggle()
                        } label: {
                            Label(
                                showingExtraKeys ? "Hide Extra Keys" : "Show Extra Keys",
                                systemImage: showingExtraKeys ? "keyboard.chevron.compact.down" : "keyboard"
                            )
                        }

                        if viewModel.connectionState == .disconnected ||
                           viewModel.connectionState.isConnecting == false &&
                           viewModel.connectionState.isConnected == false {
                            Button {
                                Task {
                                    await viewModel.reconnect()
                                }
                            } label: {
                                Label("Reconnect", systemImage: "arrow.clockwise")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .task {
                await viewModel.connect()
            }
            .alert("Disconnected", isPresented: $viewModel.showingDisconnectAlert) {
                Button("Reconnect") {
                    Task {
                        await viewModel.reconnect()
                    }
                }
                Button("Close", role: .cancel) {
                    dismiss()
                }
            } message: {
                Text(viewModel.disconnectError ?? "Connection lost")
            }
        }
    }
}

import SwiftUI

struct TerminalContainerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: TerminalViewModel
    @State private var showingExtraKeys = true
    @State private var ctrlActive = false
    @State private var altActive = false
    @State private var currentScale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0

    init(session: TerminalSession) {
        _viewModel = State(initialValue: TerminalViewModel(session: session))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if viewModel.isSearching {
                    TerminalSearchBar(
                        searchText: $viewModel.searchText,
                        isSearching: $viewModel.isSearching,
                        currentMatch: viewModel.currentMatchIndex,
                        totalMatches: viewModel.searchMatchRows.count,
                        onSearch: { viewModel.performSearch() },
                        onNext: { viewModel.nextMatch() },
                        onPrevious: { viewModel.previousMatch() },
                        onDismiss: { viewModel.toggleSearch() }
                    )
                }

                TerminalViewRepresentable(viewModel: viewModel)
                    .ignoresSafeArea(.keyboard)
                    .gesture(
                        MagnifyGesture()
                            .onChanged { value in
                                let delta = value.magnification / lastScale
                                lastScale = value.magnification
                                viewModel.handlePinchGesture(scale: delta)
                            }
                            .onEnded { _ in
                                lastScale = 1.0
                            }
                    )

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
                    Button {
                        viewModel.toggleSearch()
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }
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

                        Divider()

                        Menu {
                            Button {
                                viewModel.increaseFontSize()
                            } label: {
                                Label("Increase Size", systemImage: "plus.magnifyingglass")
                            }

                            Button {
                                viewModel.decreaseFontSize()
                            } label: {
                                Label("Decrease Size", systemImage: "minus.magnifyingglass")
                            }

                            Divider()

                            Text("Size: \(Int(viewModel.fontSize))pt")
                        } label: {
                            Label("Font Size", systemImage: "textformat.size")
                        }

                        Menu {
                            ForEach(TerminalTheme.allCases) { theme in
                                Button {
                                    AppSettings.shared.terminalTheme = theme
                                    viewModel.applyTheme(theme)
                                } label: {
                                    HStack {
                                        Text(theme.displayName)
                                        if AppSettings.shared.terminalTheme == theme {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            Label("Theme", systemImage: "paintpalette")
                        }

                        Divider()

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
            .alert(viewModel.hostKeyAlertTitle, isPresented: $viewModel.showingHostKeyAlert) {
                Button(viewModel.hostKeyAlertIsWarning ? "Connect Anyway" : "Trust", role: viewModel.hostKeyAlertIsWarning ? .destructive : nil) {
                    viewModel.acceptHostKey()
                }
                Button("Cancel", role: .cancel) {
                    viewModel.rejectHostKey()
                    dismiss()
                }
            } message: {
                VStack {
                    Text(viewModel.hostKeyAlertMessage)
                    Text(viewModel.hostKeyAlertFingerprint)
                        .font(.system(.caption, design: .monospaced))
                }
            }
        }
    }
}

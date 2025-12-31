import Foundation
import SwiftTerm
import SwiftUI

@Observable
@MainActor
final class TerminalViewModel {
    let session: TerminalSession
    private(set) var sshService: SSHService?
    var terminalView: TerminalView?

    var connectionState: ConnectionState {
        session.connectionState
    }

    var shouldReconnect = false
    var showingDisconnectAlert = false
    var disconnectError: String?
    var autoReconnect = true
    var reconnectAttempts = 0
    private let maxReconnectAttempts = 3
    private var isManualDisconnect = false

    var showingHostKeyAlert = false
    var hostKeyAlertTitle = ""
    var hostKeyAlertMessage = ""
    var hostKeyAlertFingerprint = ""
    var hostKeyAlertIsWarning = false
    private var hostKeyVerificationContinuation: CheckedContinuation<Bool, Never>?

    var fontSize: CGFloat = 14 {
        didSet {
            fontSize = min(max(fontSize, 8), 32)
            updateTerminalFont()
        }
    }

    var isSearching = false
    var searchText = ""
    var searchMatchRows: [Int] = []
    var currentMatchIndex = 0

    init(session: TerminalSession) {
        self.session = session
    }

    func setupTerminal(_ terminal: TerminalView) {
        terminalView = terminal
        terminal.font = UIFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        applyTheme(AppSettings.shared.terminalTheme)
    }

    func applyTheme(_ theme: TerminalTheme) {
        terminalView?.nativeBackgroundColor = theme.backgroundColor
        terminalView?.nativeForegroundColor = theme.foregroundColor
    }

    private func updateTerminalFont() {
        terminalView?.font = UIFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
    }

    func increaseFontSize() {
        fontSize += 2
    }

    func decreaseFontSize() {
        fontSize -= 2
    }

    func handlePinchGesture(scale: CGFloat) {
        let newSize = fontSize * scale
        fontSize = newSize
    }

    func connect() async {
        let service = SSHService()
        sshService = service

        service.onDataReceived = { [weak self] data in
            guard let self else { return }
            Task { @MainActor in
                self.handleDataReceived(data)
            }
        }

        service.onStateChanged = { [weak self] state in
            guard let self else { return }
            Task { @MainActor in
                self.session.connectionState = state
            }
        }

        service.onDisconnected = { [weak self] error in
            guard let self else { return }
            Task { @MainActor in
                self.handleDisconnect(error)
            }
        }

        service.onHostKeyVerification = { [weak self] host, fingerprint, result in
            await self?.handleHostKeyVerification(host: host, fingerprint: fingerprint, result: result) ?? false
        }

        do {
            try await service.connect(to: session.profile, temporaryPassword: session.temporaryPassword)
            sendInitialResize()
        } catch {
            session.connectionState = .failed(error.localizedDescription)
        }
    }

    private func handleHostKeyVerification(host: String, fingerprint: String, result: HostKeyVerificationResult) async -> Bool {
        switch result {
        case .trusted:
            return true
        case .unknown:
            hostKeyAlertTitle = "Unknown Host"
            hostKeyAlertMessage = "The authenticity of host '\(host)' can't be established.\n\nFingerprint:"
            hostKeyAlertFingerprint = fingerprint
            hostKeyAlertIsWarning = false
        case .changed(let oldFingerprint, let newFingerprint):
            hostKeyAlertTitle = "WARNING: Host Key Changed!"
            hostKeyAlertMessage = "The host key for '\(host)' has changed.\n\nThis could indicate a man-in-the-middle attack!\n\nOld fingerprint: \(oldFingerprint.shortFingerprint)\n\nNew fingerprint:"
            hostKeyAlertFingerprint = newFingerprint
            hostKeyAlertIsWarning = true
        }

        showingHostKeyAlert = true

        return await withCheckedContinuation { continuation in
            hostKeyVerificationContinuation = continuation
        }
    }

    func acceptHostKey() {
        hostKeyVerificationContinuation?.resume(returning: true)
        hostKeyVerificationContinuation = nil
        showingHostKeyAlert = false
    }

    func rejectHostKey() {
        hostKeyVerificationContinuation?.resume(returning: false)
        hostKeyVerificationContinuation = nil
        showingHostKeyAlert = false
    }

    private func handleDataReceived(_ data: Data) {
        guard let terminal = terminalView else { return }
        let bytes = [UInt8](data)
        terminal.feed(byteArray: ArraySlice(bytes))
    }

    private func handleDisconnect(_ error: Error?) {
        session.connectionState = .disconnected

        guard !isManualDisconnect else {
            isManualDisconnect = false
            return
        }

        if autoReconnect && reconnectAttempts < maxReconnectAttempts {
            reconnectAttempts += 1
            Task {
                try? await Task.sleep(for: .seconds(Constants.reconnectDelay))
                await reconnect()
            }
        } else {
            if let error = error {
                disconnectError = error.localizedDescription
            } else {
                disconnectError = "Connection lost"
            }
            showingDisconnectAlert = true
            reconnectAttempts = 0
        }
    }

    func sendData(_ data: Data) {
        sshService?.send(data)
    }

    func sendString(_ string: String) {
        guard let data = string.data(using: .utf8) else { return }
        sendData(data)
    }

    func sendControlCharacter(_ char: Character) {
        guard let ascii = char.asciiValue else { return }
        let controlCode = ascii - 64
        sendData(Data([controlCode]))
    }

    func sendEscape() {
        sendData(Data([0x1B]))
    }

    func sendTab() {
        sendData(Data([0x09]))
    }

    func sendArrowUp() {
        sendString("\u{1B}[A")
    }

    func sendArrowDown() {
        sendString("\u{1B}[B")
    }

    func sendArrowRight() {
        sendString("\u{1B}[C")
    }

    func sendArrowLeft() {
        sendString("\u{1B}[D")
    }

    func sendHome() {
        sendString("\u{1B}[H")
    }

    func sendEnd() {
        sendString("\u{1B}[F")
    }

    func sendPageUp() {
        sendString("\u{1B}[5~")
    }

    func sendPageDown() {
        sendString("\u{1B}[6~")
    }

    func toggleSearch() {
        isSearching.toggle()
        if !isSearching {
            clearSearch()
        }
    }

    func performSearch() {
        guard let terminal = terminalView, !searchText.isEmpty else {
            searchMatchRows = []
            currentMatchIndex = 0
            return
        }

        let term = terminal.getTerminal()
        let searchLower = searchText.lowercased()
        var matches: [Int] = []

        let totalRows = term.rows + term.buffer.yDisp
        for row in 0..<totalRows {
            if let line = term.getScrollInvariantLine(row: row) {
                var lineText = ""
                for col in 0..<term.cols {
                    let char = line[col].getCharacter()
                    lineText.append(char)
                }
                if lineText.lowercased().contains(searchLower) {
                    matches.append(row)
                }
            }
        }

        searchMatchRows = matches
        currentMatchIndex = matches.isEmpty ? 0 : 1

        if let firstRow = matches.first {
            scrollToRow(firstRow)
        }
    }

    func nextMatch() {
        guard !searchMatchRows.isEmpty else { return }
        currentMatchIndex = currentMatchIndex < searchMatchRows.count ? currentMatchIndex + 1 : 1
        let row = searchMatchRows[currentMatchIndex - 1]
        scrollToRow(row)
    }

    func previousMatch() {
        guard !searchMatchRows.isEmpty else { return }
        currentMatchIndex = currentMatchIndex > 1 ? currentMatchIndex - 1 : searchMatchRows.count
        let row = searchMatchRows[currentMatchIndex - 1]
        scrollToRow(row)
    }

    private func scrollToRow(_ row: Int) {
        guard let terminal = terminalView else { return }
        let term = terminal.getTerminal()
        let scrollRow = max(0, row - term.rows / 2)
        term.buffer.yDisp = scrollRow
        term.updateFullScreen()
    }

    func clearSearch() {
        searchText = ""
        searchMatchRows = []
        currentMatchIndex = 0
    }

    func resize(cols: Int, rows: Int) {
        sshService?.resize(cols: cols, rows: rows)
    }

    private func sendInitialResize() {
        guard let terminal = terminalView else { return }
        let cols = terminal.getTerminal().cols
        let rows = terminal.getTerminal().rows
        resize(cols: cols, rows: rows)
    }

    func disconnect() {
        isManualDisconnect = true
        sshService?.disconnect()
        sshService = nil
    }

    func reconnect() async {
        isManualDisconnect = true
        sshService?.disconnect()
        sshService = nil
        isManualDisconnect = false
        reconnectAttempts = 0
        await connect()
    }
}

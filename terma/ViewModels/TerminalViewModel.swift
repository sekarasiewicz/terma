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

    init(session: TerminalSession) {
        self.session = session
    }

    func setupTerminal(_ terminal: TerminalView) {
        terminalView = terminal
        terminal.font = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        terminal.nativeBackgroundColor = .black
        terminal.nativeForegroundColor = .white
    }

    func connect() async {
        let service = SSHService()
        sshService = service

        service.onDataReceived = { [weak self] data in
            Task { @MainActor in
                self?.handleDataReceived(data)
            }
        }

        service.onStateChanged = { [weak self] state in
            Task { @MainActor in
                self?.session.connectionState = state
            }
        }

        service.onDisconnected = { [weak self] error in
            Task { @MainActor in
                self?.handleDisconnect(error)
            }
        }

        do {
            try await service.connect(to: session.profile)
            sendInitialResize()
        } catch {
            session.connectionState = .failed(error.localizedDescription)
        }
    }

    private func handleDataReceived(_ data: Data) {
        guard let terminal = terminalView else { return }
        let bytes = [UInt8](data)
        terminal.feed(byteArray: ArraySlice(bytes))
    }

    private func handleDisconnect(_ error: Error?) {
        if let error = error {
            disconnectError = error.localizedDescription
            showingDisconnectAlert = true
        }
        session.connectionState = .disconnected
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
        sshService?.disconnect()
        sshService = nil
    }

    func reconnect() async {
        disconnect()
        await connect()
    }
}

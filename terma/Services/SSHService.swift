import Foundation
import NIOCore
import NIOPosix
import NIOFoundationCompat
import NIOSSH
import Crypto

enum SSHError: LocalizedError {
    case connectionFailed(String)
    case authenticationFailed
    case channelCreationFailed
    case ptyRequestFailed
    case shellRequestFailed
    case disconnected
    case invalidKey
    case hostKeyVerificationFailed
    case hostKeyChanged(oldFingerprint: String, newFingerprint: String)
    case hostKeyRejected

    var errorDescription: String? {
        switch self {
        case .connectionFailed(let reason):
            return "Connection failed: \(reason)"
        case .authenticationFailed:
            return "Authentication failed"
        case .channelCreationFailed:
            return "Failed to create SSH channel"
        case .ptyRequestFailed:
            return "Failed to allocate PTY"
        case .shellRequestFailed:
            return "Failed to start shell"
        case .disconnected:
            return "Disconnected from server"
        case .invalidKey:
            return "Invalid SSH key format"
        case .hostKeyVerificationFailed:
            return "Host key verification failed"
        case .hostKeyChanged:
            return "WARNING: Host key has changed! This could indicate a security threat."
        case .hostKeyRejected:
            return "Host key rejected by user"
        }
    }
}

typealias HostKeyVerificationCallback = @Sendable (String, String, HostKeyVerificationResult) async -> Bool

final class SSHService: @unchecked Sendable {
    private var channel: Channel?
    private var sshChannel: Channel?
    private let group: MultiThreadedEventLoopGroup
    private var terminalCols: Int = Constants.defaultTerminalCols
    private var terminalRows: Int = Constants.defaultTerminalRows
    private var currentHost: String = ""
    private var currentPort: Int = 22

    var onDataReceived: (@Sendable (Data) -> Void)?
    var onStateChanged: (@Sendable (ConnectionState) -> Void)?
    var onDisconnected: (@Sendable (Error?) -> Void)?
    var onHostKeyVerification: HostKeyVerificationCallback?

    private var _connectionState: ConnectionState = .disconnected
    var connectionState: ConnectionState {
        get { _connectionState }
        set {
            _connectionState = newValue
            onStateChanged?(newValue)
        }
    }

    init() {
        group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    }

    deinit {
        try? group.syncShutdownGracefully()
    }

    func connect(to profile: ServerProfile, temporaryPassword: String? = nil) async throws {
        connectionState = .connecting
        currentHost = profile.host
        currentPort = profile.port

        let password: String?
        let privateKeyData: Data?
        let passphrase: String?

        if let tempPwd = temporaryPassword {
            password = tempPwd
            privateKeyData = nil
            passphrase = nil
        } else {
            do {
                password = try KeychainService.shared.getPassword(for: profile.keychainPasswordKey)
                privateKeyData = try KeychainService.shared.getPrivateKey(for: profile.keychainPrivateKeyKey)
                passphrase = try KeychainService.shared.getPassphrase(for: profile.keychainPassphraseKey)
            } catch {
                connectionState = .failed("Failed to load credentials")
                throw SSHError.authenticationFailed
            }
        }

        let authDelegate: NIOSSHClientUserAuthenticationDelegate
        switch profile.authMethod {
        case .password:
            guard let pwd = password, !pwd.isEmpty else {
                connectionState = .failed("No password configured")
                throw SSHError.authenticationFailed
            }
            authDelegate = PasswordAuthDelegate(username: profile.username, password: pwd)
        case .sshKey:
            guard let keyData = privateKeyData else {
                connectionState = .failed("No SSH key configured")
                throw SSHError.authenticationFailed
            }
            authDelegate = PrivateKeyAuthDelegate(
                username: profile.username,
                privateKeyData: keyData,
                passphrase: passphrase
            )
        }

        let hostKeyDelegate = VerifyingHostKeyDelegate(
            host: profile.host,
            port: profile.port,
            verificationCallback: onHostKeyVerification
        )

        do {
            let bootstrap = ClientBootstrap(group: group)
                .channelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
                .channelInitializer { channel in
                    channel.pipeline.addHandlers([
                        NIOSSHHandler(
                            role: .client(.init(
                                userAuthDelegate: authDelegate,
                                serverAuthDelegate: hostKeyDelegate
                            )),
                            allocator: channel.allocator,
                            inboundChildChannelInitializer: nil
                        ),
                    ])
                }

            channel = try await bootstrap.connect(host: profile.host, port: profile.port).get()
            connectionState = .authenticating

            try await createShellChannel()
            connectionState = .connected
        } catch let error as SSHError {
            connectionState = .failed(error.localizedDescription)
            throw error
        } catch {
            connectionState = .failed(error.localizedDescription)
            throw SSHError.connectionFailed(error.localizedDescription)
        }
    }

    private func createShellChannel() async throws {
        guard let channel = channel else {
            throw SSHError.channelCreationFailed
        }

        let sshHandler = try await channel.pipeline.handler(type: NIOSSHHandler.self).get()

        let promise = channel.eventLoop.makePromise(of: Channel.self)

        sshHandler.createChannel(promise) { childChannel, channelType in
            guard channelType == .session else {
                return childChannel.eventLoop.makeFailedFuture(SSHError.channelCreationFailed)
            }
            return childChannel.pipeline.addHandlers([
                SSHChannelDataHandler(onData: { [weak self] data in
                    self?.onDataReceived?(data)
                }),
                SSHOutboundHandler(),
            ])
        }

        let childChannel = try await promise.futureResult.get()
        sshChannel = childChannel

        let ptyRequest = SSHChannelRequestEvent.PseudoTerminalRequest(
            wantReply: true,
            term: Constants.defaultTerminalType,
            terminalCharacterWidth: terminalCols,
            terminalRowHeight: terminalRows,
            terminalPixelWidth: 0,
            terminalPixelHeight: 0,
            terminalModes: SSHTerminalModes([:])
        )

        try await childChannel.triggerUserOutboundEvent(ptyRequest).get()

        let shellRequest = SSHChannelRequestEvent.ShellRequest(wantReply: true)
        try await childChannel.triggerUserOutboundEvent(shellRequest).get()
    }

    func send(_ data: Data) {
        guard let channel = sshChannel else { return }
        let buffer = channel.allocator.buffer(data: data)
        let dataMessage = SSHChannelData(type: .channel, data: .byteBuffer(buffer))
        channel.writeAndFlush(dataMessage, promise: nil)
    }

    func resize(cols: Int, rows: Int) {
        terminalCols = cols
        terminalRows = rows

        guard let channel = sshChannel else { return }

        let resizeRequest = SSHChannelRequestEvent.WindowChangeRequest(
            terminalCharacterWidth: cols,
            terminalRowHeight: rows,
            terminalPixelWidth: 0,
            terminalPixelHeight: 0
        )
        channel.triggerUserOutboundEvent(resizeRequest, promise: nil)
    }

    func disconnect() {
        sshChannel?.close(promise: nil)
        channel?.close(promise: nil)
        sshChannel = nil
        channel = nil
        connectionState = .disconnected
        onDisconnected?(nil)
    }
}

private final class PasswordAuthDelegate: NIOSSHClientUserAuthenticationDelegate {
    private let username: String
    private let password: String
    private var attemptedAuth = false

    init(username: String, password: String) {
        self.username = username
        self.password = password
    }

    func nextAuthenticationType(
        availableMethods: NIOSSHAvailableUserAuthenticationMethods,
        nextChallengePromise: EventLoopPromise<NIOSSHUserAuthenticationOffer?>
    ) {
        if attemptedAuth {
            nextChallengePromise.succeed(nil)
            return
        }
        attemptedAuth = true

        if availableMethods.contains(.password) {
            nextChallengePromise.succeed(.init(
                username: username,
                serviceName: "",
                offer: .password(.init(password: password))
            ))
        } else {
            nextChallengePromise.succeed(nil)
        }
    }
}

private final class PrivateKeyAuthDelegate: NIOSSHClientUserAuthenticationDelegate {
    private let username: String
    private let privateKeyData: Data
    private let passphrase: String?
    private var attemptedAuth = false

    init(username: String, privateKeyData: Data, passphrase: String?) {
        self.username = username
        self.privateKeyData = privateKeyData
        self.passphrase = passphrase
    }

    func nextAuthenticationType(
        availableMethods: NIOSSHAvailableUserAuthenticationMethods,
        nextChallengePromise: EventLoopPromise<NIOSSHUserAuthenticationOffer?>
    ) {
        if attemptedAuth {
            nextChallengePromise.succeed(nil)
            return
        }
        attemptedAuth = true

        guard availableMethods.contains(.publicKey) else {
            nextChallengePromise.succeed(nil)
            return
        }

        do {
            let privateKey = try parsePrivateKey(privateKeyData, passphrase: passphrase)
            nextChallengePromise.succeed(.init(
                username: username,
                serviceName: "",
                offer: .privateKey(.init(privateKey: privateKey))
            ))
        } catch {
            nextChallengePromise.succeed(nil)
        }
    }

    private func parsePrivateKey(_ data: Data, passphrase: String?) throws -> NIOSSHPrivateKey {
        guard let pemString = String(data: data, encoding: .utf8) else {
            throw SSHError.invalidKey
        }

        if pemString.contains("ssh-ed25519") || pemString.contains("OPENSSH") {
            let key = try Curve25519.Signing.PrivateKey(rawRepresentation: extractEd25519Key(from: data))
            return NIOSSHPrivateKey(ed25519Key: key)
        }

        throw SSHError.invalidKey
    }

    private func extractEd25519Key(from data: Data) throws -> Data {
        guard let pemString = String(data: data, encoding: .utf8) else {
            throw SSHError.invalidKey
        }

        let lines = pemString.components(separatedBy: .newlines)
            .filter { !$0.hasPrefix("-----") && !$0.isEmpty }
        let base64String = lines.joined()

        guard let decodedData = Data(base64Encoded: base64String) else {
            throw SSHError.invalidKey
        }

        if decodedData.count >= 32 {
            return decodedData.suffix(32)
        }

        throw SSHError.invalidKey
    }
}

private final class VerifyingHostKeyDelegate: NIOSSHClientServerAuthenticationDelegate {
    private let host: String
    private let port: Int
    private let verificationCallback: HostKeyVerificationCallback?

    init(host: String, port: Int, verificationCallback: HostKeyVerificationCallback?) {
        self.host = host
        self.port = port
        self.verificationCallback = verificationCallback
    }

    func validateHostKey(hostKey: NIOSSHPublicKey, validationCompletePromise: EventLoopPromise<Void>) {
        let result = HostKeyService.shared.verify(host: host, port: port, hostKey: hostKey)

        switch result {
        case .trusted:
            validationCompletePromise.succeed(())

        case .unknown, .changed:
            guard let callback = verificationCallback else {
                HostKeyService.shared.trustHost(host: host, port: port, hostKey: hostKey)
                validationCompletePromise.succeed(())
                return
            }

            let fingerprintString = extractFingerprint(from: result)

            Task {
                let accepted = await callback(host, fingerprintString, result)
                if accepted {
                    HostKeyService.shared.trustHost(host: host, port: port, hostKey: hostKey)
                    validationCompletePromise.succeed(())
                } else {
                    validationCompletePromise.fail(SSHError.hostKeyRejected)
                }
            }
        }
    }

    private func extractFingerprint(from result: HostKeyVerificationResult) -> String {
        switch result {
        case .trusted:
            return ""
        case .unknown(let fingerprint):
            return fingerprint
        case .changed(_, let newFingerprint):
            return newFingerprint
        }
    }
}

private final class SSHChannelDataHandler: ChannelInboundHandler {
    typealias InboundIn = SSHChannelData
    typealias InboundOut = ByteBuffer

    private let onData: @Sendable (Data) -> Void

    init(onData: @escaping @Sendable (Data) -> Void) {
        self.onData = onData
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let channelData = unwrapInboundIn(data)

        guard case .byteBuffer(var buffer) = channelData.data else { return }
        guard let bytes = buffer.readBytes(length: buffer.readableBytes) else { return }

        onData(Data(bytes))
    }

    func errorCaught(context: ChannelHandlerContext, error: Error) {
        context.close(promise: nil)
    }
}

private final class SSHOutboundHandler: ChannelOutboundHandler {
    typealias OutboundIn = SSHChannelData
    typealias OutboundOut = SSHChannelData

    func write(context: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
        context.write(data, promise: promise)
    }
}

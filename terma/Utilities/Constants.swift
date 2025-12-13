import Foundation

enum Constants {
    static let defaultPort = 22
    static let defaultTerminalType = "xterm-256color"
    static let defaultTerminalCols = 80
    static let defaultTerminalRows = 24
    static let reconnectDelay: TimeInterval = 2.0
    static let connectionTimeout: TimeInterval = 30.0
}

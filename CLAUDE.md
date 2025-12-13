# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Terma is a native iOS SSH client app built with SwiftUI. The primary use case is running Claude Code CLI and git operations on remote servers via full interactive terminal sessions.

## Build Commands

```bash
# Build the project
xcodebuild -project terma.xcodeproj -scheme terma -destination 'platform=iOS Simulator,name=iPhone 16' build

# Run tests
xcodebuild -project terma.xcodeproj -scheme terma -destination 'platform=iOS Simulator,name=iPhone 16' test

# Run a single test class
xcodebuild -project terma.xcodeproj -scheme terma -destination 'platform=iOS Simulator,name=iPhone 16' test -only-testing:termaTests/TestClassName

# Run a single test method
xcodebuild -project terma.xcodeproj -scheme terma -destination 'platform=iOS Simulator,name=iPhone 16' test -only-testing:termaTests/TestClassName/testMethodName
```

## Technical Stack

- **Language:** Swift 5.9+
- **UI Framework:** SwiftUI
- **Minimum iOS:** 17.0
- **Terminal Emulation:** SwiftTerm (github.com/migueldeicaza/SwiftTerm)
- **SSH Protocol:** SwiftNIO SSH (github.com/apple/swift-nio-ssh)
- **Secure Storage:** iOS Keychain via KeychainAccess library

## Planned Architecture

The app follows MVVM pattern with these layers:

- **Models:** `ServerProfile`, `AuthMethod`, `SessionState` - data structures for connection profiles and session management
- **Services:** `SSHService` (SwiftNIO SSH wrapper), `KeychainService` (credential CRUD), `ProfileStorage` (profile persistence)
- **ViewModels:** Coordinate between services and views
- **Views:** SwiftUI views organized by feature (ServerList, ServerEdit, Terminal)

### Key Integration Points

- **SwiftTerm:** Use `UIViewRepresentable` to wrap `TerminalView` (UIKit) for SwiftUI
- **SSH I/O:** Connect `SSHService.onDataReceived` to `terminalView.feed()`, and terminal delegate's `send()` to `SSHService.send()`
- **PTY:** Request with `xterm-256color` terminal type for full color support

## SPM Dependencies (to be added)

```swift
dependencies: [
    .package(url: "https://github.com/migueldeicaza/SwiftTerm.git", from: "1.2.0"),
    .package(url: "https://github.com/apple/swift-nio-ssh.git", from: "0.8.0"),
    .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.2.2"),
]
```

## Implementation Notes

- Store credentials in iOS Keychain only, never UserDefaults
- Support both password and SSH key (Ed25519, RSA) authentication
- Handle window resize by updating PTY size
- iOS aggressively kills background connections - implement reconnection logic

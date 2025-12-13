# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Terma is a native iOS SSH client app built with SwiftUI. The primary use case is running Claude Code CLI and git operations on remote servers via full interactive terminal sessions.

## Build Commands

```bash
# Build the project
xcodebuild -project terma.xcodeproj -scheme terma -destination 'platform=iOS Simulator,name=Phone' build

# Run tests
xcodebuild -project terma.xcodeproj -scheme terma -destination 'platform=iOS Simulator,name=Phone' test

# Run a single test class
xcodebuild -project terma.xcodeproj -scheme terma -destination 'platform=iOS Simulator,name=Phone' test -only-testing:termaTests/TestClassName

# Run a single test method
xcodebuild -project terma.xcodeproj -scheme terma -destination 'platform=iOS Simulator,name=Phone' test -only-testing:termaTests/TestClassName/testMethodName
```

## Technical Stack

- **Language:** Swift 5.9+
- **UI Framework:** SwiftUI
- **Minimum iOS:** 17.0
- **Terminal Emulation:** SwiftTerm (github.com/migueldeicaza/SwiftTerm)
- **SSH Protocol:** SwiftNIO SSH (github.com/apple/swift-nio-ssh)
- **Secure Storage:** iOS Keychain via KeychainAccess library

## Architecture

The app follows MVVM pattern with these layers:

- **Models:** `ServerProfile` (SwiftData), `AuthMethod`, `SessionState`/`TerminalSession`
- **Services:** `SSHService` (SwiftNIO SSH wrapper), `KeychainService` (credential CRUD), `ProfileStorage` (SwiftData persistence)
- **ViewModels:** `ServerListViewModel`, `ServerEditViewModel`, `TerminalViewModel`
- **Views:** Organized by feature in `Views/ServerList/`, `Views/ServerEdit/`, `Views/Terminal/`, `Views/Components/`

### Key Integration Points

- **SwiftTerm:** `TerminalViewRepresentable` wraps `TerminalView` (UIKit) for SwiftUI
- **SSH I/O:** `SSHService.onDataReceived` feeds `terminalView.feed()`, terminal delegate's `send()` calls `SSHService.send()`
- **PTY:** Request with `xterm-256color` terminal type, handle resize via `SSHChannelRequestEvent.WindowChangeRequest`

## SPM Dependencies

- SwiftTerm (1.2.0+) - Terminal emulation
- swift-nio-ssh (0.8.0+) - SSH protocol
- KeychainAccess (4.2.2+) - Secure credential storage

## Implementation Notes

- Store credentials in iOS Keychain only, never UserDefaults
- Support both password and SSH key (Ed25519, RSA) authentication
- Handle window resize by updating PTY size
- iOS aggressively kills background connections - implement reconnection logic

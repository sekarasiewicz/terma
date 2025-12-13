# iOS SSH Client App — Project Specification

## Overview

Build a native iOS SSH client app using SwiftUI that supports full interactive terminal sessions. Primary use case: running Claude Code CLI and git operations on remote servers.

## Technical Stack

- **Language:** Swift 5.9+
- **UI Framework:** SwiftUI
- **Minimum iOS:** 17.0
- **Terminal Emulation:** SwiftTerm (https://github.com/migueldeicaza/SwiftTerm)
- **SSH Protocol:** SwiftNIO SSH (https://github.com/apple/swift-nio-ssh)
- **Secure Storage:** iOS Keychain via KeychainAccess library

## Dependencies (Package.swift / SPM)

```swift
dependencies: [
    .package(url: "https://github.com/migueldeicaza/SwiftTerm.git", from: "1.2.0"),
    .package(url: "https://github.com/apple/swift-nio-ssh.git", from: "0.8.0"),
    .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.2.2"),
]
```

## Core Features (MVP)

### 1. Connection Management
- Add/edit/delete server profiles
- Store profiles in UserDefaults or SwiftData
- Each profile contains:
  - Name (display label)
  - Host (IP or domain)
  - Port (default 22)
  - Username
  - Auth method (password or SSH key)
  - Reference to Keychain-stored credentials

### 2. Authentication
- Password authentication
- SSH key authentication (Ed25519, RSA)
- Import private keys from Files app
- Generate new SSH key pairs in-app (stretch goal)
- All secrets stored in iOS Keychain (never UserDefaults)

### 3. Terminal Session
- Full PTY allocation for interactive sessions
- SwiftTerm-based terminal view
- Support for:
  - ANSI colors (256 color)
  - Cursor movement
  - Line editing
  - Scrollback buffer
- Keyboard handling:
  - Standard text input
  - Extra row with Ctrl, Tab, Esc, Arrow keys, pipe, etc.
  - Hardware keyboard support

### 4. Session Management
- Multiple concurrent sessions (tabs)
- Reconnect on disconnect
- Background session keep-alive (within iOS limits)

## Project Structure

```
iTerminal/
├── iTerminal.xcodeproj
├── iTerminal/
│   ├── App/
│   │   ├── iTerminalApp.swift          # App entry point
│   │   └── ContentView.swift           # Root navigation
│   │
│   ├── Models/
│   │   ├── ServerProfile.swift         # Connection profile model
│   │   ├── AuthMethod.swift            # Enum: password, key
│   │   └── SessionState.swift          # Terminal session state
│   │
│   ├── Services/
│   │   ├── SSHService.swift            # SwiftNIO SSH wrapper
│   │   ├── KeychainService.swift       # Keychain CRUD operations
│   │   └── ProfileStorage.swift        # Profile persistence
│   │
│   ├── Views/
│   │   ├── ServerList/
│   │   │   ├── ServerListView.swift    # Main list of saved servers
│   │   │   └── ServerRowView.swift     # Individual server row
│   │   │
│   │   ├── ServerEdit/
│   │   │   ├── ServerEditView.swift    # Add/edit server form
│   │   │   └── KeyImportView.swift     # SSH key import UI
│   │   │
│   │   ├── Terminal/
│   │   │   ├── TerminalContainerView.swift  # Wraps SwiftTerm
│   │   │   ├── TerminalView.swift      # UIViewRepresentable for SwiftTerm
│   │   │   ├── ExtraKeysBar.swift      # Ctrl, Esc, arrows toolbar
│   │   │   └── SessionTabBar.swift     # Multiple session tabs
│   │   │
│   │   └── Components/
│   │       ├── SecureFieldWithToggle.swift  # Password field
│   │       └── ConnectionStatusBadge.swift
│   │
│   ├── ViewModels/
│   │   ├── ServerListViewModel.swift
│   │   ├── ServerEditViewModel.swift
│   │   └── TerminalViewModel.swift     # Manages SSH + terminal binding
│   │
│   ├── Utilities/
│   │   ├── SSHKeyParser.swift          # Parse OpenSSH key formats
│   │   └── Constants.swift
│   │
│   └── Resources/
│       └── Assets.xcassets
│
├── iTerminalTests/
└── README.md
```

## Implementation Plan

### Phase 1: Project Setup & Basic UI
1. Create new Xcode project (SwiftUI, iOS 17+)
2. Add SPM dependencies
3. Build ServerListView with mock data
4. Build ServerEditView form
5. Implement ProfileStorage (UserDefaults initially)
6. Implement KeychainService for credentials

### Phase 2: SSH Connection
1. Create SSHService wrapper around SwiftNIO SSH
2. Implement password authentication flow
3. Implement SSH key authentication flow
4. Handle connection errors gracefully
5. Test basic command execution (non-interactive)

### Phase 3: Terminal Integration
1. Create UIViewRepresentable wrapper for SwiftTerm's TerminalView
2. Connect SSH channel I/O to SwiftTerm
3. Request PTY with appropriate terminal type (xterm-256color)
4. Handle window resize (send SIGWINCH / update PTY size)
5. Implement scrollback buffer

### Phase 4: Keyboard & Input
1. Build ExtraKeysBar with special keys
2. Handle Ctrl+key combinations
3. Support arrow keys, Tab, Escape
4. Test with interactive apps (vim, htop, Claude Code)

### Phase 5: Polish & Session Management
1. Add multiple session tabs
2. Implement reconnection logic
3. Add connection status indicators
4. Handle app backgrounding gracefully
5. Add haptic feedback for connections

## Key Implementation Details

### SSHService Core Interface

```swift
@Observable
class SSHService {
    var connectionState: ConnectionState = .disconnected
    
    func connect(to profile: ServerProfile, credential: Credential) async throws
    func disconnect()
    func send(_ data: Data)
    func resize(cols: Int, rows: Int)
    
    var onDataReceived: ((Data) -> Void)?
    var onDisconnected: ((Error?) -> Void)?
}

enum ConnectionState {
    case disconnected
    case connecting
    case authenticating
    case connected
    case failed(Error)
}
```

### SwiftTerm Integration

SwiftTerm provides `TerminalView` (UIKit) which needs UIViewRepresentable wrapper:

```swift
struct TerminalViewRepresentable: UIViewRepresentable {
    let terminalView: SwiftTerm.TerminalView
    
    func makeUIView(context: Context) -> SwiftTerm.TerminalView {
        terminalView.configureNativeColors()
        terminalView.font = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        return terminalView
    }
    
    func updateUIView(_ uiView: SwiftTerm.TerminalView, context: Context) {}
}
```

Connect SSH I/O to terminal:

```swift
// SSH -> Terminal (display output)
sshService.onDataReceived = { data in
    terminalView.feed(byteArray: ArraySlice(data))
}

// Terminal -> SSH (user input)
terminalView.terminalDelegate = self
// In delegate: func send(source: TerminalView, data: ArraySlice<UInt8>)
// Forward to sshService.send(Data(data))
```

### Extra Keys Bar

Essential keys for terminal use:

```
┌─────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┐
│ Esc │ Tab │Ctrl │ Alt │  ←  │  →  │  ↑  │  ↓  │
└─────┴─────┴─────┴─────┴─────┴─────┴─────┴─────┘
┌─────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┐
│  -  │  /  │  |  │  ~  │ Pg↑ │ Pg↓ │Home │ End │
└─────┴─────┴─────┴─────┴─────┴─────┴─────┴─────┘
```

Ctrl key works as modifier — tap Ctrl, then tap 'c' sends Ctrl+C (0x03).

### PTY Request Parameters

```swift
let ptyRequest = SSHChannelType.Session.PseudoTerminalRequest(
    wantReply: true,
    term: "xterm-256color",
    terminalCharacterWidth: 80,
    terminalRowHeight: 24,
    terminalPixelWidth: 0,
    terminalPixelHeight: 0,
    terminalModes: [:]  // Use defaults
)
```

## Testing Checklist

- [ ] Password auth connects successfully
- [ ] SSH key auth (Ed25519) works
- [ ] SSH key auth (RSA) works
- [ ] Terminal displays colors correctly
- [ ] Cursor movement works (test with vim)
- [ ] Ctrl+C interrupts running command
- [ ] Arrow keys work for command history
- [ ] Tab completion works
- [ ] Window resize updates remote PTY
- [ ] Copy/paste works
- [ ] Claude Code TUI renders correctly
- [ ] git push/pull with interactive prompts work
- [ ] Session survives brief app background
- [ ] Reconnect works after disconnect

## Stretch Goals (Post-MVP)

- SSH key generation in-app
- SFTP file browser
- Port forwarding
- Snippets / saved commands
- Touch ID / Face ID to unlock saved credentials
- iCloud sync for profiles (not credentials)
- macOS Catalyst support
- Keyboard shortcuts for hardware keyboards
- Custom color themes

## Notes

- SwiftNIO SSH is lower-level than libssh2 wrappers but more maintainable
- SwiftTerm handles most terminal complexity — don't reinvent it
- iOS aggressively kills background connections; warn users
- Test with actual Claude Code early — it's the target use case

## Commands to Get Started

```bash
# Create project directory
mkdir iTerminal && cd iTerminal

# Initialize Xcode project via command line or Xcode
# Then add packages via File > Add Package Dependencies:
# - https://github.com/migueldeicaza/SwiftTerm.git
# - https://github.com/apple/swift-nio-ssh.git
# - https://github.com/kishikawakatsumi/KeychainAccess.git
```

---

This spec is ready to feed to Claude Code. Start with Phase 1 and iterate.

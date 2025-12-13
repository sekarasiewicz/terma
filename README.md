# Terma

A native iOS SSH client built with SwiftUI for running interactive terminal sessions on remote servers.

![iOS 17.0+](https://img.shields.io/badge/iOS-17.0+-blue.svg)
![Swift 5.9+](https://img.shields.io/badge/Swift-5.9+-orange.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)

## Features

- **Full Terminal Emulation** - Powered by SwiftTerm with 256-color support, cursor movement, and scrollback
- **SSH Authentication** - Password and SSH key (Ed25519, RSA) authentication
- **Secure Credential Storage** - All secrets stored in iOS Keychain
- **Extra Keys Bar** - Quick access to Esc, Tab, Ctrl, Alt, arrow keys, and more
- **Server Profiles** - Save and manage multiple server connections
- **Connection Status** - Real-time connection state indicators

## Screenshots

*Coming soon*

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/terma.git
cd terma
```

2. Open in Xcode:
```bash
open terma.xcodeproj
```

3. Build and run on your device or simulator

## Dependencies

Terma uses Swift Package Manager for dependencies:

- [SwiftTerm](https://github.com/migueldeicaza/SwiftTerm) - Terminal emulation
- [swift-nio-ssh](https://github.com/apple/swift-nio-ssh) - SSH protocol implementation
- [KeychainAccess](https://github.com/kishikawakatsumi/KeychainAccess) - Keychain wrapper

## Usage

1. **Add a Server** - Tap the + button to add a new server profile
2. **Configure Connection** - Enter host, port, username, and authentication method
3. **Connect** - Tap the terminal icon to start an SSH session
4. **Use Extra Keys** - Access special keys via the toolbar at the bottom

### Extra Keys

| Key | Function |
|-----|----------|
| Esc | Send escape character |
| Tab | Tab completion |
| Ctrl | Modifier for control sequences (Ctrl+C, etc.) |
| Alt | Modifier for alt sequences |
| Arrows | Navigation and command history |
| PgUp/PgDn | Scroll through output |
| Home/End | Jump to start/end of line |

## Architecture

```
terma/
├── Models/
│   ├── AuthMethod.swift
│   ├── ServerProfile.swift
│   └── SessionState.swift
├── Services/
│   ├── SSHService.swift
│   ├── KeychainService.swift
│   └── ProfileStorage.swift
├── ViewModels/
│   ├── ServerListViewModel.swift
│   ├── ServerEditViewModel.swift
│   └── TerminalViewModel.swift
├── Views/
│   ├── ServerList/
│   ├── ServerEdit/
│   ├── Terminal/
│   └── Components/
└── Utilities/
```

## Building

```bash
# Build for simulator
xcodebuild -project terma.xcodeproj -scheme terma -destination 'platform=iOS Simulator,name=Phone' build

# Run tests
xcodebuild -project terma.xcodeproj -scheme terma -destination 'platform=iOS Simulator,name=Phone' test
```

## Roadmap

- [ ] SSH key generation in-app
- [ ] SFTP file browser
- [ ] Port forwarding
- [ ] Touch ID / Face ID authentication
- [ ] iCloud sync for profiles
- [ ] Custom color themes
- [ ] macOS Catalyst support

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License - see [LICENSE](LICENSE) for details

## Acknowledgments

- [SwiftTerm](https://github.com/migueldeicaza/SwiftTerm) by Miguel de Icaza
- [swift-nio-ssh](https://github.com/apple/swift-nio-ssh) by Apple

# Terma Roadmap

## Current State

- ~2,650 lines of clean Swift code
- MVVM architecture with proper separation
- Swift 6 compatible

## Completed

- [x] Host key verification - Store and verify server fingerprints (SHA256)
- [x] Font size adjustment - Pinch to zoom gesture and menu controls (8-32pt)
- [x] Auto-reconnect - Retry connection up to 3 times on unexpected disconnect
- [x] Quick connect - Connect without saving profile (bolt icon in toolbar)
- [x] Search in scrollback - Find text in terminal history with navigation

## Phase 1: Polish

- [ ] Color themes - Dark/light themes, custom terminal colors (ANSI 16)
- [ ] Haptic feedback - Subtle feedback on extra key taps
- [ ] Biometric unlock - Face ID/Touch ID to protect credentials
- [ ] URL detection - Tap to open links in terminal output

## Phase 2: iPad

- [ ] Hardware keyboard shortcuts - Cmd+T new tab, Cmd+W close, Cmd+1-9 switch
- [ ] Split view - Multiple terminals side by side
- [ ] Pointer support - Better cursor/trackpad integration

## Phase 3: Advanced

- [ ] Port forwarding - Local/remote SSH tunnels
- [ ] SFTP browser - Browse and transfer files
- [ ] SSH agent forwarding
- [ ] Background notifications - Alert when long command finishes

## Phase 4: Sync & Backup

- [ ] iCloud sync - Share profiles across devices (CloudKit)
- [ ] Export/import profiles - JSON backup
- [ ] SSH key generation - Create keys in-app
- [ ] Snippets - Saved commands with one-tap execution

## Implementation Notes

### Color Themes
- Store theme preference in UserDefaults
- Define color sets: background, foreground, ANSI colors (16), cursor
- Update SwiftTerm's `TerminalView` colors dynamically

### Biometric Unlock
- Use LocalAuthentication framework
- Gate credential retrieval from Keychain
- Fallback to device passcode

### iPad Keyboard Shortcuts
- Use `.keyboardShortcut()` modifier in SwiftUI
- Handle in `TerminalContainerView` for session management

### iCloud Sync
- Use CloudKit with NSPersistentCloudKitContainer
- Handle conflict resolution (last-write-wins)

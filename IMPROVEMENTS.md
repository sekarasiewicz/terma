# Terma Improvement Plan

Portfolio-focused improvements to make Terma stand out.

## Current State

- ~2,650 lines of clean Swift code
- MVVM architecture with proper separation of concerns
- Swift 6 compatible
- Core features complete: SSH terminal, key auth, host verification, auto-reconnect, search

## Tier 1: High Visibility, Moderate Effort

These improvements show technical range and polish:

| Feature | Description | Why it matters |
|---------|-------------|----------------|
| Color themes | Dark/light themes, custom terminal colors | Shows UI/UX sensibility, SwiftUI skills |
| Biometric unlock | Face ID/Touch ID to protect saved credentials | Security feature, LocalAuthentication framework |
| iPad keyboard shortcuts | Cmd+T (new tab), Cmd+W (close), Cmd+1-9 (switch tabs) | Platform expertise, professional polish |
| Haptic feedback | Subtle feedback on key presses and actions | Attention to detail |

## Tier 2: Technical Depth

These demonstrate deeper engineering skills:

| Feature | Description | Why it matters |
|---------|-------------|----------------|
| Port forwarding | Local/remote SSH tunnels | Deeper SSH/networking knowledge |
| iCloud sync | Sync server profiles across devices | CloudKit experience, async data handling |
| SFTP browser | Browse and transfer files | Significant feature, file system UI |

## Tier 3: Nice-to-Have

Polish features for completeness:

- URL detection in terminal output (tap to open)
- Snippets/macros (saved commands)
- Export/import profiles (JSON backup)
- SSH key generation in-app

## Implementation Priority

### Phase 1: Polish
1. Color themes (custom terminal colors + app appearance)
2. Haptic feedback
3. Biometric unlock

### Phase 2: iPad
4. Hardware keyboard shortcuts
5. Split view support

### Phase 3: Advanced
6. iCloud sync
7. Port forwarding OR SFTP (pick one)

## Technical Notes

### Color Themes
- Store theme preference in UserDefaults
- Define color sets for: background, foreground, ANSI colors (16), cursor
- Update SwiftTerm's `TerminalView` colors dynamically

### Biometric Unlock
- Use LocalAuthentication framework
- Gate access to credential retrieval from Keychain
- Fallback to device passcode

### iPad Keyboard Shortcuts
- Use `.keyboardShortcut()` modifier in SwiftUI
- Handle in `TerminalContainerView` for session management
- Document shortcuts in app (help sheet)

### iCloud Sync
- Use CloudKit with NSPersistentCloudKitContainer
- Or manual CKRecord sync for more control
- Handle conflict resolution (last-write-wins or merge)

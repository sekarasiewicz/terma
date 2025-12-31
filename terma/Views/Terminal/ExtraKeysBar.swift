import SwiftUI

struct ExtraKeysBar: View {
    let viewModel: TerminalViewModel
    @Binding var ctrlActive: Bool
    @Binding var altActive: Bool

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                ExtraKeyButton(label: "Esc") {
                    viewModel.sendEscape()
                }

                ExtraKeyButton(label: "Tab") {
                    viewModel.sendTab()
                }

                ExtraKeyButton(
                    label: "Ctrl",
                    isActive: ctrlActive
                ) {
                    ctrlActive.toggle()
                    if ctrlActive {
                        altActive = false
                    }
                }

                ExtraKeyButton(
                    label: "Alt",
                    isActive: altActive
                ) {
                    altActive.toggle()
                    if altActive {
                        ctrlActive = false
                    }
                }

                ExtraKeyButton(systemImage: "arrow.left") {
                    viewModel.sendArrowLeft()
                }

                ExtraKeyButton(systemImage: "arrow.right") {
                    viewModel.sendArrowRight()
                }

                ExtraKeyButton(systemImage: "arrow.up") {
                    viewModel.sendArrowUp()
                }

                ExtraKeyButton(systemImage: "arrow.down") {
                    viewModel.sendArrowDown()
                }
            }

            HStack(spacing: 4) {
                ExtraKeyButton(label: "-") {
                    sendCharacter("-")
                }

                ExtraKeyButton(label: "/") {
                    sendCharacter("/")
                }

                ExtraKeyButton(label: "|") {
                    sendCharacter("|")
                }

                ExtraKeyButton(label: "~") {
                    sendCharacter("~")
                }

                ExtraKeyButton(label: "PgUp") {
                    viewModel.sendPageUp()
                }

                ExtraKeyButton(label: "PgDn") {
                    viewModel.sendPageDown()
                }

                ExtraKeyButton(label: "Home") {
                    viewModel.sendHome()
                }

                ExtraKeyButton(label: "End") {
                    viewModel.sendEnd()
                }
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 8)
        .background(.bar)
    }

    private func sendCharacter(_ char: String) {
        if ctrlActive, let firstChar = char.uppercased().first {
            viewModel.sendControlCharacter(firstChar)
            ctrlActive = false
        } else if altActive {
            viewModel.sendString("\u{1B}\(char)")
            altActive = false
        } else {
            viewModel.sendString(char)
        }
    }
}

struct ExtraKeyButton: View {
    let label: String?
    let systemImage: String?
    var isActive: Bool = false
    let action: () -> Void

    private let impactGenerator = UIImpactFeedbackGenerator(style: .light)

    init(label: String, isActive: Bool = false, action: @escaping () -> Void) {
        self.label = label
        self.systemImage = nil
        self.isActive = isActive
        self.action = action
    }

    init(systemImage: String, isActive: Bool = false, action: @escaping () -> Void) {
        self.label = nil
        self.systemImage = systemImage
        self.isActive = isActive
        self.action = action
    }

    var body: some View {
        Button {
            impactGenerator.impactOccurred()
            action()
        } label: {
            Group {
                if let systemImage = systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 14, weight: .medium))
                } else if let label = label {
                    Text(label)
                        .font(.system(size: 12, weight: .medium))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 36)
            .background(isActive ? Color.accentColor : Color(.systemGray5))
            .foregroundStyle(isActive ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }
}

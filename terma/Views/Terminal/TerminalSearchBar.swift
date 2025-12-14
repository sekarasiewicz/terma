import SwiftUI
import SwiftTerm

struct TerminalSearchBar: View {
    @Binding var searchText: String
    @Binding var isSearching: Bool
    var currentMatch: Int
    var totalMatches: Int
    var onSearch: () -> Void
    var onNext: () -> Void
    var onPrevious: () -> Void
    var onDismiss: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 8) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("Search", text: $searchText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($isFocused)
                    .onSubmit {
                        onSearch()
                    }
                    .onChange(of: searchText) { _, _ in
                        onSearch()
                    }

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            if totalMatches > 0 {
                Text("\(currentMatch)/\(totalMatches)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            Button {
                onPrevious()
            } label: {
                Image(systemName: "chevron.up")
            }
            .disabled(totalMatches == 0)

            Button {
                onNext()
            } label: {
                Image(systemName: "chevron.down")
            }
            .disabled(totalMatches == 0)

            Button("Done") {
                onDismiss()
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.bar)
        .onAppear {
            isFocused = true
        }
    }
}

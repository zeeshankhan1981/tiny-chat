import SwiftUI
import PhotosUI

public struct MessageInputViewHeightKey: PreferenceKey {
    public static let defaultValue: CGFloat = 0  // ✅ FIXED

    public static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - View Modifiers

extension View {
    func messageInputViewHeight(_ value: CGFloat) -> some View {
        self.preference(key: MessageInputViewHeightKey.self, value: value)
    }

    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - LLMTextInput View

public struct LLMTextInput: View {
    private let messagePlaceholder: String
    private let onSend: (() -> Void)?  // ✅ Optional callback for haptics or logging

    @EnvironmentObject var aiChatModel: AIChatModel
    @State private var input_text = ""
    @State private var isRecording = false
    @State private var isProcessing = false

    public var body: some View {
        VStack {
            HStack {
                TextField(messagePlaceholder, text: $input_text)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                    .background(Color.clear)
                    .frame(minHeight: 44)

                Button(action: {
                    sendMessage()
                }) {
                    Image(systemName: "paperplane.fill")
                        .padding(8)
                }
                .disabled(input_text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.vertical, 8)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .padding(.horizontal)

            if isProcessing {
                ProgressView()
            }
        }
        .background(Color.clear)
    }

    // MARK: - Send Action

    @MainActor
    private func sendMessage() {
        guard !input_text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        Task {
            isProcessing = true
            await aiChatModel.send(message: input_text)
            input_text = ""
            isProcessing = false
            onSend?() // ✅ Trigger haptics or callback
        }
    }

    // MARK: - Initializer

    public init(messagePlaceholder: String? = nil, onSend: (() -> Void)? = nil) {
        self.messagePlaceholder = messagePlaceholder ?? "Message"
        self.onSend = onSend
    }
}

#Preview {
    LLMTextInput()
        .environmentObject(AIChatModel())
}

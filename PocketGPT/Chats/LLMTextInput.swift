//
//  LLMTextInput.swift
//  PocketGPT
//
//

import SwiftUI
import PhotosUI

public struct MessageInputViewHeightKey: PreferenceKey {
    /// Default height of 0.
    ///
    public static var defaultValue: CGFloat = 0
    

    
    /// Writes the received value to the `PreferenceKey`.
    public static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}


/// View modifier to write the height of a `View` to the ``MessageInputViewHeightKey`` SwiftUI `PreferenceKey`.
extension View {
    func messageInputViewHeight(_ value: CGFloat) -> some View {
        self.preference(key: MessageInputViewHeightKey.self, value: value)
    }
}

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

public struct LLMTextInput: View {

    private let messagePlaceholder: String
    @EnvironmentObject var aiChatModel: AIChatModel
    @State public var input_text = ""
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
                    if !input_text.isEmpty {
                        Task { @MainActor in
                            isProcessing = true
                            await aiChatModel.send(message: input_text)
                            input_text = ""
                            isProcessing = false
                        }
                    }
                }) {
                    Image(systemName: "paperplane.fill")
                        .padding(8)
                }
            }
            .padding(.vertical, 8)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .padding()
            
            if isProcessing {
                ProgressView()
            }
        }
        .background(Color.clear)
    }
    
    /// - Parameters:
    ///   - chat: The chat that should be appended to.
    ///   - messagePlaceholder: Placeholder text that should be added in the input field
    public init(
//        _ chat: Binding<Chat>,
        messagePlaceholder: String? = nil
    ) {
//        self._chat = chat
        self.messagePlaceholder = messagePlaceholder ?? "Message"
    }
}

#Preview {
    LLMTextInput()
}

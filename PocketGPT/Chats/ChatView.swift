import SwiftUI
import UIKit

struct ChatView: View {
    @EnvironmentObject var aiChatModel: AIChatModel
    @Binding var chat_title: String?

    @State private var scrollProxy: ScrollViewProxy? = nil
    @State private var clearChatAlert = false
    @FocusState private var isInputFieldFocused: Bool
    @Namespace var bottomID

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(spacing: 12) {
                        ForEach(aiChatModel.messages, id: \.id) { message in
                            ChatBubbleView(message: message)
                        }
                        Color.clear.frame(height: 1).id("latest")
                    }
                    .padding(.vertical, 12)
                }
                .onAppear {
                    scrollProxy = proxy
                    scrollToBottom(animated: false)
                }
                .onChange(of: aiChatModel.messages) { _ in
                    scrollToBottom(animated: true)
                }
                .onChange(of: isInputFieldFocused) { focused in
                    if focused {
                        scrollToBottom(animated: true)
                    }
                }
                .onChange(of: chat_title) { _ in
                    // Swift 6-safe reloading
                    Task {
                        await reload()
                    }
                }
            }

            Divider()

            // Removed `onSend:` which is not a valid parameter
            LLMTextInput(messagePlaceholder: placeholderFor(chat_title))
                .environmentObject(aiChatModel)
                .focused($isInputFieldFocused)
                .padding()
                .background(.ultraThinMaterial)
        }
        .navigationTitle(chat_title ?? "Chat")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(role: .destructive) {
                    clearChatAlert = true
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
        .alert("Conversation history will be deleted", isPresented: $clearChatAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                aiChatModel.messages = []
                FileHelper.clear_chat_history(aiChatModel.chat_name)
            }
        } message: {
            Text("This will clear the current conversation.")
        }
    }

    // MARK: - Helper Functions

    func placeholderFor(_ title: String?) -> String {
        switch title {
        case "Image Creation":
            return "Describe the image"
        default:
            return "Message"
        }
    }

    func scrollToBottom(animated: Bool = true) {
        DispatchQueue.main.async {
            withAnimation(animated ? .easeOut(duration: 0.25) : nil) {
                scrollProxy?.scrollTo("latest", anchor: .bottom)
            }
        }
    }

    func reload() async {
        guard let chat_title else { return }
        aiChatModel.prepare(chat_title: chat_title)
    }

    func triggerHapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}

// MARK: - Chat Bubble Extracted

struct ChatBubbleView: View {
    let message: Message

    var body: some View {
        HStack {
            if message.sender == .user {
                Spacer()
                Text(message.text)
                    .padding()
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: .trailing)
            } else {
                Text(message.text)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: .leading)
                Spacer()
            }
        }
        .padding(.horizontal)
    }
}

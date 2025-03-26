//
//  ChatView.swift
//  PocketGPT
//

import SwiftUI

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
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(aiChatModel.messages, id: \.id) { message in
                            MessageView(message: message)
                                .id(message.id)
                                .padding(.horizontal)
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
                    Task {
                        await reload()
                    }
                }
            }

            Divider()

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

    private func placeholderFor(_ title: String?) -> String {
        switch title {
        case "Image Creation": return "Describe the image"
        default: return "Message"
        }
    }

    private func scrollToBottom(animated: Bool = true) {
        DispatchQueue.main.async {
            withAnimation(animated ? .easeOut(duration: 0.25) : nil) {
                scrollProxy?.scrollTo("latest", anchor: .bottom)
            }
        }
    }

    private func reload() async {
        guard let chat_title else { return }
        aiChatModel.prepare(chat_title: chat_title)
    }
}

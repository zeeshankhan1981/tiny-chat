//  ChatView.swift
//  PocketGPT

import SwiftUI

struct ChatView: View {
    @EnvironmentObject var aiChatModel: AIChatModel

    @State var placeholderString: String = "Message"
    enum FocusedField { case firstName, lastName }

    @Binding var chat_title: String?
    @State private var reload_button_icon: String = "arrow.counterclockwise.circle"
    @State private var scrollProxy: ScrollViewProxy? = nil
    @State private var scrollTarget: Int?
    @State private var toggleEditChat = false
    @State private var clearChatAlert = false

    @FocusState private var focusedField: FocusedField?
    @Namespace var bottomID
    @FocusState private var isInputFieldFocused: Bool

    func scrollToBottom(with_animation: Bool = false) {
        var scroll_bug = true
        #if os(macOS)
        scroll_bug = false
        #else
        if #available(iOS 16.4, *) {
            scroll_bug = false
        }
        #endif
        if scroll_bug { return }

        if aiChatModel.messages.last != nil, let scrollProxy = scrollProxy {
            if with_animation {
                withAnimation {
                    scrollProxy.scrollTo("latest")
                }
            } else {
                scrollProxy.scrollTo("latest")
            }
        }
    }

    func reload() {
        guard let chat_title else { return }
        print("\nreload\n")

        if chat_title == "Chat" {
            placeholderString = "Message"
        } else if chat_title == "Image Creation" {
            placeholderString = "Describe the image"
        }
        aiChatModel.prepare(chat_title: chat_title)
    }

    private func delayIconChange() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            reload_button_icon = "arrow.counterclockwise.circle"
        }
    }

    private var starOverlay: some View {
        Button {
            Task { scrollToBottom() }
        } label: {
            Image(systemName: "arrow.down.circle")
                .resizable()
                .foregroundColor(.white)
                .frame(width: 25, height: 25)
                .padding([.bottom, .trailing], 15)
                .opacity(0.4)
        }
        .buttonStyle(BorderlessButtonStyle())
    }

    var body: some View {
        VStack {
            ScrollViewReader { scrollView in
                VStack {
                    List {
                        ForEach(aiChatModel.messages, id: \ .id) { message in
                            MessageView(message: message).id(message.id)
                        }
                        .listRowSeparator(.hidden)
                        Text("").id("latest")
                    }
                    .listStyle(PlainListStyle())
                }
                .onChange(of: aiChatModel.AI_typing) { _ in
                    scrollToBottom(with_animation: false)
                }
                .onAppear {
                    scrollProxy = scrollView
                    scrollToBottom(with_animation: false)
                    focusedField = .firstName
                }
            }
            .frame(maxHeight: .infinity)
            .onChange(of: chat_title) { _ in
                Task { self.reload() }
            }
            .toolbar {
                Button {
                    clearChatAlert = true
                } label: {
                    Image(systemName: "trash")
                }
                .alert("Conversation history will be deleted", isPresented: $clearChatAlert) {
                    Button("Cancel", role: .cancel, action: {})
                    Button("Proceed", role: .destructive) {
                        aiChatModel.messages = []
                        FileHelper.clear_chat_history(aiChatModel.chat_name)
                    }
                } message: {
                    Text("The message history will be cleared")
                }
            }

            LLMTextInput(messagePlaceholder: placeholderString)
                .environmentObject(aiChatModel)
                .focused($focusedField, equals: .firstName)
        }
        .onChange(of: aiChatModel.messages) { _ in
            scrollToBottom()
        }
        .onChange(of: isInputFieldFocused) { focused in
            if focused {
                scrollToBottom(with_animation: true)
            }
        }
    }
}

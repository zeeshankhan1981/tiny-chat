//
//  AIChatModel.swift
//  PocketGPT
//

import Foundation
import SwiftUI
import os
import CoreML

@MainActor
final class AIChatModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var AI_typing = 0

    public var llamaState = LlamaState()
    public var chat_name = "Chat"

    public var numberOfTokens = 0
    public var total_sec = 0.0
    public var start_predicting_time = DispatchTime.now()

    // Generation Parameters
    public var temperature: Float = 0.7
    public var top_k: Int32 = 40
    public var top_p: Float = 0.9

    init() {
        Task {
            try? await llamaState.loadModel()
        }
    }

    public func prepare(chat_title: String) {
        if chat_title != self.chat_name {
            self.chat_name = chat_title
            self.messages = []
            Task {
                self.messages = FileHelper.load_chat_history(self.chat_name) ?? []
                self.AI_typing = -Int.random(in: 0..<100000)
            }
        }
    }

    private func getConversationPromptLlama(messages: [Message]) -> String {
        let contextLength = 3
        let numChats = contextLength * 2 + 1
        var prompt = """
        You are TinyLlama, a concise, fact-based AI assistant. Be helpful, honest, and stay on topic.
        Avoid repeating the user's question. If you don't know the answer, say so. Use simple, clear language.

        Chat history:
        """

        let start = max(0, messages.count - numChats)
        for i in start..<messages.count-1 {
            let message = messages[i]
            switch message.sender {
            case .user:
                prompt += "user: \(message.text)\n"
            case .system:
                prompt += "assistant: \(message.text)\n"
            default:
                break
            }
        }

        if let last = messages.last, last.sender == .user {
            prompt += "user: \(last.text)\nassistant:"
        }

        return prompt
    }

    public func send(message in_text: String, image: Image? = nil) {
        guard !in_text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("Error: Empty message")
            return
        }

        let userMessage = Message(sender: .user, state: .typed, text: in_text, tok_sec: 0, image: image)
        self.messages.append(userMessage)
        self.AI_typing += 1
        self.numberOfTokens = 0
        self.total_sec = 0.0
        self.start_predicting_time = DispatchTime.now()

        Task { @MainActor in
            let prompt = self.getConversationPromptLlama(messages: self.messages)
            print("🧠 Sending prompt to model:\n\(prompt)")

            var aiMessage = Message(sender: .system, text: "", tok_sec: 0)
            self.messages.append(aiMessage)
            let messageIndex = self.messages.endIndex - 1

            do {
                try await llamaState.complete(
                    text: prompt,
                    temperature: temperature,
                    top_k: top_k,
                    top_p: top_p,
                    stop_if: { partial in
                        partial.contains("user:") || partial.contains("assistant:")
                    },
                    onToken: { str in
                        aiMessage.state = .predicting
                        aiMessage.text += str

                        var updated = self.messages
                        updated[messageIndex] = aiMessage
                        self.messages = updated

                        self.AI_typing += 1
                        self.numberOfTokens += 1
                    }
                )
            } catch {
                print("⚠️ Error during completion: \(error.localizedDescription)")
                return
            }

            self.total_sec = Double((DispatchTime.now().uptimeNanoseconds - self.start_predicting_time.uptimeNanoseconds)) / 1_000_000_000
            aiMessage.tok_sec = Double(self.numberOfTokens) / self.total_sec
            print("✅ Completion stats: tokens=\(self.numberOfTokens), time=\(self.total_sec)s, tokens/sec=\(aiMessage.tok_sec)")

            aiMessage.state = .predicted(totalSecond: 0)
            self.messages[messageIndex] = aiMessage
            llamaState.answer = ""
            self.AI_typing = 0

            self.save_chat_history([userMessage, aiMessage], self.chat_name)
        }
    }

    private func save_chat_history(_ messages: [Message], _ chat_name: String) {
        FileHelper.save_chat_history(chat_name, messages: messages)
    }

    public func stopPredicting() {
        llamaState.stopPredicting()
    }
}

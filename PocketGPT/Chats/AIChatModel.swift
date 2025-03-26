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

    init() {
        Task {
            try? await llamaState.loadModel()
        }
    }
    
    public func prepare(chat_title: String) {
        let new_chat_name = chat_title
        if new_chat_name != self.chat_name {
            self.chat_name = new_chat_name
            self.messages = []
            Task {
                self.messages = FileHelper.load_chat_history(self.chat_name) ?? []
                self.AI_typing = -Int.random(in: 0..<100000)
            }
        }
    }
    
    private func getConversationPromptLlama(messages: [Message]) -> String {
        let contextLength = 2
        let numChats = contextLength * 2 + 1
        var prompt = "The following is a friendly conversation between a human and an AI. You are a helpful chatbot that answers questions. Chat history:\n"
        let start = max(0, messages.count - numChats)
        for i in start..<messages.count-1 {
            let message = messages[i]
            if message.sender == .user {
                prompt += "user: " + message.text + "\n"
            } else if message.sender == .system {
                prompt += "assistant:" + message.text + "\n"
            }
        }
        prompt += "\nassistant:\n"
        let message = messages[messages.count-1]
        if message.sender == .user {
            prompt += "user: " + message.text + "\nassistant:\n"
        }
        return prompt
    }
    
    public func send(message in_text: String, image: Image? = nil) {
        guard !in_text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("Error: Empty message")
            return
        }

        let requestMessage = Message(sender: .user, state: .typed, text: in_text, tok_sec: 0, image: image)
        self.messages.append(requestMessage)
        self.AI_typing += 1
        self.numberOfTokens = 0
        self.total_sec = 0.0
        self.start_predicting_time = DispatchTime.now()
        
        Task { @MainActor in
            let prompt = self.getConversationPromptLlama(messages: self.messages)
            print("Sending prompt to model: \(prompt)")
            
            var message = Message(sender: .system, text: "", tok_sec: 0)
            self.messages.append(message)
            let messageIndex = self.messages.endIndex - 1
            
            do {
                try await llamaState.complete(
                    text: prompt,
                    { str in
                        message.state = .predicting
                        message.text += str
                        
                        var updatedMessages = self.messages
                        updatedMessages[messageIndex] = message
                        self.messages = updatedMessages
                        
                        self.AI_typing += 1
                        self.numberOfTokens += 1
                    }
                )
            } catch {
                print("Error in completion: \(error.localizedDescription)")
                return
            }
            
            self.total_sec = Double((DispatchTime.now().uptimeNanoseconds - self.start_predicting_time.uptimeNanoseconds)) / 1_000_000_000
            message.tok_sec = Double(self.numberOfTokens) / self.total_sec
            print("Completion stats: tokens=\(self.numberOfTokens), time=\(self.total_sec)s, tokens/sec=\(message.tok_sec)")
            
            message.state = .predicted(totalSecond: 0)
            self.messages[messageIndex] = message
            llamaState.answer = ""
            self.AI_typing = 0
            
            self.save_chat_history([requestMessage, message], self.chat_name)
        }
    }

    private func save_chat_history(_ messages: [Message], _ chat_name: String) {
        FileHelper.save_chat_history(chat_name, messages: messages)
    }
    
    public func stopPredicting() {
        llamaState.stopPredicting()
    }
}

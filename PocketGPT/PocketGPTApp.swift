//
//  PocketGPTApp.swift
//  PocketGPT
//

import SwiftUI
import StoreKit

let udkey_activeCount = "activeCount"

@main
struct PocketGPTApp: App {
    @StateObject var aiChatModel = AIChatModel()
    @StateObject var llamaState: LlamaState

    init() {
        let aiChatModel = AIChatModel()
        self._aiChatModel = StateObject(wrappedValue: aiChatModel)
        self._llamaState = StateObject(wrappedValue: aiChatModel.llamaState)
    }

    @Environment(\.scenePhase) var scenePhase

    var body: some Scene {
        WindowGroup {
            ChatView(chat_title: .constant("Chat"))
                .environmentObject(aiChatModel)
                .onAppear {
                    Task { @MainActor in
                        do {
                            try await llamaState.loadModel()
                            print("✅ Model initialized successfully")
                        } catch LlamaModelError.modelNotLoaded {
                            print("❌ Error: Model not loaded. Please try again.")
                        } catch LlamaModelError.modelCorrupted {
                            print("❌ Error: Model corrupted. Please reinstall the app.")
                        } catch {
                            print("❌ Error initializing model: \(error.localizedDescription)")
                        }
                    }
                }
                .onChange(of: scenePhase) { oldPhase, newPhase in
                    if newPhase == .active {
                        var activeCount = UserDefaults.standard.integer(forKey: udkey_activeCount)
                        activeCount += 1
                        UserDefaults.standard.set(activeCount, forKey: udkey_activeCount)
                        print("activeCount: \(activeCount)")
                        if activeCount == 15 {
                            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                                SKStoreReviewController.requestReview(in: windowScene)
                            }
                        }
                    }
                }
        }
    }
}

enum LlamaModelError: Error {
    case modelNotLoaded
    case modelCorrupted
}

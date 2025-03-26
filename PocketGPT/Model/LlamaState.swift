//
//  LlamaState.swift
//  PocketGPT
//

import Foundation
import QuartzCore

@MainActor
class LlamaState: ObservableObject {
    @Published var messageLog = ""
    @Published var answer = ""
    @Published var cacheCleared = false
    @Published var interrupt: Bool = false
    let NS_PER_S = 1_000_000_000.0

    private var llamaContext: LlamaContext?
    
    // Updated to use your Resources folder path
    private var defaultModelUrl: URL? {
        Bundle.main.url(forResource: "tinyllama-1.1b-chat-v1.0-q2_k", withExtension: "gguf")
    }

    init() {
        Task {
            await loadModel()
        }
    }

    func loadModel() async {
        print("🧪 Available .gguf files in bundle:")
        let paths = Bundle.main.paths(forResourcesOfType: "gguf", inDirectory: nil)
        for path in paths {
            print("→ \(path)")
        }

        guard let modelUrl = defaultModelUrl else {
            print("❌ Error: Model URL not found")
            return
        }

        print("✅ Model initialized from path: \(modelUrl.path)")

        if let llamaContext = llamaContext {
            await llamaContext.clear()
        }

        do {
            llamaContext = try LlamaContext.create_context(path: modelUrl.path())
            print("✅ Model loaded successfully")
        } catch {
            print("❌ Error loading model: \(error.localizedDescription)")
        }
    }


    enum LlamaModelError: Error {
        case modelNotLoaded
        case modelCorrupted
    }

    func complete(text: String, _ tokenCallback: ((String) -> ())?) async throws {
        guard let llamaContext else {
            print("❌ Error: LlamaContext is nil")
            throw LlamaModelError.modelNotLoaded
        }

        print("🧠 Starting completion with prompt:\n\(text)")

        try await llamaContext.completion_init(text: text)

        var generatedTokens = 0
        let startTime = CACurrentMediaTime()

        while true {
            if interrupt {
                print("⚠️ Completion interrupted by user")
                break
            }

            let result = await llamaContext.completion_loop()
            print("🔹 Token: \(result)")

            if result.isEmpty || result == "</s>" {
                print("✅ Completion ended with result: \(result)")
                break
            }

            generatedTokens += 1
            DispatchQueue.main.async {
                tokenCallback?(result)
            }
        }

        let endTime = CACurrentMediaTime()
        let totalTime = endTime - startTime
        let tokensPerSecond = totalTime > 0 ? Double(generatedTokens) / totalTime : 0
        print("📊 Completion stats → tokens: \(generatedTokens), time: \(totalTime)s, speed: \(tokensPerSecond) tokens/sec")

        try await llamaContext.clear()
    }

    func stopPredicting() {
        interrupt = true
    }
}

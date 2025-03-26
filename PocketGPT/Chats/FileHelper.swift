import Foundation
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Convert SwiftUI View to UIImage
extension View {
    public func asUIImage() -> UIImage {
        let controller = UIHostingController(rootView: self)
        controller.view.backgroundColor = .clear
        controller.view.frame = CGRect(x: 0, y: CGFloat(Int.max), width: 1, height: 1)

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.view.addSubview(controller.view)
        }

        let size = controller.sizeThatFits(in: UIScreen.main.bounds.size)
        controller.view.bounds = CGRect(origin: .zero, size: size)
        controller.view.sizeToFit()

        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
}

// MARK: - Chat File Helper
struct FileHelper {
    static func load_chat_history(_ name: String) -> [Message]? {
        let fileURL = getDocumentsDirectory().appendingPathComponent("\(name).json")
        do {
            let data = try Data(contentsOf: fileURL)
            let messages = try JSONDecoder().decode([Message].self, from: data)
            return messages
        } catch {
            print("❌ Error loading chat history: \(error)")
            return nil
        }
    }

    static func save_chat_history(_ name: String, messages: [Message]) {
        let fileURL = getDocumentsDirectory().appendingPathComponent("\(name).json")
        do {
            let data = try JSONEncoder().encode(messages)
            try data.write(to: fileURL)
        } catch {
            print("❌ Error saving chat history: \(error)")
        }
    }

    static func delete_chats(_ previews: [Dictionary<String, String>]) -> Bool {
        for preview in previews {
            if let name = preview["title"] {
                let fileURL = getDocumentsDirectory().appendingPathComponent("\(name).json")
                if FileManager.default.fileExists(atPath: fileURL.path) {
                    try? FileManager.default.removeItem(at: fileURL)
                }
            }
        }
        return true
    }

    static func duplicate_chat(_ preview: Dictionary<String, String>) -> Bool {
        guard let name = preview["title"] else { return false }
        let src = getDocumentsDirectory().appendingPathComponent("\(name).json")
        let dst = getDocumentsDirectory().appendingPathComponent("\(name)-copy.json")
        if FileManager.default.fileExists(atPath: src.path) {
            try? FileManager.default.copyItem(at: src, to: dst)
            return true
        }
        return false
    }

    static func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    static func clear_chat_history(_ name: String) {
        let fileURL = getDocumentsDirectory().appendingPathComponent("\(name).json")
        let emptyMessages: [Message] = []
        do {
            let data = try JSONEncoder().encode(emptyMessages)
            try data.write(to: fileURL)
            print("✅ Chat history cleared for '\(name)'")
        } catch {
            print("❌ Failed to clear chat history: \(error)")
        }
    }
}

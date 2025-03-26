import SwiftUI

struct Message: Identifiable, Codable, Equatable {
    enum State: Codable, Equatable {
        case none
        case error
        case typed
        case predicting
        case predicted(totalSecond: Double)

        enum CodingKeys: String, CodingKey {
            case type, totalSecond
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let type = try container.decode(String.self, forKey: .type)

            switch type {
            case "none": self = .none
            case "error": self = .error
            case "typed": self = .typed
            case "predicting": self = .predicting
            case "predicted":
                let seconds = try container.decode(Double.self, forKey: .totalSecond)
                self = .predicted(totalSecond: seconds)
            default:
                self = .none
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case .none:
                try container.encode("none", forKey: .type)
            case .error:
                try container.encode("error", forKey: .type)
            case .typed:
                try container.encode("typed", forKey: .type)
            case .predicting:
                try container.encode("predicting", forKey: .type)
            case .predicted(let sec):
                try container.encode("predicted", forKey: .type)
                try container.encode(sec, forKey: .totalSecond)
            }
        }
    }

    enum Sender: String, Codable {
        case user
        case system
    }

    var id = UUID()
    var sender: Sender
    var state: State = .none
    var text: String
    var tok_sec: Double
    var header: String = ""

    // Not Codable, so we'll ignore it during encoding/decoding
    var image: Image? = nil

    private enum CodingKeys: String, CodingKey {
        case id, sender, state, text, tok_sec, header
    }

    init(sender: Sender, state: State = .none, text: String, tok_sec: Double, header: String = "", image: Image? = nil) {
        self.sender = sender
        self.state = state
        self.text = text
        self.tok_sec = tok_sec
        self.header = header
        self.image = image
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        sender = try container.decode(Sender.self, forKey: .sender)
        state = try container.decode(State.self, forKey: .state)
        text = try container.decode(String.self, forKey: .text)
        tok_sec = try container.decode(Double.self, forKey: .tok_sec)
        header = try container.decode(String.self, forKey: .header)
        image = nil
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(sender, forKey: .sender)
        try container.encode(state, forKey: .state)
        try container.encode(text, forKey: .text)
        try container.encode(tok_sec, forKey: .tok_sec)
        try container.encode(header, forKey: .header)
        // image is intentionally not encoded
    }

    static func == (lhs: Message, rhs: Message) -> Bool {
        lhs.id == rhs.id &&
        lhs.sender == rhs.sender &&
        lhs.state == rhs.state &&
        lhs.text == rhs.text &&
        lhs.tok_sec == rhs.tok_sec &&
        lhs.header == rhs.header
        // image is ignored from comparison since it's not codable or equatable
    }
}

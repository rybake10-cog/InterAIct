import Foundation

/// A companion character that guides the child through each scenario.
struct Avatar: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let emoji: String
    let colorHex: String

    var shortName: String { name.components(separatedBy: " ").first ?? name }

    static let all: [Avatar] = [
        Avatar(id: "cat", name: "Whiskers the Cat", emoji: "🐱", colorHex: "#FF9FF3"),
        Avatar(id: "dog", name: "Buddy the Dog", emoji: "🐶", colorHex: "#FECA57"),
        Avatar(id: "rabbit", name: "Hoppy the Rabbit", emoji: "🐰", colorHex: "#FF6B6B"),
        Avatar(id: "bear", name: "Berry the Bear", emoji: "🐻", colorHex: "#48DBFB"),
    ]

    static func with(id: String?) -> Avatar? {
        guard let id else { return nil }
        return all.first { $0.id == id }
    }
}

import Foundation

enum Feeling: String, Codable, CaseIterable, Identifiable, Hashable {
    case happy, calm, okay, worried, sad, angry, tired

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .happy: "😀"
        case .calm: "😌"
        case .okay: "🙂"
        case .worried: "😟"
        case .sad: "😢"
        case .angry: "😠"
        case .tired: "🥱"
        }
    }

    var label: String { rawValue.capitalized }

    /// Feelings where the app suggests visiting the Calm Corner.
    var suggestsCalmCorner: Bool {
        switch self {
        case .worried, .sad, .angry: true
        default: false
        }
    }
}

enum FeelingMoment: String, Codable, Hashable {
    case beforeScenario
    case afterScenario
    case calmCorner

    var label: String {
        switch self {
        case .beforeScenario: "Before practice"
        case .afterScenario: "After practice"
        case .calmCorner: "Calm Corner"
        }
    }
}

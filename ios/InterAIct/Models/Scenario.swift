import Foundation

/// How helpful a choice is. Feedback is always gentle; there is no "wrong" styling.
enum ChoiceKind: String, Codable, Hashable {
    case great
    case okay
    case tryAgain
}

struct Choice: Identifiable, Hashable, Codable {
    let id: String
    let text: String
    let icon: String
    let kind: ChoiceKind
    let feedback: String
    /// The phase to move to after this choice, or `nil` when the scenario is finished.
    let next: String?
}

struct Phase: Identifiable, Hashable, Codable {
    let id: String
    let title: String
    let prompt: String
    /// Emoji illustration shown when no video is available.
    let scene: String
    /// Optional bundled video resource name (without the `.mp4` extension).
    let video: String?
    let choices: [Choice]

    var isFinal: Bool { choices.allSatisfy { $0.next == nil } }
}

struct Scenario: Identifiable, Hashable, Codable {
    let id: String
    let title: String
    let summary: String
    let icon: String
    let color: String
    let skill: String
    let startPhaseID: String
    let phases: [Phase]

    func phase(id: String) -> Phase? {
        phases.first { $0.id == id }
    }

    func index(ofPhase id: String) -> Int? {
        phases.firstIndex { $0.id == id }
    }
}

struct ScenarioCatalog: Codable {
    let version: Int
    let scenarios: [Scenario]
}

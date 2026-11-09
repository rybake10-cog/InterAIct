import Foundation

struct ChoiceRecord: Codable, Hashable {
    let phaseID: String
    let choiceID: String
    let kind: ChoiceKind
    /// 1 for the first answer in a phase, 2 for the second, and so on.
    let attempt: Int
    let date: Date
}

struct PlayRecord: Codable, Identifiable, Hashable {
    let id: UUID
    let scenarioID: String
    let avatarID: String?
    let startedAt: Date
    var finishedAt: Date?
    var choices: [ChoiceRecord]

    var isCompleted: Bool { finishedAt != nil }

    /// Phases where the very first answer was a "great" choice.
    var greatOnFirstTry: Int {
        choices.filter { $0.attempt == 1 && $0.kind == .great }.count
    }

    var phasesAnswered: Int {
        Set(choices.map(\.phaseID)).count
    }
}

struct FeelingRecord: Codable, Identifiable, Hashable {
    let id: UUID
    let feeling: Feeling
    let moment: FeelingMoment
    let scenarioID: String?
    let date: Date
}

struct ProgressData: Codable, Equatable {
    var plays: [PlayRecord] = []
    var feelings: [FeelingRecord] = []
    var stars: Int = 0
}

struct ScenarioStats: Equatable {
    let plays: Int
    let completions: Int
    /// Fraction (0...1) of answered phases where the first answer was "great", or `nil` if none.
    let firstTryGreatRate: Double?
}

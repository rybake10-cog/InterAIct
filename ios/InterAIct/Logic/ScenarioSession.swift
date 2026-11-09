import Foundation
import Observation

/// Runtime state for one play-through of a scenario.
@Observable
final class ScenarioSession {
    let scenario: Scenario
    /// When true, the child keeps trying until they pick a "great" choice before moving on.
    let retryUntilGreat: Bool

    private(set) var currentPhaseID: String
    private(set) var selectedChoice: Choice?
    private(set) var triedChoiceIDs: Set<String> = []
    private(set) var records: [ChoiceRecord] = []
    private(set) var isFinished = false

    private var attemptsInPhase = 0
    private let now: () -> Date

    init(scenario: Scenario, retryUntilGreat: Bool, now: @escaping () -> Date = Date.init) {
        self.scenario = scenario
        self.retryUntilGreat = retryUntilGreat
        self.currentPhaseID = scenario.startPhaseID
        self.now = now
    }

    var currentPhase: Phase? { scenario.phase(id: currentPhaseID) }

    var phaseNumber: Int { (scenario.index(ofPhase: currentPhaseID) ?? 0) + 1 }

    var phaseCount: Int { scenario.phases.count }

    /// Whether the feedback for the selected choice lets the child move on.
    var canContinue: Bool {
        guard let selectedChoice else { return false }
        return selectedChoice.kind == .great || !retryUntilGreat
    }

    /// Whether the child may pick another choice in the current phase.
    var canTryAgain: Bool {
        guard let selectedChoice else { return false }
        return selectedChoice.kind != .great
    }

    func isTried(_ choice: Choice) -> Bool {
        triedChoiceIDs.contains(choice.id)
    }

    @discardableResult
    func choose(_ choice: Choice) -> ChoiceRecord? {
        guard !isFinished, selectedChoice == nil,
              currentPhase?.choices.contains(choice) == true else { return nil }
        attemptsInPhase += 1
        selectedChoice = choice
        let record = ChoiceRecord(
            phaseID: currentPhaseID,
            choiceID: choice.id,
            kind: choice.kind,
            attempt: attemptsInPhase,
            date: now()
        )
        records.append(record)
        return record
    }

    func tryAgain() {
        guard let selectedChoice, canTryAgain else { return }
        triedChoiceIDs.insert(selectedChoice.id)
        self.selectedChoice = nil
    }

    func advance() {
        guard let selectedChoice, canContinue else { return }
        self.selectedChoice = nil
        triedChoiceIDs = []
        attemptsInPhase = 0
        if let next = selectedChoice.next {
            currentPhaseID = next
        } else {
            isFinished = true
        }
    }
}

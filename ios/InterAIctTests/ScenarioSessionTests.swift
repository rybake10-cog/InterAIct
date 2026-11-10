import XCTest
@testable import InterAIct

final class ScenarioSessionTests: XCTestCase {
    private let scenario = Scenario(
        id: "test", title: "Test", summary: "", icon: "", color: "#000000", skill: "",
        startPhaseID: "first",
        phases: [
            Phase(id: "first", title: "", prompt: "", scene: "", video: nil, choices: [
                Choice(id: "a", text: "", icon: "", kind: .tryAgain, feedback: "", next: "last"),
                Choice(id: "b", text: "", icon: "", kind: .great, feedback: "", next: "last"),
                Choice(id: "c", text: "", icon: "", kind: .okay, feedback: "", next: "last"),
            ]),
            Phase(id: "last", title: "", prompt: "", scene: "", video: nil, choices: [
                Choice(id: "a", text: "", icon: "", kind: .great, feedback: "", next: nil),
            ]),
        ]
    )

    func testRetryUntilGreatRequiresHelpfulChoice() throws {
        let session = ScenarioSession(scenario: scenario, retryUntilGreat: true)
        let phase = try XCTUnwrap(session.currentPhase)

        session.choose(phase.choices[0])
        XCTAssertFalse(session.canContinue)
        XCTAssertTrue(session.canTryAgain)
        session.advance()
        XCTAssertEqual(session.currentPhaseID, "first")

        session.tryAgain()
        XCTAssertTrue(session.isTried(phase.choices[0]))
        XCTAssertNil(session.selectedChoice)

        session.choose(phase.choices[1])
        XCTAssertTrue(session.canContinue)
        session.advance()
        XCTAssertEqual(session.currentPhaseID, "last")
        XCTAssertTrue(session.triedChoiceIDs.isEmpty)
        XCTAssertEqual(session.records.map(\.attempt), [1, 2])
    }

    func testWithoutRetryAnyChoiceContinues() throws {
        let session = ScenarioSession(scenario: scenario, retryUntilGreat: false)
        session.choose(try XCTUnwrap(session.currentPhase).choices[2])
        XCTAssertTrue(session.canContinue)
        XCTAssertTrue(session.canTryAgain)
        session.advance()
        session.choose(try XCTUnwrap(session.currentPhase).choices[0])
        session.advance()
        XCTAssertTrue(session.isFinished)
        XCTAssertNil(session.choose(scenario.phases[1].choices[0]))
    }

    func testCannotChooseTwiceBeforeFeedbackIsDismissed() throws {
        let session = ScenarioSession(scenario: scenario, retryUntilGreat: true)
        let phase = try XCTUnwrap(session.currentPhase)
        XCTAssertNotNil(session.choose(phase.choices[1]))
        XCTAssertNil(session.choose(phase.choices[0]))
        XCTAssertEqual(session.records.count, 1)
    }
}

final class ProgressStoreTests: XCTestCase {
    func testProgressPersistsAndComputesStats() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: url) }

        let store = ProgressStore(fileURL: url)
        let playID = store.startPlay(scenarioID: "taking-turns", avatarID: "dog")
        store.record(ChoiceRecord(phaseID: "toys", choiceID: "a", kind: .tryAgain, attempt: 1, date: Date()), playID: playID)
        store.record(ChoiceRecord(phaseID: "toys", choiceID: "b", kind: .great, attempt: 2, date: Date()), playID: playID)
        store.record(ChoiceRecord(phaseID: "trading", choiceID: "b", kind: .great, attempt: 1, date: Date()), playID: playID)
        store.finishPlay(playID)
        store.finishPlay(playID)
        store.logFeeling(.calm, moment: .afterScenario, scenarioID: "taking-turns")

        let reloaded = ProgressStore(fileURL: url)
        XCTAssertEqual(reloaded.data, store.data)
        XCTAssertEqual(reloaded.stars, 1)
        XCTAssertEqual(reloaded.completedScenarioIDs, ["taking-turns"])
        XCTAssertEqual(reloaded.stats(for: "taking-turns"),
                       ScenarioStats(plays: 1, completions: 1, firstTryGreatRate: 0.5))

        reloaded.reset()
        XCTAssertEqual(ProgressStore(fileURL: url).data, ProgressData())
    }
}

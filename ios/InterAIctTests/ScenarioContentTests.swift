import XCTest
@testable import InterAIct

final class ScenarioContentTests: XCTestCase {
    func testBundledScenariosLoadAndValidate() throws {
        let library = try ScenarioLibrary.load()
        XCTAssertGreaterThanOrEqual(library.scenarios.count, 8)
        XCTAssertEqual(ScenarioLibrary.validate(library.scenarios), [])
    }

    func testTakingTurnsVideosAreBundled() throws {
        let library = try ScenarioLibrary.load()
        let takingTurns = try XCTUnwrap(library.scenario(id: "taking-turns"))
        for phase in takingTurns.phases {
            let video = try XCTUnwrap(phase.video, "\(phase.id) should have a video")
            XCTAssertNotNil(Bundle.main.url(forResource: video, withExtension: "mp4"), "Missing \(video).mp4")
        }
    }

    func testValidationCatchesBrokenContent() {
        let broken = Scenario(
            id: "broken", title: "Broken", summary: "", icon: "", color: "#000000", skill: "",
            startPhaseID: "missing",
            phases: [
                Phase(id: "one", title: "", prompt: "", scene: "", video: nil, choices: [
                    Choice(id: "a", text: "", icon: "", kind: .okay, feedback: "", next: "nowhere"),
                ]),
            ]
        )
        let problems = ScenarioLibrary.validate([broken])
        XCTAssertTrue(problems.contains { $0.contains("start phase missing") })
        XCTAssertTrue(problems.contains { $0.contains("needs at least one great choice") })
        XCTAssertTrue(problems.contains { $0.contains("next phase nowhere") })
    }
}

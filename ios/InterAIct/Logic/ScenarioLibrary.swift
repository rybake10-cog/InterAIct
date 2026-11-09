import Foundation

enum ScenarioLibraryError: Error, Equatable, CustomStringConvertible {
    case missingResource(String)
    case invalid([String])

    var description: String {
        switch self {
        case .missingResource(let name): "Missing resource \(name)"
        case .invalid(let problems): problems.joined(separator: "\n")
        }
    }
}

/// Loads the bundled social scenarios from `scenarios.json`.
struct ScenarioLibrary {
    let scenarios: [Scenario]

    init(scenarios: [Scenario]) {
        self.scenarios = scenarios
    }

    init(data: Data) throws {
        let catalog = try JSONDecoder().decode(ScenarioCatalog.self, from: data)
        let problems = ScenarioLibrary.validate(catalog.scenarios)
        guard problems.isEmpty else { throw ScenarioLibraryError.invalid(problems) }
        self.init(scenarios: catalog.scenarios)
    }

    static func load(from bundle: Bundle = .main, resource: String = "scenarios") throws -> ScenarioLibrary {
        guard let url = bundle.url(forResource: resource, withExtension: "json") else {
            throw ScenarioLibraryError.missingResource("\(resource).json")
        }
        return try ScenarioLibrary(data: Data(contentsOf: url))
    }

    func scenario(id: String) -> Scenario? {
        scenarios.first { $0.id == id }
    }

    /// Returns human-readable problems; an empty array means the content is playable.
    static func validate(_ scenarios: [Scenario]) -> [String] {
        var problems: [String] = []
        var scenarioIDs = Set<String>()

        for scenario in scenarios {
            let name = scenario.id
            if !scenarioIDs.insert(scenario.id).inserted {
                problems.append("Duplicate scenario id \(name)")
            }
            let phaseIDs = scenario.phases.map(\.id)
            if Set(phaseIDs).count != phaseIDs.count {
                problems.append("\(name): duplicate phase ids")
            }
            if scenario.phase(id: scenario.startPhaseID) == nil {
                problems.append("\(name): start phase \(scenario.startPhaseID) not found")
            }
            for phase in scenario.phases {
                if phase.choices.isEmpty {
                    problems.append("\(name)/\(phase.id): no choices")
                }
                if !phase.choices.contains(where: { $0.kind == .great }) {
                    problems.append("\(name)/\(phase.id): needs at least one great choice")
                }
                let choiceIDs = phase.choices.map(\.id)
                if Set(choiceIDs).count != choiceIDs.count {
                    problems.append("\(name)/\(phase.id): duplicate choice ids")
                }
                for choice in phase.choices {
                    if let next = choice.next, scenario.phase(id: next) == nil {
                        problems.append("\(name)/\(phase.id)/\(choice.id): next phase \(next) not found")
                    }
                }
            }

            var reachable = Set<String>()
            var queue = [scenario.startPhaseID]
            var reachesEnd = false
            while let id = queue.popLast() {
                guard reachable.insert(id).inserted, let phase = scenario.phase(id: id) else { continue }
                for choice in phase.choices {
                    if let next = choice.next { queue.append(next) } else { reachesEnd = true }
                }
            }
            if !reachesEnd {
                problems.append("\(name): no path to the end")
            }
            for id in phaseIDs where !reachable.contains(id) {
                problems.append("\(name)/\(id): unreachable phase")
            }
        }
        return problems
    }
}

import Foundation
import Observation

/// Saves the child's practice history on device as JSON. Nothing leaves the device.
@Observable
final class ProgressStore {
    private(set) var data: ProgressData
    private let fileURL: URL?

    init(fileURL: URL?) {
        self.fileURL = fileURL
        if let fileURL,
           let saved = try? Data(contentsOf: fileURL),
           let decoded = try? JSONDecoder().decode(ProgressData.self, from: saved) {
            data = decoded
        } else {
            data = ProgressData()
        }
    }

    static func defaultFileURL() -> URL? {
        let fm = FileManager.default
        guard let dir = try? fm.url(for: .applicationSupportDirectory, in: .userDomainMask,
                                    appropriateFor: nil, create: true) else { return nil }
        return dir.appendingPathComponent("progress.json")
    }

    var stars: Int { data.stars }

    var completedScenarioIDs: Set<String> {
        Set(data.plays.filter(\.isCompleted).map(\.scenarioID))
    }

    func startPlay(scenarioID: String, avatarID: String?, at date: Date = Date()) -> UUID {
        let play = PlayRecord(id: UUID(), scenarioID: scenarioID, avatarID: avatarID,
                              startedAt: date, finishedAt: nil, choices: [])
        data.plays.append(play)
        save()
        return play.id
    }

    func record(_ choice: ChoiceRecord, playID: UUID) {
        guard let index = data.plays.firstIndex(where: { $0.id == playID }) else { return }
        data.plays[index].choices.append(choice)
        save()
    }

    func finishPlay(_ playID: UUID, at date: Date = Date()) {
        guard let index = data.plays.firstIndex(where: { $0.id == playID }),
              data.plays[index].finishedAt == nil else { return }
        data.plays[index].finishedAt = date
        data.stars += 1
        save()
    }

    func logFeeling(_ feeling: Feeling, moment: FeelingMoment, scenarioID: String? = nil, at date: Date = Date()) {
        data.feelings.append(FeelingRecord(id: UUID(), feeling: feeling, moment: moment,
                                           scenarioID: scenarioID, date: date))
        save()
    }

    func stats(for scenarioID: String) -> ScenarioStats {
        let plays = data.plays.filter { $0.scenarioID == scenarioID }
        let answered = plays.reduce(0) { $0 + $1.phasesAnswered }
        let great = plays.reduce(0) { $0 + $1.greatOnFirstTry }
        return ScenarioStats(
            plays: plays.count,
            completions: plays.filter(\.isCompleted).count,
            firstTryGreatRate: answered == 0 ? nil : Double(great) / Double(answered)
        )
    }

    func reset() {
        data = ProgressData()
        save()
    }

    private func save() {
        guard let fileURL else { return }
        do {
            let encoded = try JSONEncoder().encode(data)
            try encoded.write(to: fileURL, options: [.atomic])
        } catch {
            print("Failed to save progress: \(error)")
        }
    }
}

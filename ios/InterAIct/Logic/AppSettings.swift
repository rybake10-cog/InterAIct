import Foundation
import Observation

/// Child and caregiver preferences, persisted in `UserDefaults`.
@Observable
final class AppSettings {
    private let defaults: UserDefaults

    var avatarID: String? { didSet { defaults.set(avatarID, forKey: Keys.avatarID) } }
    var childName: String { didSet { defaults.set(childName, forKey: Keys.childName) } }
    var readAloud: Bool { didSet { defaults.set(readAloud, forKey: Keys.readAloud) } }
    /// AVSpeechUtterance rate (0...1). Lower is slower.
    var speechRate: Double { didSet { defaults.set(speechRate, forKey: Keys.speechRate) } }
    var showVideos: Bool { didSet { defaults.set(showVideos, forKey: Keys.showVideos) } }
    var feelingsCheckIn: Bool { didSet { defaults.set(feelingsCheckIn, forKey: Keys.feelingsCheckIn) } }
    var retryUntilGreat: Bool { didSet { defaults.set(retryUntilGreat, forKey: Keys.retryUntilGreat) } }

    static let defaultSpeechRate = 0.42

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [
            Keys.readAloud: true,
            Keys.speechRate: AppSettings.defaultSpeechRate,
            Keys.showVideos: true,
            Keys.feelingsCheckIn: true,
            Keys.retryUntilGreat: true,
        ])
        avatarID = defaults.string(forKey: Keys.avatarID)
        childName = defaults.string(forKey: Keys.childName) ?? ""
        readAloud = defaults.bool(forKey: Keys.readAloud)
        speechRate = defaults.double(forKey: Keys.speechRate)
        showVideos = defaults.bool(forKey: Keys.showVideos)
        feelingsCheckIn = defaults.bool(forKey: Keys.feelingsCheckIn)
        retryUntilGreat = defaults.bool(forKey: Keys.retryUntilGreat)
    }

    var avatar: Avatar? { Avatar.with(id: avatarID) }

    var trimmedChildName: String { childName.trimmingCharacters(in: .whitespacesAndNewlines) }

    private enum Keys {
        static let avatarID = "avatarID"
        static let childName = "childName"
        static let readAloud = "readAloud"
        static let speechRate = "speechRate"
        static let showVideos = "showVideos"
        static let feelingsCheckIn = "feelingsCheckIn"
        static let retryUntilGreat = "retryUntilGreat"
    }
}

import SwiftUI

@main
struct InterAIctApp: App {
    @State private var settings = AppSettings()
    @State private var progress = ProgressStore(fileURL: ProgressStore.defaultFileURL())
    @State private var speaker = Speaker()

    private let library: ScenarioLibrary = {
        do {
            return try ScenarioLibrary.load()
        } catch {
            assertionFailure("Could not load scenarios: \(error)")
            return ScenarioLibrary(scenarios: [])
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(settings)
                .environment(progress)
                .environment(speaker)
                .environment(\.scenarioLibrary, library)
                .onChange(of: settings.readAloud, initial: true) { _, enabled in
                    speaker.autoReadEnabled = enabled
                    if !enabled { speaker.stop() }
                }
                .onChange(of: settings.speechRate, initial: true) { _, rate in
                    speaker.rate = Float(rate)
                }
        }
    }
}

private struct ScenarioLibraryKey: EnvironmentKey {
    static let defaultValue = ScenarioLibrary(scenarios: [])
}

extension EnvironmentValues {
    var scenarioLibrary: ScenarioLibrary {
        get { self[ScenarioLibraryKey.self] }
        set { self[ScenarioLibraryKey.self] = newValue }
    }
}

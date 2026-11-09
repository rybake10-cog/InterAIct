import SwiftUI

struct CompletionView: View {
    let scenario: Scenario
    let avatar: Avatar
    let onPlayAgain: () -> Void
    let onDone: () -> Void
    @Environment(AppSettings.self) private var settings
    @Environment(ProgressStore.self) private var progress
    @Environment(Speaker.self) private var speaker
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var celebrate = false

    private var message: String {
        let name = settings.trimmedChildName
        let proud = name.isEmpty ? "I'm so proud of you!" : "I'm so proud of you, \(name)!"
        return "You did it! \(proud) You practiced \(scenario.title.lowercased()). You earned a star!"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("🌟")
                    .font(.system(size: 110))
                    .scaleEffect(celebrate || reduceMotion ? 1 : 0.4)
                    .accessibilityHidden(true)
                Text("You did it!")
                    .font(.largeTitle.bold())
                    .foregroundStyle(Color.ink)
                Label("+1 star  ·  \(progress.stars) total", systemImage: "star.fill")
                    .font(.title2.bold())
                    .foregroundStyle(Color(hex: "#C98C1B"))
                CompanionBubble(avatar: avatar, text: message)
                HStack(spacing: 12) {
                    Button(action: onPlayAgain) {
                        Label("Play again", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(BigButtonStyle(color: scenario.tint, prominent: false))
                    Button(action: onDone) {
                        Label("All done", systemImage: "checkmark")
                    }
                    .buttonStyle(BigButtonStyle(color: ChoiceKind.great.tint))
                }
            }
            .padding(24)
            .frame(maxWidth: 800)
            .frame(maxWidth: .infinity)
        }
        .sensoryFeedback(.success, trigger: celebrate)
        .task {
            withAnimation(reduceMotion ? nil : .spring(duration: 0.6, bounce: 0.5)) {
                celebrate = true
            }
            speaker.autoSpeak(message)
        }
    }
}

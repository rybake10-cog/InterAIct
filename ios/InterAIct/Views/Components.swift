import SwiftUI

struct SpeakButton: View {
    let text: String
    @Environment(Speaker.self) private var speaker

    var body: some View {
        Button {
            speaker.speak(text)
        } label: {
            Image(systemName: "speaker.wave.2.fill")
                .font(.title2)
                .foregroundStyle(Color.accentColor)
                .frame(width: 56, height: 56)
                .background(Circle().fill(Color.accentColor.opacity(0.12)))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Read aloud")
    }
}

/// The companion avatar "talking" to the child in a speech bubble.
struct CompanionBubble: View {
    let avatar: Avatar
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Text(avatar.emoji)
                .font(.system(size: 64))
                .frame(width: 88, height: 88)
                .background(Circle().fill(avatar.color.opacity(0.25)))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 8) {
                Text(avatar.shortName)
                    .font(.headline)
                    .foregroundStyle(Color.ink.opacity(0.6))
                Text(text)
                    .font(.title3)
                    .foregroundStyle(Color.ink)
                    .fixedSize(horizontal: false, vertical: true)
                HStack {
                    Spacer()
                    SpeakButton(text: text)
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardBackground()
            .accessibilityElement(children: .contain)
            .accessibilityLabel("\(avatar.shortName) says: \(text)")
        }
    }
}

struct ProgressDots: View {
    let current: Int
    let total: Int
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...max(total, 1), id: \.self) { step in
                Capsule()
                    .fill(step <= current ? color : color.opacity(0.2))
                    .frame(width: step == current ? 34 : 14, height: 14)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Step \(current) of \(total)")
    }
}

/// Shows the phase video when available, otherwise a calm emoji illustration.
struct SceneView: View {
    let phase: Phase
    let color: Color
    @Environment(AppSettings.self) private var settings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var failedVideo: String?

    private var videoURL: URL? {
        guard settings.showVideos, let video = phase.video, video != failedVideo else { return nil }
        return Bundle.main.url(forResource: video, withExtension: "mp4")
    }

    var body: some View {
        Group {
            if let videoURL {
                LoopingVideoView(url: videoURL, loops: !reduceMotion) {
                    failedVideo = phase.video
                }
                    .aspectRatio(4 / 3, contentMode: .fit)
                    .background(Color.black.opacity(0.05))
            } else {
                Text(phase.scene)
                    .font(.system(size: 84))
                    .minimumScaleFactor(0.4)
                    .lineLimit(1)
                    .padding(24)
                    .frame(maxWidth: .infinity, minHeight: 220)
                    .background(color.opacity(0.18))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .accessibilityHidden(true)
    }
}

struct ChoiceButton: View {
    let choice: Choice
    let isTried: Bool
    let isSelected: Bool
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: action) {
                HStack(spacing: 16) {
                    Text(choice.icon)
                        .font(.system(size: 44))
                        .accessibilityHidden(true)
                    Text(choice.text)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color.ink)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if isTried {
                        Image(systemName: "arrow.uturn.backward.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Color.ink.opacity(0.4))
                    }
                }
                .padding(18)
                .frame(minHeight: 84)
                .cardBackground(cornerRadius: 22)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(isSelected ? choice.kind.tint : Color.ink.opacity(0.08),
                                      lineWidth: isSelected ? 4 : 2)
                )
                .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(isDisabled)
            .opacity(isTried ? 0.5 : 1)
            .accessibilityHint(isTried ? "Already tried" : "Choose this answer")
            .accessibilityAddTraits(isSelected ? .isSelected : [])

            SpeakButton(text: choice.text)
        }
    }
}

struct AvatarTile: View {
    let avatar: Avatar
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 10) {
            Text(avatar.emoji)
                .font(.system(size: 72))
            Text(avatar.name)
                .font(.headline)
                .foregroundStyle(Color.ink)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 170)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(avatar.color.opacity(isSelected ? 0.4 : 0.18))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(isSelected ? avatar.color : Color.clear, lineWidth: 5)
        )
    }
}

import SwiftUI

/// Runs one scenario: optional feelings check-in, the phases, a celebration, then an optional check-out.
struct ScenarioFlowView: View {
    private enum Stage {
        case checkInBefore, playing, celebrate, checkInAfter
    }

    let scenario: Scenario
    @Environment(AppSettings.self) private var settings
    @Environment(ProgressStore.self) private var progress
    @Environment(Speaker.self) private var speaker
    @Environment(\.dismiss) private var dismiss
    @State private var stage: Stage?
    @State private var session: ScenarioSession?
    @State private var playID: UUID?
    @State private var showCalmCorner = false

    private var avatar: Avatar { settings.avatar ?? Avatar.all[0] }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            switch stage {
            case .checkInBefore:
                FeelingsCheckInView(avatar: avatar, prompt: "Before we start, how do you feel right now?") { feeling in
                    if let feeling {
                        progress.logFeeling(feeling, moment: .beforeScenario, scenarioID: scenario.id)
                    }
                    stage = .playing
                }
            case .playing:
                if let session {
                    PhasePlayView(session: session, avatar: avatar) { record in
                        if let playID { progress.record(record, playID: playID) }
                    }
                }
            case .celebrate:
                CompletionView(scenario: scenario, avatar: avatar, onPlayAgain: start) {
                    if settings.feelingsCheckIn {
                        stage = .checkInAfter
                    } else {
                        dismiss()
                    }
                }
            case .checkInAfter:
                FeelingsCheckInView(avatar: avatar, prompt: "How do you feel now?") { feeling in
                    if let feeling {
                        progress.logFeeling(feeling, moment: .afterScenario, scenarioID: scenario.id)
                    }
                    dismiss()
                }
            case nil:
                EmptyView()
            }
        }
        .navigationTitle(scenario.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showCalmCorner = true
                } label: {
                    Label("Calm Corner", systemImage: "leaf.fill")
                }
            }
        }
        .sheet(isPresented: $showCalmCorner) {
            CalmCornerView()
        }
        .onAppear {
            if stage == nil { start() }
        }
        .onDisappear {
            speaker.stop()
        }
        .onChange(of: session?.isFinished ?? false) { _, finished in
            guard finished else { return }
            if let playID { progress.finishPlay(playID) }
            stage = .celebrate
        }
    }

    private func start() {
        session = ScenarioSession(scenario: scenario, retryUntilGreat: settings.retryUntilGreat)
        playID = progress.startPlay(scenarioID: scenario.id, avatarID: settings.avatarID)
        stage = settings.feelingsCheckIn ? .checkInBefore : .playing
    }
}

struct PhasePlayView: View {
    let session: ScenarioSession
    let avatar: Avatar
    let onChoice: (ChoiceRecord) -> Void
    @Environment(Speaker.self) private var speaker
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if let phase = session.currentPhase {
            let layout = sizeClass == .regular
                ? AnyLayout(HStackLayout(alignment: .top, spacing: 20))
                : AnyLayout(VStackLayout(spacing: 16))
            ScrollView {
                VStack(spacing: 20) {
                    ProgressDots(current: session.phaseNumber, total: session.phaseCount,
                                 color: session.scenario.tint)
                    Text(phase.title)
                        .font(.title.bold())
                        .foregroundStyle(Color.ink)
                        .multilineTextAlignment(.center)
                    layout {
                        SceneView(phase: phase, color: session.scenario.tint)
                            .frame(maxWidth: .infinity)
                        CompanionBubble(avatar: avatar, text: phase.prompt)
                            .frame(maxWidth: .infinity)
                    }
                    VStack(spacing: 14) {
                        ForEach(phase.choices) { choice in
                            ChoiceButton(
                                choice: choice,
                                isTried: session.isTried(choice),
                                isSelected: session.selectedChoice == choice,
                                isDisabled: session.selectedChoice != nil || session.isTried(choice)
                            ) {
                                if let record = session.choose(choice) {
                                    onChoice(record)
                                    speaker.autoSpeak("\(choice.kind.headline) \(choice.feedback)")
                                }
                            }
                        }
                    }
                }
                .padding(24)
                .frame(maxWidth: 1000)
                .frame(maxWidth: .infinity)
            }
            .id(phase.id)
            .safeAreaInset(edge: .bottom) {
                if let choice = session.selectedChoice {
                    FeedbackPanel(
                        choice: choice,
                        avatar: avatar,
                        canContinue: session.canContinue,
                        canTryAgain: session.canTryAgain,
                        onTryAgain: { session.tryAgain() },
                        onContinue: { session.advance() }
                    )
                    .frame(maxWidth: .infinity)
                    .background {
                        LinearGradient(colors: [Color.appBackground.opacity(0), Color.appBackground],
                                       startPoint: .top, endPoint: .center)
                            .ignoresSafeArea(edges: .bottom)
                    }
                    .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(reduceMotion ? nil : .spring(duration: 0.35), value: session.selectedChoice)
            .sensoryFeedback(trigger: session.selectedChoice) { _, newValue in
                newValue?.kind == .great ? .success : nil
            }
            .task(id: phase.id) {
                speaker.autoSpeak(phase.prompt)
            }
        }
    }
}

struct FeedbackPanel: View {
    let choice: Choice
    let avatar: Avatar
    let canContinue: Bool
    let canTryAgain: Bool
    let onTryAgain: () -> Void
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                Text(avatar.emoji)
                    .font(.system(size: 52))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 6) {
                    Text(choice.kind.headline)
                        .font(.title2.bold())
                        .foregroundStyle(choice.kind.tint)
                    Text(choice.feedback)
                        .font(.title3)
                        .foregroundStyle(Color.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                SpeakButton(text: "\(choice.kind.headline) \(choice.feedback)")
            }
            .accessibilityElement(children: .combine)

            AdaptiveButtonRow {
                if canTryAgain {
                    Button(action: onTryAgain) {
                        Label("Try another way", systemImage: "arrow.uturn.backward")
                    }
                    .buttonStyle(BigButtonStyle(color: ChoiceKind.tryAgain.tint, prominent: !canContinue))
                }
                if canContinue {
                    Button(action: onContinue) {
                        Label(choice.next == nil ? "Finish" : "Next", systemImage: "arrow.right")
                    }
                    .buttonStyle(BigButtonStyle(color: choice.kind == .great ? ChoiceKind.great.tint : ChoiceKind.tryAgain.tint))
                }
            }
        }
        .padding(20)
        .frame(maxWidth: 900)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.card)
                .shadow(color: Color.ink.opacity(0.18), radius: 16, y: -2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(choice.kind.tint.opacity(0.5), lineWidth: 3)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}

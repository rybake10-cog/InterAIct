import SwiftUI

struct CalmCornerView: View {
    private enum Tool: String, CaseIterable, Identifiable {
        case breathe = "Breathe"
        case senses = "5 Senses"
        var id: String { rawValue }
    }

    @Environment(\.dismiss) private var dismiss
    @State private var tool: Tool = .breathe

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Picker("Calm tool", selection: $tool) {
                    ForEach(Tool.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 24)

                switch tool {
                case .breathe: BreathingView()
                case .senses: SensesView()
                }
            }
            .padding(.top, 12)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.calmBackground.ignoresSafeArea())
            .navigationTitle("Calm Corner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .fontDesign(.rounded)
        .largeSheetOnIPad()
    }
}

/// A balloon that slowly grows and shrinks: 4 seconds in, 4 seconds out.
struct BreathingView: View {
    @Environment(Speaker.self) private var speaker
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var inhaling = false
    @State private var breaths = 0

    private let seconds = 4.0

    var body: some View {
        GeometryReader { geometry in
            let balloon = max(120, min(300, geometry.size.width - 48, geometry.size.height * 0.45))
            VStack(spacing: 28) {
                Spacer(minLength: 0)
                ZStack {
                    Circle()
                        .fill(Color(hex: "#9ED2C6").opacity(0.35))
                        .frame(width: balloon, height: balloon)
                    Circle()
                        .fill(Color(hex: "#5FB49C"))
                        .frame(width: balloon - 20, height: balloon - 20)
                        .scaleEffect(reduceMotion ? 0.8 : (inhaling ? 1 : 0.4))
                        .opacity(reduceMotion ? (inhaling ? 1 : 0.5) : 1)
                }
                .accessibilityHidden(true)
                Text(inhaling ? "Breathe in…" : "Breathe out…")
                    .font(.largeTitle.bold())
                    .foregroundStyle(Color.ink)
                    .transaction { $0.animation = nil }
                    .accessibilityAddTraits(.updatesFrequently)
                Text("Watch the balloon. Breathe in while it grows. Breathe out while it shrinks.")
                    .font(.title3)
                    .foregroundStyle(Color.ink.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 32)
                Text("Breaths: \(breaths)")
                    .font(.headline)
                    .foregroundStyle(Color.ink.opacity(0.6))
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .task {
            while !Task.isCancelled {
                speaker.autoSpeak("Breathe in")
                withAnimation(.easeInOut(duration: seconds)) { inhaling = true }
                try? await Task.sleep(for: .seconds(seconds))
                if Task.isCancelled { break }
                speaker.autoSpeak("Breathe out")
                withAnimation(.easeInOut(duration: seconds)) { inhaling = false }
                try? await Task.sleep(for: .seconds(seconds))
                breaths += 1
            }
        }
        .onDisappear { speaker.stop() }
    }
}

/// The 5-4-3-2-1 grounding exercise, one step at a time.
struct SensesView: View {
    private struct Step {
        let count: Int
        let emoji: String
        let text: String
    }

    private let steps = [
        Step(count: 5, emoji: "👀", text: "Find 5 things you can see."),
        Step(count: 4, emoji: "✋", text: "Find 4 things you can touch."),
        Step(count: 3, emoji: "👂", text: "Listen for 3 things you can hear."),
        Step(count: 2, emoji: "👃", text: "Find 2 things you can smell."),
        Step(count: 1, emoji: "👅", text: "Think of 1 thing you can taste."),
    ]

    @Environment(Speaker.self) private var speaker
    @State private var index = 0

    private var isDone: Bool { index >= steps.count }
    private var currentText: String {
        isDone ? "You did it! Your body and brain are noticing the world around you." : steps[index].text
    }

    var body: some View {
        VStack(spacing: 28) {
            Spacer(minLength: 0)
            Text(isDone ? "🌈" : steps[index].emoji)
                .font(.system(size: 120))
                .accessibilityHidden(true)
            if !isDone {
                Text("\(steps[index].count)")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "#3E9B6B"))
            }
            HStack(alignment: .center, spacing: 12) {
                Text(currentText)
                    .font(.title2.bold())
                    .foregroundStyle(Color.ink)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                SpeakButton(text: currentText)
            }
            .padding(.horizontal, 24)
            Spacer(minLength: 0)
            Button {
                index = isDone ? 0 : index + 1
            } label: {
                Label(isDone ? "Start again" : "Next", systemImage: isDone ? "arrow.clockwise" : "arrow.right")
            }
            .buttonStyle(BigButtonStyle(color: Color(hex: "#3E9B6B")))
            .frame(maxWidth: 500)
            .padding(24)
        }
        .task(id: index) {
            speaker.autoSpeak(currentText)
        }
        .onDisappear { speaker.stop() }
    }
}

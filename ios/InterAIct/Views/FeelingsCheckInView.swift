import SwiftUI

struct FeelingsCheckInView: View {
    let avatar: Avatar
    let prompt: String
    let onDone: (Feeling?) -> Void
    @Environment(Speaker.self) private var speaker
    @State private var picked: Feeling?
    @State private var showCalmCorner = false
    private let supportCardID = "support"

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 24) {
                    CompanionBubble(avatar: avatar, text: prompt)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), spacing: 14)], spacing: 14) {
                        ForEach(Feeling.allCases) { feeling in
                            Button {
                                pick(feeling)
                            } label: {
                                VStack(spacing: 8) {
                                    Text(feeling.emoji)
                                        .font(.system(size: 56))
                                    Text(feeling.label)
                                        .font(.title3.bold())
                                        .foregroundStyle(Color.ink)
                                }
                                .frame(maxWidth: .infinity, minHeight: 130)
                                .cardBackground(cornerRadius: 22)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                                        .strokeBorder(picked == feeling ? avatar.color : Color.clear, lineWidth: 5)
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(feeling.label)
                            .accessibilityAddTraits(picked == feeling ? .isSelected : [])
                        }
                    }

                    if let picked, picked.suggestsCalmCorner {
                        VStack(spacing: 14) {
                            Text(supportMessage(for: picked))
                                .font(.title3)
                                .foregroundStyle(Color.ink)
                                .multilineTextAlignment(.center)
                            AdaptiveButtonRow {
                                Button {
                                    showCalmCorner = true
                                } label: {
                                    Label("Calm Corner", systemImage: "leaf.fill")
                                }
                                .buttonStyle(BigButtonStyle(color: Color(hex: "#3E9B6B")))
                                Button {
                                    onDone(picked)
                                } label: {
                                    Label("I'm ready", systemImage: "arrow.right")
                                }
                                .buttonStyle(BigButtonStyle(color: .accentColor, prominent: false))
                            }
                        }
                        .padding(20)
                        .cardBackground()
                        .id(supportCardID)
                    }

                    Button("Skip") {
                        onDone(nil)
                    }
                    .font(.title3)
                    .padding()
                }
                .padding(24)
                .frame(maxWidth: 800)
                .frame(maxWidth: .infinity)
            }
            .onChange(of: picked) { _, feeling in
                guard feeling?.suggestsCalmCorner == true else { return }
                withAnimation { proxy.scrollTo(supportCardID, anchor: .bottom) }
            }
        }
        .task {
            speaker.autoSpeak(prompt)
        }
        .sheet(isPresented: $showCalmCorner) {
            CalmCornerView()
        }
    }

    private func pick(_ feeling: Feeling) {
        picked = feeling
        if feeling.suggestsCalmCorner {
            speaker.autoSpeak(supportMessage(for: feeling))
        } else {
            onDone(feeling)
        }
    }

    private func supportMessage(for feeling: Feeling) -> String {
        "It is okay to feel \(feeling.label.lowercased()). Would you like to visit the Calm Corner first?"
    }
}

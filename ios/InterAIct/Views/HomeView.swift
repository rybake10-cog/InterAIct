import SwiftUI

struct HomeView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(ProgressStore.self) private var progress
    @Environment(\.scenarioLibrary) private var library
    @State private var path: [Scenario] = []
    @State private var showCalmCorner = false
    @State private var showGrownUps = false

    private var avatar: Avatar { settings.avatar ?? Avatar.all[0] }

    private var greeting: String {
        let name = settings.trimmedChildName
        let hello = name.isEmpty ? "Hi!" : "Hi, \(name)!"
        return "\(hello) I'm \(avatar.shortName). What would you like to practice today?"
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    CompanionBubble(avatar: avatar, text: greeting)

                    HStack(spacing: 12) {
                        Label("\(progress.stars) stars", systemImage: "star.fill")
                            .font(.title3.bold())
                            .foregroundStyle(Color(hex: "#C98C1B"))
                            .padding(.horizontal, 18)
                            .frame(minHeight: 60)
                            .cardBackground(cornerRadius: 20)
                            .accessibilityLabel("You have \(progress.stars) stars")
                        Button {
                            showCalmCorner = true
                        } label: {
                            Label("Calm Corner", systemImage: "leaf.fill")
                        }
                        .buttonStyle(BigButtonStyle(color: Color(hex: "#3E9B6B")))
                    }

                    Text("Choose a situation to practice")
                        .font(.title2.bold())
                        .foregroundStyle(Color.ink)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 300), spacing: 16)], spacing: 16) {
                        ForEach(library.scenarios) { scenario in
                            NavigationLink(value: scenario) {
                                ScenarioCard(
                                    scenario: scenario,
                                    isCompleted: progress.completedScenarioIDs.contains(scenario.id)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(24)
                .frame(maxWidth: 1100)
                .frame(maxWidth: .infinity)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("InterAIct")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showGrownUps = true
                    } label: {
                        Label("Grown-ups", systemImage: "lock.fill")
                    }
                }
            }
            .navigationDestination(for: Scenario.self) { scenario in
                ScenarioFlowView(scenario: scenario)
            }
            .sheet(isPresented: $showCalmCorner) {
                CalmCornerView()
            }
            .sheet(isPresented: $showGrownUps) {
                ParentAreaView()
            }
        }
    }
}

struct ScenarioCard: View {
    let scenario: Scenario
    let isCompleted: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Text(scenario.icon)
                .font(.system(size: 48))
                .frame(width: 84, height: 84)
                .background(Circle().fill(scenario.tint.opacity(0.25)))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 6) {
                Text(scenario.title)
                    .font(.title3.bold())
                    .foregroundStyle(Color.ink)
                Text(scenario.summary)
                    .font(.body)
                    .foregroundStyle(Color.ink.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
                Text(scenario.skill)
                    .font(.caption.bold())
                    .foregroundStyle(Color.ink)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(scenario.tint.opacity(0.3)))
            }
            Spacer(minLength: 0)
            if isCompleted {
                Image(systemName: "star.fill")
                    .font(.title2)
                    .foregroundStyle(Color(hex: "#E8B931"))
                    .accessibilityLabel("Completed")
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardBackground()
        .accessibilityElement(children: .combine)
        .accessibilityHint("Starts practicing \(scenario.title)")
    }
}

import SwiftUI

/// Grown-up area: a simple math gate, then the progress report and settings.
struct ParentAreaView: View {
    @State private var unlocked = false

    var body: some View {
        NavigationStack {
            if unlocked {
                ParentDashboardView()
            } else {
                ParentGateView { unlocked = true }
            }
        }
        .fontDesign(.rounded)
    }
}

struct ParentGateView: View {
    let onUnlock: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var first = Int.random(in: 6...9)
    @State private var second = Int.random(in: 4...9)
    @State private var entry = ""
    @State private var showError = false

    private let keys = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "⌫", "0", "✓"]

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.fill")
                .font(.system(size: 44))
                .foregroundStyle(Color.accentColor)
            Text("Grown-ups only")
                .font(.largeTitle.bold())
            Text("What is \(first) + \(second)?")
                .font(.title2)
            Text(entry.isEmpty ? " " : entry)
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .frame(minWidth: 140, minHeight: 64)
                .cardBackground(cornerRadius: 16)
                .accessibilityLabel(entry.isEmpty ? "No answer yet" : "Answer \(entry)")
            if showError {
                Text("Not quite. Try this one.")
                    .foregroundStyle(.secondary)
            }
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(88), spacing: 12), count: 3), spacing: 12) {
                ForEach(keys, id: \.self) { key in
                    Button {
                        press(key)
                    } label: {
                        Text(key)
                            .font(.title.bold())
                            .frame(width: 88, height: 64)
                            .cardBackground(cornerRadius: 16)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(key == "⌫" ? "Delete" : key == "✓" ? "Submit" : key)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground.ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
        }
    }

    private func press(_ key: String) {
        switch key {
        case "⌫":
            if !entry.isEmpty { entry.removeLast() }
        case "✓":
            if Int(entry) == first + second {
                onUnlock()
            } else {
                showError = true
                entry = ""
                first = Int.random(in: 6...9)
                second = Int.random(in: 4...9)
            }
        default:
            if entry.count < 3 { entry.append(key) }
        }
    }
}

struct ParentDashboardView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(ProgressStore.self) private var progress
    @Environment(\.scenarioLibrary) private var library
    @Environment(\.dismiss) private var dismiss
    @State private var confirmReset = false

    var body: some View {
        @Bindable var settings = settings
        Form {
            Section("Overview") {
                LabeledContent("Stars earned", value: "\(progress.stars)")
                LabeledContent("Situations completed",
                               value: "\(progress.completedScenarioIDs.count) of \(library.scenarios.count)")
                LabeledContent("Practice sessions started", value: "\(progress.data.plays.count)")
            }

            Section {
                ForEach(library.scenarios) { scenario in
                    let stats = progress.stats(for: scenario.id)
                    HStack(spacing: 12) {
                        Text(scenario.icon).font(.title)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(scenario.title).font(.headline)
                            Text("\(stats.completions) completed · \(stats.plays) started")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if let rate = stats.firstTryGreatRate {
                            Text(rate, format: .percent.precision(.fractionLength(0)))
                                .font(.headline)
                        } else {
                            Text("–").foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityElement(children: .combine)
                }
            } header: {
                Text("Situations")
            } footer: {
                Text("The percentage shows how often the child's first answer was the most helpful choice.")
            }

            Section("Recent feelings") {
                if progress.data.feelings.isEmpty {
                    Text("No check-ins yet.").foregroundStyle(.secondary)
                } else {
                    ForEach(Array(progress.data.feelings.suffix(20).reversed())) { record in
                        HStack(spacing: 12) {
                            Text(record.feeling.emoji).font(.title)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(record.feeling.label).font(.headline)
                                Text(feelingDetail(record))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(record.date.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            }

            Section("Child settings") {
                TextField("Child's name", text: $settings.childName)
                Picker("Companion", selection: $settings.avatarID) {
                    ForEach(Avatar.all) { avatar in
                        Text("\(avatar.emoji) \(avatar.name)").tag(Optional(avatar.id))
                    }
                }
                Toggle("Read aloud automatically", isOn: $settings.readAloud)
                VStack(alignment: .leading) {
                    Text("Voice speed")
                    Slider(value: $settings.speechRate, in: 0.3...0.55) {
                        Text("Voice speed")
                    } minimumValueLabel: {
                        Image(systemName: "tortoise.fill")
                    } maximumValueLabel: {
                        Image(systemName: "hare.fill")
                    }
                }
                Toggle("Show videos", isOn: $settings.showVideos)
                Toggle("Feelings check-in", isOn: $settings.feelingsCheckIn)
                Toggle("Keep trying until the most helpful choice", isOn: $settings.retryUntilGreat)
            }

            Section {
                Button("Reset all progress", role: .destructive) {
                    confirmReset = true
                }
            } footer: {
                Text("All progress stays on this device. InterAIct does not use the camera, microphone, accounts, or the internet.")
            }
        }
        .navigationTitle("Grown-ups")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
        .confirmationDialog("Reset all progress?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Reset", role: .destructive) { progress.reset() }
        } message: {
            Text("Stars, practice history, and feelings check-ins will be deleted.")
        }
    }

    private func feelingDetail(_ record: FeelingRecord) -> String {
        if let id = record.scenarioID, let scenario = library.scenario(id: id) {
            return "\(record.moment.label) · \(scenario.title)"
        }
        return record.moment.label
    }
}

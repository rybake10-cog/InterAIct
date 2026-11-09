import SwiftUI

struct OnboardingView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(Speaker.self) private var speaker
    @State private var selected: Avatar?
    @State private var name = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                Text("💬🤝😊")
                    .font(.system(size: 64))
                    .accessibilityHidden(true)
                Text("Choose Your Friend!")
                    .font(.largeTitle.bold())
                    .foregroundStyle(Color.ink)
                Text("Pick a friend who will help you practice feelings and making friends.")
                    .font(.title3)
                    .foregroundStyle(Color.ink.opacity(0.75))
                    .multilineTextAlignment(.center)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 16)], spacing: 16) {
                    ForEach(Avatar.all) { avatar in
                        Button {
                            selected = avatar
                            speaker.autoSpeak("Hi! I'm \(avatar.name).")
                        } label: {
                            AvatarTile(avatar: avatar, isSelected: selected == avatar)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(avatar.name)
                        .accessibilityAddTraits(selected == avatar ? .isSelected : [])
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("What is your name? (You can skip this.)")
                        .font(.headline)
                        .foregroundStyle(Color.ink)
                    TextField("Your name", text: $name)
                        .font(.title3)
                        .textContentType(.givenName)
                        .autocorrectionDisabled()
                        .padding(14)
                        .cardBackground(cornerRadius: 16)
                }

                Button {
                    settings.childName = name
                    settings.avatarID = selected?.id
                } label: {
                    Label("Let's go!", systemImage: "arrow.right.circle.fill")
                }
                .buttonStyle(BigButtonStyle(color: selected?.color ?? .accentColor))
                .disabled(selected == nil)
            }
            .padding(24)
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .onAppear {
            name = settings.childName
        }
    }
}

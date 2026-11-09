import SwiftUI

extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        self.init(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }

    static let appBackground = Color(hex: "#FFF8EE")
    static let calmBackground = Color(hex: "#EAF5F1")
    static let ink = Color(hex: "#2E3A59")
    static let card = Color.white
}

extension ChoiceKind {
    /// Gentle colors only: green, gold, and blue. Never red.
    var tint: Color {
        switch self {
        case .great: Color(hex: "#3E9B6B")
        case .okay: Color(hex: "#C98C1B")
        case .tryAgain: Color(hex: "#4F7CAC")
        }
    }

    var headline: String {
        switch self {
        case .great: "Great choice!"
        case .okay: "Good thinking!"
        case .tryAgain: "Let's think about it."
        }
    }
}

extension Avatar {
    var color: Color { Color(hex: colorHex) }
}

extension Scenario {
    var tint: Color { Color(hex: color) }
}

struct BigButtonStyle: ButtonStyle {
    var color: Color = .accentColor
    var prominent = true

    func makeBody(configuration: Configuration) -> some View {
        BigButton(configuration: configuration, color: color, prominent: prominent)
    }

    private struct BigButton: View {
        let configuration: ButtonStyleConfiguration
        let color: Color
        let prominent: Bool
        @Environment(\.isEnabled) private var isEnabled

        var body: some View {
            configuration.label
                .font(.title3.bold())
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity, minHeight: 60)
                .foregroundStyle(prominent ? Color.white : color)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(prominent ? color : color.opacity(0.15))
                )
                .opacity(isEnabled ? 1 : 0.4)
                .scaleEffect(configuration.isPressed ? 0.97 : 1)
                .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }
}

struct CardBackground: ViewModifier {
    var cornerRadius: CGFloat = 24

    func body(content: Content) -> some View {
        content.background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.card)
                .shadow(color: Color.ink.opacity(0.08), radius: 8, y: 3)
        )
    }
}

extension View {
    func cardBackground(cornerRadius: CGFloat = 24) -> some View {
        modifier(CardBackground(cornerRadius: cornerRadius))
    }
}

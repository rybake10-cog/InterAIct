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
                .foregroundStyle(prominent ? Color.white : Color.ink)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(prominent ? color : color.opacity(0.15))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(prominent ? Color.clear : color.opacity(0.6), lineWidth: 2)
                )
                .opacity(isEnabled ? 1 : 0.4)
                .scaleEffect(configuration.isPressed ? 0.97 : 1)
                .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }
}

/// Lays buttons out side by side, or stacks them when their labels would have to wrap.
struct AdaptiveButtonRow<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) { content.lineLimit(1) }
            VStack(spacing: 12) { content }
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

extension View {
    /// Shows a sheet as a large page on iPad instead of a small form sheet.
    @ViewBuilder
    func largeSheetOnIPad() -> some View {
        if #available(iOS 18.0, *) {
            presentationSizing(.page)
        } else {
            self
        }
    }
}

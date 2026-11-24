import SwiftUI

enum Theme {
    static let bg = Color(red: 0.05, green: 0.04, blue: 0.10)
    static let bg2 = Color(red: 0.10, green: 0.06, blue: 0.20)
    static let accent = Color(red: 0.62, green: 0.35, blue: 1.0)
    static let neon = Color(red: 0.30, green: 1.0, blue: 0.60)
    static let danger = Color(red: 1.0, green: 0.32, blue: 0.42)
    static let warning = Color(red: 1.0, green: 0.72, blue: 0.25)
    static let card = Color.white.opacity(0.06)
    static let stroke = Color.white.opacity(0.10)

    static let gradient = LinearGradient(colors: [accent, neon], startPoint: .topLeading, endPoint: .bottomTrailing)

    static func scoreColor(_ score: Int) -> Color {
        switch score {
        case ..<30: return neon
        case 30..<55: return warning
        default: return danger
        }
    }
}

struct AppBackground: View {
    var body: some View {
        ZStack {
            Theme.bg
            RadialGradient(colors: [Theme.accent.opacity(0.35), .clear],
                           center: .topTrailing, startRadius: 10, endRadius: 420)
            RadialGradient(colors: [Theme.neon.opacity(0.12), .clear],
                           center: .bottomLeading, startRadius: 10, endRadius: 380)
        }
        .ignoresSafeArea()
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    var enabled = true
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 18, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(enabled ? AnyShapeStyle(Theme.gradient) : AnyShapeStyle(Color.white.opacity(0.12)))
            )
            .shadow(color: enabled ? Theme.accent.opacity(0.45) : .clear, radius: 16, y: 6)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.25), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .foregroundStyle(.white.opacity(0.85))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(RoundedRectangle(cornerRadius: 18).stroke(Theme.stroke, lineWidth: 1.5))
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

struct Card<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 24).fill(Theme.card))
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(Theme.stroke, lineWidth: 1))
    }
}

struct ProgressBar: View {
    var progress: Double
    var body: some View {
        GeometryReader { geo in
            Capsule().fill(Color.white.opacity(0.1))
                .overlay(alignment: .leading) {
                    Capsule().fill(Theme.gradient)
                        .frame(width: geo.size.width * max(0, min(1, progress)))
                        .animation(.easeInOut, value: progress)
                }
        }
        .frame(height: 6)
    }
}

struct ScoreRing: View {
    var score: Int
    var size: CGFloat = 200
    @State private var animated: Double = 0

    var body: some View {
        ZStack {
            Circle().stroke(Color.white.opacity(0.08), lineWidth: 18)
            Circle()
                .trim(from: 0, to: animated)
                .stroke(AngularGradient(colors: [Theme.neon, Theme.warning, Theme.danger], center: .center),
                        style: StrokeStyle(lineWidth: 18, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 2) {
                Text("\(Int(animated * 100))")
                    .font(.system(size: size * 0.28, weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.scoreColor(score))
                    .contentTransition(.numericText())
                Text("out of 100").font(.caption).foregroundStyle(.secondary)
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.easeOut(duration: 1.6)) { animated = Double(score) / 100 }
        }
    }
}

struct SelectableRow: View {
    var emoji: String
    var text: String
    var selected: Bool
    var multi: Bool

    var body: some View {
        HStack(spacing: 14) {
            Text(emoji).font(.system(size: 26))
            Text(text)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
            Spacer()
            Image(systemName: selected
                  ? (multi ? "checkmark.square.fill" : "checkmark.circle.fill")
                  : (multi ? "square" : "circle"))
                .font(.title3)
                .foregroundStyle(selected ? Theme.neon : .white.opacity(0.3))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(selected ? Theme.accent.opacity(0.22) : Theme.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(selected ? Theme.accent : Theme.stroke, lineWidth: selected ? 2 : 1)
        )
        .animation(.spring(response: 0.25), value: selected)
    }
}

struct StepHeader: View {
    var title: String
    var subtitle: String?
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 30, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(0.65))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

func hapticTap(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
    UIImpactFeedbackGenerator(style: style).impactOccurred()
}

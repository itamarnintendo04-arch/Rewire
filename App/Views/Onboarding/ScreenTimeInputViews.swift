import SwiftUI

/// Big hours/minutes readout with a slider and ± buttons.
struct MinutesDial: View {
    @Binding var minutes: Int
    var range: ClosedRange<Int>
    var step: Int = 15
    var color: AnyShapeStyle = AnyShapeStyle(Theme.gradient)

    var body: some View {
        VStack(spacing: 18) {
            HStack(spacing: 18) {
                roundButton("minus") { minutes = max(range.lowerBound, minutes - step) }
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(minutes / 60)")
                        .font(.system(size: 64, weight: .black, design: .rounded).monospacedDigit())
                    Text("שע׳").font(.title3.weight(.bold)).foregroundStyle(.white.opacity(0.6))
                    Text(String(format: "%02d", minutes % 60))
                        .font(.system(size: 64, weight: .black, design: .rounded).monospacedDigit())
                    Text("דק׳").font(.title3.weight(.bold)).foregroundStyle(.white.opacity(0.6))
                }
                .foregroundStyle(color)
                .frame(maxWidth: .infinity)
                roundButton("plus") { minutes = min(range.upperBound, minutes + step) }
            }
            Slider(value: Binding(get: { Double(minutes) },
                                  set: { minutes = Int($0) / step * step }),
                   in: Double(range.lowerBound)...Double(max(range.upperBound, range.lowerBound + step)),
                   step: Double(step))
                .tint(Theme.accent)
            HStack {
                Text(formatMinutes(range.lowerBound))
                Spacer()
                Text(formatMinutes(range.upperBound))
            }
            .font(.caption).foregroundStyle(.white.opacity(0.4))
        }
    }

    private func roundButton(_ icon: String, action: @escaping () -> Void) -> some View {
        Button {
            hapticTap()
            action()
        } label: {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(Circle().fill(Theme.card))
                .overlay(Circle().stroke(Theme.stroke))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Current screen time

struct ScreenTimeInputView: View {
    @EnvironmentObject var model: AppModel
    let question: QuizQuestion
    var onNext: () -> Void

    private let average = 270 // ~4.5h

    var body: some View {
        OnboardingPage {
            VStack(alignment: .leading, spacing: 26) {
                StepHeader(title: question.title, subtitle: question.subtitle)

                Card {
                    VStack(spacing: 18) {
                        Text(reaction.emoji).font(.system(size: 56))
                        MinutesDial(minutes: $model.quiz.currentMinutes, range: 30...720)
                        Text(reaction.text)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(reaction.color)
                            .multilineTextAlignment(.center)
                    }
                }

                comparison
            }
        } footer: {
            Button("המשך", action: onNext).buttonStyle(PrimaryButtonStyle())
        }
    }

    private var minutes: Int { model.quiz.currentMinutes }

    private var reaction: (emoji: String, text: String, color: Color) {
        switch minutes {
        case ..<120: return ("🙂", "פחות מהממוצע, יפה!", Theme.neon)
        case 120..<240: return ("😐", "קרוב לממוצע. יש מקום לשיפור.", .white.opacity(0.8))
        case 240..<360: return ("😬", "מעל הממוצע. זה מצטבר מהר.", Theme.warning)
        case 360..<480: return ("😵", "רבע מהיום שלך הולך למסך.", Theme.danger)
        default: return ("💀", "יותר משליש מהשעות שאת/ה ער/ה.", Theme.danger)
        }
    }

    private var comparison: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                bar("את/ה", minutes, Theme.scoreColor(minutes > average ? 70 : 20))
                bar("ממוצע", average, .white.opacity(0.4))
                Text("זה \(Int(Double(minutes) * 365 / 60 / 24)) ימים שלמים בשנה מול המסך.")
                    .font(.footnote).foregroundStyle(.white.opacity(0.6))
            }
        }
    }

    private func bar(_ label: String, _ value: Int, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label).font(.subheadline.weight(.semibold)).foregroundStyle(.white.opacity(0.85))
                Spacer()
                Text(formatMinutes(value)).font(.subheadline.monospacedDigit()).foregroundStyle(color)
            }
            GeometryReader { geo in
                Capsule().fill(Color.white.opacity(0.08))
                    .overlay(alignment: .leading) {
                        Capsule().fill(color)
                            .frame(width: geo.size.width * min(1, CGFloat(value) / 720))
                            .animation(.easeOut, value: value)
                    }
            }
            .frame(height: 8)
        }
    }
}

// MARK: - Goal

struct GoalInputView: View {
    @EnvironmentObject var model: AppModel
    let question: QuizQuestion
    var onNext: () -> Void

    var body: some View {
        let current = model.quiz.currentMinutes
        let maxGoal = max(15, current - 15)
        OnboardingPage {
            VStack(alignment: .leading, spacing: 24) {
                StepHeader(title: question.title,
                           subtitle: "היום: \(formatMinutes(current)) ביום. בחר/י יעד ריאלי, אפשר להוריד בהדרגה.")

                Card {
                    VStack(spacing: 18) {
                        Text("🎯").font(.system(size: 52))
                        MinutesDial(minutes: $model.quiz.goalMinutes,
                                    range: 15...maxGoal,
                                    color: AnyShapeStyle(Theme.neon))
                    }
                }

                HStack(spacing: 10) {
                    preset("‎-25%", current * 3 / 4, maxGoal)
                    preset("חצי", current / 2, maxGoal)
                    preset("‎-75%", current / 4, maxGoal)
                }

                Card {
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("פחות ביום").font(.caption).foregroundStyle(.white.opacity(0.6))
                            Text(formatMinutes(max(0, current - model.quiz.goalMinutes)))
                                .font(.title2.weight(.heavy)).foregroundStyle(Theme.neon)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("שנים שתחזיר/י").font(.caption).foregroundStyle(.white.opacity(0.6))
                            Text(String(format: "%.1f", model.quiz.result.yearsRegained))
                                .font(.title2.weight(.heavy)).foregroundStyle(Theme.neon)
                        }
                    }
                }
            }
        } footer: {
            Button("זה היעד שלי", action: onNext).buttonStyle(PrimaryButtonStyle())
        }
        .onAppear {
            if model.quiz.goalMinutes > maxGoal {
                model.quiz.goalMinutes = QuizState.defaultGoal(for: current)
            }
        }
    }

    private func preset(_ title: String, _ value: Int, _ maxGoal: Int) -> some View {
        let v = min(maxGoal, max(15, value / 15 * 15))
        let selected = model.quiz.goalMinutes == v
        return Button {
            hapticTap()
            model.quiz.goalMinutes = v
        } label: {
            VStack(spacing: 2) {
                Text(title).font(.subheadline.weight(.bold))
                Text(formatMinutes(v)).font(.caption2).foregroundStyle(.white.opacity(0.6))
            }
            .frame(maxWidth: .infinity).padding(.vertical, 10)
            .background(RoundedRectangle(cornerRadius: 14).fill(selected ? Theme.neon.opacity(0.2) : Theme.card))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(selected ? Theme.neon : Theme.stroke))
            .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
    }
}

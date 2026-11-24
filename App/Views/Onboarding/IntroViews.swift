import SwiftUI

struct WelcomeView: View {
    var onNext: () -> Void
    @State private var pulse = false

    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            ZStack {
                Circle().fill(Theme.accent.opacity(0.25)).frame(width: 220, height: 220)
                    .blur(radius: 30).scaleEffect(pulse ? 1.15 : 0.9)
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 110, weight: .bold))
                    .foregroundStyle(Theme.gradient)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) { pulse = true }
            }

            VStack(spacing: 14) {
                Text("Rewire")
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text("הטלפון שלך מתוכנת להתמכר.\nבוא/י נתכנת את המוח שלך מחדש.")
                    .font(.system(size: 19, weight: .medium))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.7))
            }
            Spacer()
            VStack(spacing: 12) {
                Button("בוא/י נתחיל", action: onNext).buttonStyle(PrimaryButtonStyle())
                Text("שאלון קצר של דקה · בלי הרשמה")
                    .font(.footnote).foregroundStyle(.white.opacity(0.45))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
    }
}

struct NameView: View {
    @EnvironmentObject var model: AppModel
    var onNext: () -> Void
    @FocusState private var focused: Bool

    var body: some View {
        OnboardingPage {
            VStack(alignment: .leading, spacing: 28) {
                StepHeader(title: "קודם כל, איך קוראים לך?",
                           subtitle: "כדי שנוכל לדבר איתך כמו חברים 🤝")
                TextField("השם שלך", text: $model.userName)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .padding(20)
                    .background(RoundedRectangle(cornerRadius: 18).fill(Theme.card))
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(focused ? Theme.accent : Theme.stroke, lineWidth: 2))
                    .focused($focused)
                    .submitLabel(.next)
                    .onSubmit { if canContinue { onNext() } }
            }
        } footer: {
            Button("המשך", action: onNext)
                .buttonStyle(PrimaryButtonStyle(enabled: canContinue))
                .disabled(!canContinue)
        }
        .onAppear { focused = true }
    }

    private var canContinue: Bool { !model.userName.trimmingCharacters(in: .whitespaces).isEmpty }
}

struct QuestionView: View {
    @EnvironmentObject var model: AppModel
    let question: QuizQuestion
    var onNext: () -> Void
    @State private var advancing = false

    var body: some View {
        OnboardingPage {
            VStack(alignment: .leading, spacing: 24) {
                StepHeader(title: question.title, subtitle: question.subtitle)
                VStack(spacing: 12) {
                    ForEach(question.options) { option in
                        let selected = model.quiz.answers[question.id]?.contains(option.id) ?? false
                        Button {
                            guard !advancing else { return }
                            hapticTap()
                            model.quiz.toggle(option, in: question)
                            if !question.multiSelect {
                                advancing = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { onNext() }
                            }
                        } label: {
                            SelectableRow(emoji: option.emoji, text: option.text,
                                          selected: selected, multi: question.multiSelect)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        } footer: {
            if question.multiSelect {
                let ok = model.quiz.isAnswered(question)
                Button("המשך", action: onNext)
                    .buttonStyle(PrimaryButtonStyle(enabled: ok))
                    .disabled(!ok)
            }
        }
    }
}

struct CalculatingView: View {
    var onDone: () -> Void
    @State private var progress = 0.0
    @State private var messageIndex = 0

    private let messages = [
        "מנתח את הרגלי הגלילה שלך…",
        "משווה לאלפי משתמשים…",
        "מחשב את ציון ה-Brain Rot…",
        "בונה לך תוכנית אישית…",
    ]
    private let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 36) {
            Spacer()
            ZStack {
                Circle().stroke(Color.white.opacity(0.08), lineWidth: 14)
                Circle().trim(from: 0, to: progress)
                    .stroke(Theme.gradient, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 44, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()
            }
            .frame(width: 200, height: 200)

            Text(messages[messageIndex])
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white.opacity(0.75))
                .id(messageIndex)
                .transition(.opacity)
            Spacer()
        }
        .padding(24)
        .onReceive(timer) { _ in
            guard progress < 1 else { return }
            progress = min(1, progress + 0.012)
            let idx = min(messages.count - 1, Int(progress * Double(messages.count)))
            if idx != messageIndex { withAnimation { messageIndex = idx } }
            if progress >= 1 {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: onDone)
            }
        }
    }
}

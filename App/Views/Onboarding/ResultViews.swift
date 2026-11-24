import SwiftUI

struct ResultsView: View {
    @EnvironmentObject var model: AppModel
    var onNext: () -> Void

    var body: some View {
        let r = model.quizResult ?? model.quiz.result
        OnboardingPage {
            VStack(spacing: 28) {
                Text("\(model.userName), here's your Brain Rot score")
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)

                ScoreRing(score: r.score)

                VStack(spacing: 8) {
                    Text(r.verdict.title)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.scoreColor(r.score))
                    Text(r.verdict.detail)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.7))
                }

                Card {
                    VStack(alignment: .leading, spacing: 14) {
                        compareRow(label: "Your score", value: r.score, color: Theme.scoreColor(r.score))
                        compareRow(label: "Average", value: 42, color: .white.opacity(0.4))
                        compareRow(label: "Healthy target", value: 20, color: Theme.neon)
                    }
                }

                if !r.impacts.isEmpty {
                    Card {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Where it's hurting you").font(.headline).foregroundStyle(.white)
                            FlowTags(tags: r.impacts)
                        }
                    }
                }
            }
        } footer: {
            Button("What does this mean for me?", action: onNext).buttonStyle(PrimaryButtonStyle())
        }
    }

    private func compareRow(label: String, value: Int, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label).font(.subheadline.weight(.semibold)).foregroundStyle(.white.opacity(0.8))
                Spacer()
                Text("\(value)").font(.subheadline.monospacedDigit().weight(.bold)).foregroundStyle(color)
            }
            GeometryReader { geo in
                Capsule().fill(Color.white.opacity(0.08))
                    .overlay(alignment: .leading) {
                        Capsule().fill(color).frame(width: geo.size.width * CGFloat(value) / 100)
                    }
            }
            .frame(height: 8)
        }
    }
}

struct FlowTags: View {
    var tags: [String]
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 8)], alignment: .leading, spacing: 8) {
            ForEach(tags, id: \.self) { tag in
                Text(tag)
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(Capsule().fill(Theme.danger.opacity(0.18)))
                    .foregroundStyle(Theme.danger)
            }
        }
    }
}

struct ProjectionView: View {
    @EnvironmentObject var model: AppModel
    var onNext: () -> Void
    @State private var appear = false

    var body: some View {
        let r = model.quizResult ?? model.quiz.result
        OnboardingPage {
            VStack(alignment: .leading, spacing: 26) {
                StepHeader(title: "At your current pace…",
                           subtitle: "\(formatMinutes(r.currentMinutes)) a day sounds small. At \(r.age), here's the full picture.")

                Card {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("You'll spend").foregroundStyle(.white.opacity(0.7))
                        Text("\(String(format: "%.1f", r.yearsOnPhone)) years")
                            .font(.system(size: 52, weight: .black, design: .rounded))
                            .foregroundStyle(Theme.danger)
                        Text("of the rest of your life on your phone. That's \(Int(r.dailyHours * 365)) hours every year.")
                            .font(.subheadline).foregroundStyle(.white.opacity(0.6))
                    }
                }
                .opacity(appear ? 1 : 0).offset(y: appear ? 0 : 20)

                Card {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("With Rewire you'll get back").foregroundStyle(.white.opacity(0.7))
                        Text("\(String(format: "%.1f", r.yearsRegained)) years")
                            .font(.system(size: 52, weight: .black, design: .rounded))
                            .foregroundStyle(Theme.neon)
                        Text("Just by going from \(formatMinutes(r.currentMinutes)) to \(formatMinutes(r.goalMinutes ?? r.currentMinutes)) a day.")
                            .font(.subheadline).foregroundStyle(.white.opacity(0.6))
                    }
                }
                .opacity(appear ? 1 : 0).offset(y: appear ? 0 : 20)
                .animation(.easeOut(duration: 0.6).delay(0.5), value: appear)

                VStack(alignment: .leading, spacing: 12) {
                    Text("What you could do with that time:").font(.headline).foregroundStyle(.white)
                    benefit("📚", "Read \(Int(r.goalHoursSaved * 365 / 6)) books a year")
                    benefit("🏃", "Work out \(Int(r.goalHoursSaved * 365)) hours a year")
                    benefit("🌍", "Learn a new language within a year")
                    benefit("😴", "Sleep better from the very first week")
                }
                .opacity(appear ? 1 : 0)
                .animation(.easeOut(duration: 0.6).delay(0.9), value: appear)
            }
        } footer: {
            Button("I want my time back", action: onNext).buttonStyle(PrimaryButtonStyle())
        }
        .onAppear { withAnimation(.easeOut(duration: 0.6)) { appear = true } }
    }

    private func benefit(_ emoji: String, _ text: String) -> some View {
        HStack(spacing: 12) {
            Text(emoji).font(.title2)
            Text(text).foregroundStyle(.white.opacity(0.85))
        }
    }
}

struct HowItWorksView: View {
    var onNext: () -> Void

    var body: some View {
        OnboardingPage {
            VStack(alignment: .leading, spacing: 24) {
                StepHeader(title: "How Rewire works", subtitle: "A few simple steps to take back control")
                step("lock.shield.fill", "Pick your apps", "TikTok, Instagram, games – whatever steals your time.")
                step("hourglass", "Set your rules", "A daily limit, scheduled block times and focus sessions.")
                step("hand.raised.fill", "Rewire blocks", "When time's up, a block screen appears. To open it you have to pause and breathe.")
                step("flame.fill", "Build a streak", "Every day you stay under your limit adds to your streak.")
            }
        } footer: {
            Button("Got it, let's go", action: onNext).buttonStyle(PrimaryButtonStyle())
        }
    }

    private func step(_ icon: String, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 14).fill(Theme.accent.opacity(0.2)).frame(width: 52, height: 52)
                Image(systemName: icon).font(.title2).foregroundStyle(Theme.accent)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline).foregroundStyle(.white)
                Text(detail).font(.subheadline).foregroundStyle(.white.opacity(0.65))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

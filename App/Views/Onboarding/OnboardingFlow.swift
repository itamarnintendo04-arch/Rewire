import SwiftUI

enum OnboardingStep: Hashable {
    case welcome
    case profile
    case quiz(Int)
    case calculating
    case results
    case projection
    case howItWorks
    case permission
    case selectApps
    case dailyLimit
    case schedule
    case commitment
}

struct OnboardingFlow: View {
    @EnvironmentObject var model: AppModel
    @State private var step: OnboardingStep = .welcome
    @State private var history: [OnboardingStep] = []

    private var quizCount: Int { QuizBank.questions.count }

    var body: some View {
        VStack(spacing: 0) {
            if showsTopBar {
                topBar.padding(.horizontal, 20).padding(.top, 8)
            }
            content
                .id(step)
                .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                        removal: .move(edge: .leading).combined(with: .opacity)))
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: step)
    }

    private var showsTopBar: Bool {
        switch step {
        case .welcome, .calculating: return false
        default: return true
        }
    }

    private var progress: Double {
        let order: [OnboardingStep] = [.profile] + (0..<quizCount).map { .quiz($0) } +
            [.results, .projection, .howItWorks, .permission, .selectApps, .dailyLimit, .schedule, .commitment]
        guard let i = order.firstIndex(of: step) else { return 0 }
        return Double(i + 1) / Double(order.count)
    }

    private var topBar: some View {
        HStack(spacing: 14) {
            Button {
                back()
            } label: {
                Image(systemName: "chevron.backward")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white.opacity(history.isEmpty ? 0.2 : 0.8))
                    .frame(width: 36, height: 36)
            }
            .disabled(history.isEmpty)
            ProgressBar(progress: progress)
        }
    }

    @ViewBuilder private var content: some View {
        switch step {
        case .welcome:
            WelcomeView { go(.profile) }
        case .profile:
            ProfileView { go(.quiz(0)) }
        case .quiz(let i):
            let question = QuizBank.questions[i]
            let next: () -> Void = {
                if i + 1 < quizCount { go(.quiz(i + 1)) } else { model.finishQuiz(); go(.calculating) }
            }
            switch question.kind {
            case .screenTime:
                ScreenTimeInputView(question: question, onNext: next)
            case .goal:
                GoalInputView(question: question, onNext: next)
            default:
                QuestionView(question: question, onNext: next)
            }
        case .calculating:
            CalculatingView { go(.results, remember: false) }
        case .results:
            ResultsView { go(.projection) }
        case .projection:
            ProjectionView { go(.howItWorks) }
        case .howItWorks:
            HowItWorksView { go(.permission) }
        case .permission:
            PermissionView { go(.selectApps) }
        case .selectApps:
            SelectAppsView { go(.dailyLimit) }
        case .dailyLimit:
            DailyLimitSetupView { go(.schedule) }
        case .schedule:
            ScheduleSetupView { go(.commitment) }
        case .commitment:
            CommitmentView { model.completeOnboarding() }
        }
    }

    private func go(_ next: OnboardingStep, remember: Bool = true) {
        hapticTap()
        if remember, step != .calculating { history.append(step) }
        step = next
    }

    private func back() {
        guard let prev = history.popLast() else { return }
        step = prev == .calculating ? .results : prev
    }
}

// MARK: - Shared layout for onboarding pages

struct OnboardingPage<Content: View, Footer: View>: View {
    @ViewBuilder var content: Content
    @ViewBuilder var footer: Footer

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                content
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 24)
            }
            footer
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
        }
    }
}

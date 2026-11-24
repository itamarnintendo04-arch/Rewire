import Foundation

struct QuizOption: Identifiable, Hashable {
    let id: String
    let emoji: String
    let text: String
    var score: Int = 0
}

struct QuizQuestion: Identifiable {
    enum Kind { case screenTime, goal, apps, impacts, generic }

    let id: String
    let kind: Kind
    let title: String
    var subtitle: String? = nil
    let options: [QuizOption]
    var multiSelect: Bool = false
    /// Max score that a multi-select question can contribute.
    var multiCap: Int = 10

    var maxScore: Int {
        switch kind {
        case .screenTime: return 30
        case .goal: return 0
        default: return multiSelect ? multiCap : (options.map(\.score).max() ?? 0)
        }
    }

    /// Questions answered with a slider instead of options.
    var isInput: Bool { kind == .screenTime || kind == .goal }
}

enum QuizBank {
    static let questions: [QuizQuestion] = [
        QuizQuestion(id: "screen", kind: .screenTime, title: "What's your daily screen time right now?",
                     subtitle: "Not sure? Settings → Screen Time → See All Activity",
                     options: []),
        QuizQuestion(id: "morning", kind: .generic, title: "What's the first thing you do when you wake up?",
                     options: [
                        .init(id: "m1", emoji: "📱", text: "Check my phone", score: 10),
                        .init(id: "m2", emoji: "🤷", text: "Depends on the day", score: 5),
                        .init(id: "m3", emoji: "☀️", text: "Get up and start my day", score: 0),
                     ]),
        QuizQuestion(id: "pickups", kind: .generic, title: "How often do you pick up your phone for no reason?",
                     options: [
                        .init(id: "p1", emoji: "🔁", text: "All the time, it's automatic", score: 10),
                        .init(id: "p2", emoji: "🤏", text: "A few times a day", score: 5),
                        .init(id: "p3", emoji: "🧘", text: "Almost never", score: 0),
                     ]),
        QuizQuestion(id: "night", kind: .generic, title: "Do you scroll in bed before sleep?",
                     options: [
                        .init(id: "n1", emoji: "🌚", text: "Every night", score: 10),
                        .init(id: "n2", emoji: "🌗", text: "Sometimes", score: 5),
                        .init(id: "n3", emoji: "😴", text: "Never", score: 0),
                     ]),
        QuizQuestion(id: "lost", kind: .generic, title: "Do you lose track of time while scrolling?",
                     options: [
                        .init(id: "l1", emoji: "🕳️", text: "Yes, all the time", score: 10),
                        .init(id: "l2", emoji: "⏳", text: "Now and then", score: 5),
                        .init(id: "l3", emoji: "⌚", text: "Not really", score: 0),
                     ]),
        QuizQuestion(id: "anxiety", kind: .generic, title: "How do you feel when your phone isn't with you?",
                     options: [
                        .init(id: "x1", emoji: "😰", text: "Anxious and restless", score: 10),
                        .init(id: "x2", emoji: "😕", text: "A bit uncomfortable", score: 5),
                        .init(id: "x3", emoji: "😌", text: "Totally calm", score: 0),
                     ]),
        QuizQuestion(id: "apps", kind: .apps, title: "Which apps steal the most of your time?",
                     subtitle: "Pick as many as you like",
                     options: [
                        .init(id: "tiktok", emoji: "🎵", text: "TikTok", score: 3),
                        .init(id: "instagram", emoji: "📸", text: "Instagram", score: 3),
                        .init(id: "youtube", emoji: "▶️", text: "YouTube", score: 2),
                        .init(id: "snapchat", emoji: "👻", text: "Snapchat", score: 2),
                        .init(id: "x", emoji: "🐦", text: "X / Twitter", score: 2),
                        .init(id: "whatsapp", emoji: "💬", text: "WhatsApp", score: 1),
                        .init(id: "games", emoji: "🎮", text: "Games", score: 2),
                        .init(id: "streaming", emoji: "🍿", text: "Netflix / streaming", score: 2),
                     ],
                     multiSelect: true, multiCap: 10),
        QuizQuestion(id: "impacts", kind: .impacts, title: "What is screen time hurting for you?",
                     subtitle: "Pick as many as you like",
                     options: [
                        .init(id: "focus", emoji: "🎯", text: "Focus", score: 2),
                        .init(id: "sleep", emoji: "🛌", text: "Sleep", score: 2),
                        .init(id: "mood", emoji: "🌧️", text: "Mood", score: 2),
                        .init(id: "relationships", emoji: "❤️", text: "Relationships", score: 2),
                        .init(id: "work", emoji: "📚", text: "School / work", score: 2),
                        .init(id: "confidence", emoji: "🪞", text: "Self-confidence", score: 2),
                     ],
                     multiSelect: true, multiCap: 10),
        QuizQuestion(id: "goal", kind: .goal, title: "What's your goal?",
                     subtitle: "How much daily screen time would you like to have?",
                     options: []),
    ]
}

/// Answers + scoring.
struct QuizState {
    var answers: [String: Set<String>] = [:]

    /// Age entered on the profile screen.
    var age: Int = 18

    /// Current average daily screen time, in minutes.
    var currentMinutes: Int = 240 {
        didSet { if goalMinutes >= currentMinutes { goalMinutes = Self.defaultGoal(for: currentMinutes) } }
    }
    /// Target daily screen time, in minutes.
    var goalMinutes: Int = 120

    static func defaultGoal(for current: Int) -> Int {
        max(15, (current / 2) / 15 * 15)
    }

    func isAnswered(_ q: QuizQuestion) -> Bool {
        q.isInput || !(answers[q.id]?.isEmpty ?? true)
    }

    mutating func toggle(_ option: QuizOption, in q: QuizQuestion) {
        var set = answers[q.id] ?? []
        if q.multiSelect {
            if set.contains(option.id) { set.remove(option.id) } else { set.insert(option.id) }
        } else {
            set = [option.id]
        }
        answers[q.id] = set
    }

    private func selected(_ kind: QuizQuestion.Kind) -> [QuizOption] {
        guard let q = QuizBank.questions.first(where: { $0.kind == kind }) else { return [] }
        let ids = answers[q.id] ?? []
        return q.options.filter { ids.contains($0.id) }
    }

    var score: Int {
        var total = 0, max = 0
        for q in QuizBank.questions {
            max += q.maxScore
            if q.kind == .screenTime {
                total += Swift.min(30, Int(dailyHours / 9 * 30))
                continue
            }
            let ids = answers[q.id] ?? []
            let s = q.options.filter { ids.contains($0.id) }.map(\.score).reduce(0, +)
            total += Swift.min(s, q.maxScore)
        }
        guard max > 0 else { return 0 }
        return Int((Double(total) / Double(max) * 100).rounded())
    }

    var dailyHours: Double { Double(currentMinutes) / 60 }

    /// Hours per day the user wants to win back.
    var goalHours: Double { Double(max(0, currentMinutes - goalMinutes)) / 60 }

    var result: QuizResult {
        QuizResult(score: score,
                   dailyHours: dailyHours,
                   age: age,
                   goalHoursSaved: goalHours,
                   topApps: selected(.apps).map(\.text),
                   impacts: selected(.impacts).map(\.text),
                   goalMinutes: goalMinutes)
    }
}

extension QuizResult {
    var verdict: (title: String, detail: String) {
        switch score {
        case ..<30:
            return ("Healthy brain 🧠✨", "You're fairly in control, but it can always get stronger.")
        case 30..<55:
            return ("Early signs of Brain Rot 🫠", "Your phone is starting to take more than it gives.")
        case 55..<75:
            return ("Advanced Brain Rot 🧟", "Your habits are hurting your focus, sleep and mood.")
        default:
            return ("Brain emergency 🚨", "Your phone runs your day. Time to take back control.")
        }
    }
}

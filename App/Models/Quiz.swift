import Foundation

struct QuizOption: Identifiable, Hashable {
    let id: String
    let emoji: String
    let text: String
    var score: Int = 0
    /// Numeric meaning (hours / age / goal) for questions that feed calculations.
    var value: Double? = nil
}

struct QuizQuestion: Identifiable {
    enum Kind { case age, screenTime, goal, apps, impacts, generic }

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
        QuizQuestion(id: "age", kind: .age, title: "בן/בת כמה את/ה?",
                     subtitle: "זה עוזר לנו לחשב כמה זמן מהחיים הולך למסך",
                     options: [
                        .init(id: "a1", emoji: "🧒", text: "מתחת ל-18", value: 16),
                        .init(id: "a2", emoji: "🧑", text: "18–24", value: 21),
                        .init(id: "a3", emoji: "👩", text: "25–34", value: 30),
                        .init(id: "a4", emoji: "🧔", text: "35–44", value: 40),
                        .init(id: "a5", emoji: "🧓", text: "45 ומעלה", value: 50),
                     ]),
        QuizQuestion(id: "screen", kind: .screenTime, title: "כמה זמן מסך יש לך ביום כרגע?",
                     subtitle: "לא בטוח/ה? הגדרות ← זמן מסך ← ראה את כל הפעילות",
                     options: []),
        QuizQuestion(id: "morning", kind: .generic, title: "מה הדבר הראשון שאת/ה עושה כשאת/ה מתעורר/ת?",
                     options: [
                        .init(id: "m1", emoji: "📱", text: "בודק/ת את הטלפון", score: 10),
                        .init(id: "m2", emoji: "🤷", text: "תלוי ביום", score: 5),
                        .init(id: "m3", emoji: "☀️", text: "קם/ה ומתחיל/ה את היום", score: 0),
                     ]),
        QuizQuestion(id: "pickups", kind: .generic, title: "כמה פעמים את/ה מרים/ה את הטלפון בלי סיבה?",
                     options: [
                        .init(id: "p1", emoji: "🔁", text: "כל הזמן, זה אוטומטי", score: 10),
                        .init(id: "p2", emoji: "🤏", text: "כמה פעמים ביום", score: 5),
                        .init(id: "p3", emoji: "🧘", text: "כמעט אף פעם", score: 0),
                     ]),
        QuizQuestion(id: "night", kind: .generic, title: "את/ה גולל/ת במיטה לפני השינה?",
                     options: [
                        .init(id: "n1", emoji: "🌚", text: "כל לילה", score: 10),
                        .init(id: "n2", emoji: "🌗", text: "לפעמים", score: 5),
                        .init(id: "n3", emoji: "😴", text: "אף פעם", score: 0),
                     ]),
        QuizQuestion(id: "lost", kind: .generic, title: "קורה לך שאת/ה מאבד/ת תחושת זמן בזמן גלילה?",
                     options: [
                        .init(id: "l1", emoji: "🕳️", text: "כן, כל הזמן", score: 10),
                        .init(id: "l2", emoji: "⏳", text: "מדי פעם", score: 5),
                        .init(id: "l3", emoji: "⌚", text: "לא ממש", score: 0),
                     ]),
        QuizQuestion(id: "anxiety", kind: .generic, title: "איך את/ה מרגיש/ה כשהטלפון לא לידך?",
                     options: [
                        .init(id: "x1", emoji: "😰", text: "לחוץ/ה ולא שקט/ה", score: 10),
                        .init(id: "x2", emoji: "😕", text: "קצת לא בנוח", score: 5),
                        .init(id: "x3", emoji: "😌", text: "רגוע/ה לגמרי", score: 0),
                     ]),
        QuizQuestion(id: "apps", kind: .apps, title: "אילו אפליקציות גונבות לך הכי הרבה זמן?",
                     subtitle: "אפשר לבחור כמה",
                     options: [
                        .init(id: "tiktok", emoji: "🎵", text: "TikTok", score: 3),
                        .init(id: "instagram", emoji: "📸", text: "Instagram", score: 3),
                        .init(id: "youtube", emoji: "▶️", text: "YouTube", score: 2),
                        .init(id: "snapchat", emoji: "👻", text: "Snapchat", score: 2),
                        .init(id: "x", emoji: "🐦", text: "X / Twitter", score: 2),
                        .init(id: "whatsapp", emoji: "💬", text: "WhatsApp", score: 1),
                        .init(id: "games", emoji: "🎮", text: "משחקים", score: 2),
                        .init(id: "streaming", emoji: "🍿", text: "נטפליקס / סטרימינג", score: 2),
                     ],
                     multiSelect: true, multiCap: 10),
        QuizQuestion(id: "impacts", kind: .impacts, title: "במה זמן המסך פוגע לך?",
                     subtitle: "אפשר לבחור כמה",
                     options: [
                        .init(id: "focus", emoji: "🎯", text: "ריכוז", score: 2),
                        .init(id: "sleep", emoji: "🛌", text: "שינה", score: 2),
                        .init(id: "mood", emoji: "🌧️", text: "מצב רוח", score: 2),
                        .init(id: "relationships", emoji: "❤️", text: "קשרים ומערכות יחסים", score: 2),
                        .init(id: "work", emoji: "📚", text: "לימודים / עבודה", score: 2),
                        .init(id: "confidence", emoji: "🪞", text: "ביטחון עצמי", score: 2),
                     ],
                     multiSelect: true, multiCap: 10),
        QuizQuestion(id: "goal", kind: .goal, title: "מה היעד שלך?",
                     subtitle: "כמה זמן מסך ביום היית רוצה שיהיה לך?",
                     options: []),
    ]
}

/// Answers + scoring.
struct QuizState {
    var answers: [String: Set<String>] = [:]

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
    var age: Int { Int(selected(.age).first?.value ?? 25) }

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
            return ("מוח במצב טוב 🧠✨", "יש לך שליטה יחסית טובה, אבל תמיד אפשר לחזק אותה.")
        case 30..<55:
            return ("סימנים ראשונים של Brain Rot 🫠", "הטלפון מתחיל לקחת יותר ממה שהוא נותן.")
        case 55..<75:
            return ("Brain Rot מתקדם 🧟", "ההרגלים שלך פוגעים בריכוז, בשינה ובמצב הרוח.")
        default:
            return ("מצב חירום מוחי 🚨", "הטלפון שולט ביום שלך. הגיע הזמן לקחת שליטה בחזרה.")
        }
    }
}

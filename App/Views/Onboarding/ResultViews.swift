import SwiftUI

struct ResultsView: View {
    @EnvironmentObject var model: AppModel
    var onNext: () -> Void

    var body: some View {
        let r = model.quizResult ?? model.quiz.result
        OnboardingPage {
            VStack(spacing: 28) {
                Text("\(model.userName), זה ציון ה-Brain Rot שלך")
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
                        compareRow(label: "הציון שלך", value: r.score, color: Theme.scoreColor(r.score))
                        compareRow(label: "ממוצע", value: 42, color: .white.opacity(0.4))
                        compareRow(label: "מטרה בריאה", value: 20, color: Theme.neon)
                    }
                }

                if !r.impacts.isEmpty {
                    Card {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("איפה זה פוגע בך").font(.headline).foregroundStyle(.white)
                            FlowTags(tags: r.impacts)
                        }
                    }
                }
            }
        } footer: {
            Button("מה זה אומר עליי?", action: onNext).buttonStyle(PrimaryButtonStyle())
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
                StepHeader(title: "בקצב הנוכחי…",
                           subtitle: "\(formatMinutes(r.currentMinutes)) ביום נשמע מעט. בוא/י נראה את התמונה המלאה.")

                Card {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("תבלה/י בטלפון").foregroundStyle(.white.opacity(0.7))
                        Text("\(String(format: "%.1f", r.yearsOnPhone)) שנים")
                            .font(.system(size: 52, weight: .black, design: .rounded))
                            .foregroundStyle(Theme.danger)
                        Text("מתוך שארית החיים שלך. זה \(Int(r.dailyHours * 365)) שעות כל שנה.")
                            .font(.subheadline).foregroundStyle(.white.opacity(0.6))
                    }
                }
                .opacity(appear ? 1 : 0).offset(y: appear ? 0 : 20)

                Card {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("עם Rewire תחזיר/י לעצמך").foregroundStyle(.white.opacity(0.7))
                        Text("\(String(format: "%.1f", r.yearsRegained)) שנים")
                            .font(.system(size: 52, weight: .black, design: .rounded))
                            .foregroundStyle(Theme.neon)
                        Text("רק מלרדת מ-\(formatMinutes(r.currentMinutes)) ל-\(formatMinutes(r.goalMinutes ?? r.currentMinutes)) ביום.")
                            .font(.subheadline).foregroundStyle(.white.opacity(0.6))
                    }
                }
                .opacity(appear ? 1 : 0).offset(y: appear ? 0 : 20)
                .animation(.easeOut(duration: 0.6).delay(0.5), value: appear)

                VStack(alignment: .leading, spacing: 12) {
                    Text("מה אפשר לעשות עם הזמן הזה:").font(.headline).foregroundStyle(.white)
                    benefit("📚", "לקרוא \(Int(r.goalHoursSaved * 365 / 6)) ספרים בשנה")
                    benefit("🏃", "להתאמן \(Int(r.goalHoursSaved * 365 / 1)) שעות בשנה")
                    benefit("🌍", "ללמוד שפה חדשה תוך שנה")
                    benefit("😴", "לישון טוב יותר כבר מהשבוע הראשון")
                }
                .opacity(appear ? 1 : 0)
                .animation(.easeOut(duration: 0.6).delay(0.9), value: appear)
            }
        } footer: {
            Button("אני רוצה את הזמן שלי בחזרה", action: onNext).buttonStyle(PrimaryButtonStyle())
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
                StepHeader(title: "איך Rewire עובד", subtitle: "שלושה צעדים פשוטים לשליטה מחדש")
                step(1, "lock.shield.fill", "בוחרים אפליקציות", "TikTok, אינסטגרם, משחקים – מה שגונב לך זמן.")
                step(2, "hourglass", "קובעים חוקים", "מגבלה יומית, זמני חסימה קבועים וסשנים של פוקוס.")
                step(3, "hand.raised.fill", "Rewire חוסם", "כשנגמר הזמן מופיע מסך חסימה. כדי לפתוח צריך לעצור ולנשום.")
                step(4, "flame.fill", "בונים רצף", "כל יום בלי לחרוג מהמגבלה מוסיף לרצף שלך.")
            }
        } footer: {
            Button("הבנתי, בוא/י נמשיך", action: onNext).buttonStyle(PrimaryButtonStyle())
        }
    }

    private func step(_ n: Int, _ icon: String, _ title: String, _ detail: String) -> some View {
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

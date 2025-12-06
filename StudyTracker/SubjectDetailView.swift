import SwiftUI
import SwiftData
import Charts

struct SubjectDetailView: View {
    @Bindable var subject: Subject
    
    @State private var selectedMetric: Metric = .time
    
    enum Metric {
        case time, question
    }
    
    var timeBreakdown: [(topic: String, value: Int)] {
        var dict: [String: Int] = [:]
        for log in subject.logs {
            dict[log.topic ?? t("general_work"), default: 0] += log.durationMinutes
        }
        return dict.map { ($0.key, $0.value) }.sorted { $0.value > $1.value }
    }
    
    var questionBreakdown: [(topic: String, value: Int)] {
        var dict: [String: Int] = [:]
        for log in subject.logs {
            if let q = log.questionCount, q > 0 {
                dict[log.topic ?? t("general_work"), default: 0] += q
            }
        }
        return dict.map { ($0.key, $0.value) }.sorted { $0.value > $1.value }
    }
    
    var currentBreakdown: [(topic: String, value: Int)] {
        return selectedMetric == .time ? timeBreakdown : questionBreakdown
    }
    
    var totalQuestionsSolved: Int { subject.logs.compactMap { $0.questionCount }.reduce(0, +) }
    var totalDuration: Int { subject.logs.reduce(0) { $0 + $1.durationMinutes } }
    
    // SÜRE HEDEFİ İLERLEMESİ
    var todayProgressTime: (current: Int, goal: Int) {
        let today = Calendar.current.startOfDay(for: Date())
        let todayMinutes = subject.logs
            .filter { Calendar.current.isDate($0.date, inSameDayAs: today) }
            .reduce(0) { $0 + $1.durationMinutes }
        return (todayMinutes, subject.dailyGoal)
    }
    
    // SORU HEDEFİ İLERLEMESİ
    var todayProgressQuestion: (current: Int, goal: Int) {
        let today = Calendar.current.startOfDay(for: Date())
        let todayQuestions = subject.logs
            .filter { Calendar.current.isDate($0.date, inSameDayAs: today) }
            .compactMap { $0.questionCount }
            .reduce(0, +)
        return (todayQuestions, subject.dailyGoalQuestion)
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 25) {
                    // ÜST BİLGİ KARTI
                    VStack(spacing: 15) {
                        Image(systemName: "book.fill")
                            .font(.system(size: 50))
                            .foregroundColor(subject.colorHex.toColor)
                            .padding()
                            .background(subject.colorHex.toColor.opacity(0.1))
                            .clipShape(Circle())
                        
                        Text(subject.name)
                            .font(.largeTitle).bold()
                            .foregroundColor(.white)
                        
                        HStack(spacing: 20) {
                            VStack {
                                Text("\(totalQuestionsSolved)")
                                    .font(.title2).bold().foregroundColor(.white)
                                Text(t("questions_solved")).font(.caption).foregroundColor(.gray)
                            }
                            Divider().frame(height: 30).background(Color.gray)
                            VStack {
                                Text(formatDuration(totalDuration))
                                    .font(.title2).bold().foregroundColor(.white)
                                Text(t("total_duration")).font(.caption).foregroundColor(.gray)
                            }
                        }
                        .padding()
                        .background(Color(white: 0.1))
                        .cornerRadius(15)
                    }
                    .padding(.top)
                    
                    // GÜNLÜK HEDEF KARTLARI
                    // Eğer Süre Hedefi Varsa Göster
                    if todayProgressTime.goal > 0 {
                        GoalProgressCard(
                            title: t("daily_goal_title"),
                            current: todayProgressTime.current,
                            goal: todayProgressTime.goal,
                            unit: t("unit_min"),
                            color: subject.colorHex.toColor
                        )
                    }
                    
                    // Eğer Soru Hedefi Varsa Göster
                    if todayProgressQuestion.goal > 0 {
                        GoalProgressCard(
                            title: t("daily_goal_q_title"),
                            current: todayProgressQuestion.current,
                            goal: todayProgressQuestion.goal,
                            unit: t("unit_question"),
                            color: .cyan // Soru hedefleri farklı renk olsun
                        )
                    }
                    
                    // KONU DAĞILIMI
                    if !timeBreakdown.isEmpty || !questionBreakdown.isEmpty {
                        VStack(alignment: .leading, spacing: 15) {
                            HStack {
                                // "KONU DAĞILIMI (SORU)" metni lokalizasyon ile değiştirildi
                                Label(selectedMetric == .time ? t("topic_dist_time") : t("topic_dist_question"), systemImage: "piechart")
                                    .font(.caption).bold().foregroundColor(.gray)
                                Spacer()
                                Picker("Metrik", selection: $selectedMetric) {
                                    Text(t("type_time")).tag(Metric.time)
                                    Text(t("type_question")).tag(Metric.question)
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 150)
                                .colorScheme(.dark)
                            }
                            
                            if currentBreakdown.isEmpty {
                                Text(t("no_data")).foregroundColor(.gray).frame(height: 100).frame(maxWidth: .infinity)
                            } else {
                                Chart(currentBreakdown, id: \.topic) { item in
                                    SectorMark(
                                        angle: .value("Değer", item.value),
                                        innerRadius: .ratio(0.6),
                                        angularInset: 1.5
                                    )
                                    .foregroundStyle(by: .value("Konu", item.topic))
                                    .cornerRadius(5)
                                }
                                .frame(height: 200)
                                
                                ForEach(currentBreakdown, id: \.topic) { item in
                                    HStack {
                                        Circle().fill(subject.colorHex.toColor.opacity(0.8)).frame(width: 8, height: 8)
                                        Text(item.topic).foregroundColor(.white)
                                        Spacer()
                                        Text("\(item.value) \(selectedMetric == .time ? t("unit_min") : t("unit_question"))").foregroundColor(.gray)
                                    }
                                    .padding(.vertical, 4)
                                    Divider().background(Color(white: 0.15))
                                }
                            }
                        }
                        .padding().background(Color(white: 0.1)).cornerRadius(20).padding(.horizontal)
                    }
                    
                    // SON KAYITLAR
                    VStack(alignment: .leading, spacing: 15) {
                        Label(t("recent_logs"), systemImage: "list.bullet")
                            .font(.caption).bold().foregroundColor(.gray)
                        
                        ForEach(subject.logs.sorted(by: { $0.date > $1.date }).prefix(20)) { log in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(log.topic ?? t("general_work")).font(.headline).foregroundColor(.white)
                                    Text(log.date.formatted(date: .abbreviated, time: .shortened)).font(.caption).foregroundColor(.gray)
                                }
                                Spacer()
                                if let questions = log.questionCount, questions > 0 {
                                    Text("\(questions) \(t("unit_question"))").font(.subheadline).bold().foregroundColor(.cyan)
                                } else {
                                    Text("\(log.durationMinutes) \(t("unit_min"))").font(.subheadline).bold().foregroundColor(subject.colorHex.toColor)
                                }
                            }
                            .padding().background(Color(white: 0.12)).cornerRadius(12)
                        }
                    }
                    .padding().background(Color(white: 0.1)).cornerRadius(20).padding(.horizontal).padding(.bottom, 50)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    func formatDuration(_ minutes: Int) -> String {
        return String(format: "%.1f \(t("unit_hour"))", Double(minutes) / 60.0)
    }
}

// YENİ: Tekrar kullanılabilir hedef kartı bileşeni
struct GoalProgressCard: View {
    let title: String
    let current: Int
    let goal: Int
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 15) {
            Text(title).font(.headline).bold().foregroundColor(.gray)
            HStack {
                ZStack {
                    Circle().stroke(Color.gray.opacity(0.2), lineWidth: 10)
                    Circle()
                        .trim(from: 0.0, to: min(Double(current) / Double(goal), 1.0))
                        .stroke(style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round))
                        .foregroundColor(color)
                        .rotationEffect(Angle(degrees: 270.0))
                        .animation(.spring(), value: current)
                }
                .frame(width: 80, height: 80)
                .padding(.trailing, 10)
                
                VStack(alignment: .leading, spacing: 5) {
                    Text("\(current) / \(goal) \(unit)").font(.title2).bold().foregroundColor(.white)
                    if current >= goal {
                        Text(t("goal_completed")).font(.caption).bold().foregroundColor(.green)
                    } else {
                        // DÜZELTME: Kalan miktar birimi, kartın birimi (unit) olarak ayarlandı.
                        Text("\(goal - current) \(unit) \(t("goal_remaining"))").font(.caption).foregroundColor(.gray)
                    }
                }
                Spacer()
            }
        }
        .padding().background(Color(white: 0.1)).cornerRadius(20).padding(.horizontal)
    }
}

import SwiftUI
import SwiftData

struct AddLogView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var context
    
    var preSelectedSubject: Subject
    
    // Hedef tamamlandığında tetiklenecek fonksiyon
    var onGoalReached: (() -> Void)?
    
    @State private var date = Date()
    @State private var topic: String = ""
    @FocusState private var isTopicFocused: Bool
    @State private var logType: LogType = .time
    @State private var duration: Int = 30
    @State private var questionCount: Int = 0
    
    enum LogType: String, CaseIterable { case time, question }
    
    // GÜNCELLENDİ: Daha fazla seçenek eklendi
    let quickTimes = [15, 30, 45, 60, 90, 120, 150, 180]
    let quickQuestions = [10, 20, 50, 100, 150, 200, 250, 300, 500]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 30) {
                            
                            // SEÇİLEN DERSİ GÖSTEREN BAŞLIK
                            HStack {
                                Circle()
                                    .fill(preSelectedSubject.colorHex.toColor)
                                    .frame(width: 15, height: 15)
                                Text(preSelectedSubject.name)
                                    .font(.title2).bold()
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding()
                            .background(Color(white: 0.1))
                            .cornerRadius(15)
                            
                            VStack(alignment: .leading, spacing: 10) {
                                Text(t("subtopic")).font(.caption).bold().foregroundColor(.gray)
                                TextField(t("subtopic_ph"), text: $topic)
                                    .padding().background(Color(white: 0.15)).cornerRadius(12).foregroundColor(.white).focused($isTopicFocused)
                                
                                if !preSelectedSubject.knownTopics.isEmpty {
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack {
                                            ForEach(preSelectedSubject.knownTopics, id: \.self) { knownTopic in
                                                Button(action: { topic = knownTopic }) {
                                                    Text(knownTopic).font(.caption).bold().padding(.horizontal, 12).padding(.vertical, 6)
                                                        .background(topic == knownTopic ? preSelectedSubject.colorHex.toColor : Color(white: 0.15))
                                                        .foregroundColor(topic == knownTopic ? .white : .gray).cornerRadius(8)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            
                            Picker("Tip", selection: $logType) {
                                ForEach(LogType.allCases, id: \.self) { type in
                                    Text(type == .time ? t("type_time") : t("type_question")).tag(type)
                                }
                            }
                            .pickerStyle(.segmented).colorScheme(.dark)
                            
                            VStack(alignment: .leading, spacing: 10) {
                                Text(logType == .time ? t("duration_label") : t("question_label")).font(.caption).bold().foregroundColor(.gray)
                                
                                // Manuel Arttırma/Azaltma
                                HStack {
                                    Button(action: decreaseValue) { Image(systemName: "minus.circle.fill").font(.largeTitle).foregroundColor(.gray) }
                                    Text("\(logType == .time ? duration : questionCount)").font(.system(size: 54, weight: .bold, design: .rounded)).foregroundColor(.white).frame(width: 140).contentTransition(.numericText())
                                    Button(action: increaseValue) { Image(systemName: "plus.circle.fill").font(.largeTitle).foregroundColor(preSelectedSubject.colorHex.toColor) }
                                }
                                .frame(maxWidth: .infinity)
                                
                                // GÜNCELLENDİ: Yatay Kaydırılabilir Hızlı Seçim Butonları
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(logType == .time ? quickTimes : quickQuestions, id: \.self) { val in
                                            Button(action: {
                                                if logType == .time { duration = val } else { questionCount = val }
                                            }) {
                                                Text(logType == .time ? "\(val)\(t("unit_min"))" : "+\(val)")
                                                    .font(.subheadline).bold()
                                                    .padding(.vertical, 12)
                                                    .padding(.horizontal, 24) // Yatayda daha geniş butonlar
                                                    .background(Color(white: 0.15))
                                                    .foregroundColor(.gray)
                                                    .cornerRadius(12)
                                            }
                                        }
                                    }
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 10) {
                                Text(t("date_label")).font(.caption).bold().foregroundColor(.gray)
                                DatePicker("", selection: $date, in: ...Date(), displayedComponents: [.date]).datePickerStyle(.graphical).background(Color(white: 0.1)).cornerRadius(15).colorScheme(.dark)
                            }
                        }
                        .padding()
                    }
                    .scrollDismissesKeyboard(.immediately) // EKLENDİ: Klavye hemen kapansın
                }
            }
            .navigationTitle(t("add_log_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // SOL ÜST: Vazgeç
                ToolbarItem(placement: .cancellationAction) {
                    Button(t("cancel")) { dismiss() }
                        .foregroundColor(.white)
                }
                
                // SAĞ ÜST: Kaydet
                ToolbarItem(placement: .confirmationAction) {
                    Button(t("save")) { saveLog() }
                        .fontWeight(.bold)
                        .foregroundColor(preSelectedSubject.colorHex.toColor)
                }
            }
        }
    }
    
    func increaseValue() { if logType == .time { duration += 5 } else { questionCount += 5 } }
    func decreaseValue() { if logType == .time { if duration > 5 { duration -= 5 } } else { if questionCount > 5 { questionCount -= 5 } } }
    
    func saveLog() {
        let finalTopic = topic.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let newLog = StudyLog(
            durationMinutes: logType == .time ? duration : 0,
            date: date,
            topic: finalTopic.isEmpty ? nil : finalTopic,
            questionCount: logType == .question ? questionCount : nil
        )
        
        if !finalTopic.isEmpty && !preSelectedSubject.knownTopics.contains(finalTopic) {
            preSelectedSubject.knownTopics.append(finalTopic)
        }
        
        // --- HEDEF KONTROLÜ (KUTLAMA İÇİN) ---
        let today = Calendar.current.startOfDay(for: date)
        let isToday = Calendar.current.isDateInToday(date)
        
        if isToday {
            let todayLogs = preSelectedSubject.logs.filter { Calendar.current.isDate($0.date, inSameDayAs: today) }
            let prevMinutes = todayLogs.reduce(0) { $0 + $1.durationMinutes }
            let prevQuestions = todayLogs.compactMap { $0.questionCount }.reduce(0, +)
            
            // Yeni değerleri ekle
            let newMinutes = prevMinutes + newLog.durationMinutes
            let newQuestions = prevQuestions + (newLog.questionCount ?? 0)
            
            // Süre hedefi yeni mi geçildi?
            let timeGoalJustMet = preSelectedSubject.dailyGoal > 0 && prevMinutes < preSelectedSubject.dailyGoal && newMinutes >= preSelectedSubject.dailyGoal
            
            // Soru hedefi yeni mi geçildi?
            let questionGoalJustMet = preSelectedSubject.dailyGoalQuestion > 0 && prevQuestions < preSelectedSubject.dailyGoalQuestion && newQuestions >= preSelectedSubject.dailyGoalQuestion
            
            if timeGoalJustMet || questionGoalJustMet {
                onGoalReached?()
            }
        }
        
        preSelectedSubject.addLog(newLog)
        dismiss()
    }
}

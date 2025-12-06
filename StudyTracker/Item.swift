import Foundation
import SwiftData
import SwiftUI

// MARK: - Subject Model (CloudKit Uyumlu)
@Model
final class Subject {
    var id: UUID = UUID()
    var name: String = ""
    var colorHex: String = "purple"
    var reminderTime: Date? = nil
    var createdAt: Date = Date()
    var knownTopics: [String] = []
    var isArchived: Bool = false
    
    // HEDEFLER
    var dailyGoal: Int = 0 // Süre Hedefi (Dakika)
    var dailyGoalQuestion: Int = 0 // YENİ: Soru Hedefi (Adet)
    
    @Relationship(deleteRule: .cascade, inverse: \StudyLog.subject)
    var _logs: [StudyLog]? = []
    
    var logs: [StudyLog] {
        return _logs ?? []
    }
    
    // Init güncellendi
    init(name: String, colorHex: String, reminderTime: Date? = nil, isArchived: Bool = false, dailyGoal: Int = 0, dailyGoalQuestion: Int = 0) {
        self.id = UUID()
        self.name = name
        self.colorHex = colorHex
        self.reminderTime = reminderTime
        self.createdAt = Date()
        self.isArchived = isArchived
        self.dailyGoal = dailyGoal
        self.dailyGoalQuestion = dailyGoalQuestion
        self._logs = []
    }
    
    func addLog(_ log: StudyLog) {
        if _logs == nil { _logs = [] }
        _logs?.append(log)
    }
}

// MARK: - StudyLog Model
@Model
final class StudyLog {
    var durationMinutes: Int = 0
    var date: Date = Date()
    var topic: String? = nil
    var questionCount: Int? = nil
    
    var subject: Subject? = nil
    
    init(durationMinutes: Int, date: Date = Date(), topic: String? = nil, questionCount: Int? = nil) {
        self.durationMinutes = durationMinutes
        self.date = date
        self.topic = topic
        self.questionCount = questionCount
    }
}

// MARK: - Renk Yardımcısı
extension String {
    var toColor: Color {
        switch self {
        case "purple": return .purple
        case "blue": return .blue
        case "cyan": return .cyan
        case "teal": return .teal
        case "green": return .green
        case "yellow": return .yellow
        case "orange": return .orange
        case "red": return .red
        case "pink": return .pink
        case "indigo": return .indigo
        case "mint": return .mint
        case "lime": return Color(red: 0.75, green: 1.0, blue: 0.0)
        case "magenta": return Color(red: 1.0, green: 0.0, blue: 1.0)
        default: return .gray
        }
    }
}

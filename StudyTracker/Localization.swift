import Foundation

class Localization {
    static let shared = Localization()
    
    // Dil kontrolünü sadece bir kez yapıp hafızada tutuyoruz
    private let isTurkish: Bool
    
    // Sözlüğü fonksiyon içinden çıkarıp sınıfın bir parçası yaptık.
    // Böylece her çeviri isteğinde sözlük yeniden oluşturulmayacak.
    private let dict: [String: [String: String]] = [
        // --- GENEL ---
        "cancel": ["tr": "Vazgeç", "en": "Cancel"],
        "save": ["tr": "Kaydet", "en": "Save"],
        "close": ["tr": "Kapat", "en": "Close"],
        "delete": ["tr": "Sil", "en": "Delete"],
        "edit": ["tr": "Düzenle", "en": "Edit"],
        "archive": ["tr": "Arşivle", "en": "Archive"],
        "add": ["tr": "Ekle", "en": "Add"],
        "update": ["tr": "Güncelle", "en": "Update"],
        "done": ["tr": "Bitti", "en": "Done"],
        
        // --- AÇILIŞ EKRANI (SPLASH) ---
        "splash_slogan": ["tr": "Hedeflerine Odaklan", "en": "Focus on Your Goals"],
        
        // --- SEKME İSİMLERİ VE BAŞLIKLAR (TABS & TITLES) ---
        "app_name": ["tr": "STUDY TRACKER", "en": "STUDY TRACKER"],
        "studies": ["tr": "Çalışmalar", "en": "Studies"],
        "stats": ["tr": "İstatistikler", "en": "Statistics"],
        "my_subjects": ["tr": "Derslerim", "en": "My Subjects"],
        "analysis_title": ["tr": "Analiz", "en": "Analysis"],
        
        // --- BOŞ DURUM METİNLERİ (EMPTY STATES) ---
        "no_subjects": ["tr": "Henüz ders yok.", "en": "No subjects yet."],
        "add_first_subject": ["tr": "Sağ üstteki + butonuna basarak ekle.", "en": "Tap + on top right to add."],
        "no_subjects_studies": ["tr": "Henüz çalışma dersi yok.", "en": "No study subjects yet."],
        "add_subjects_to_start": ["tr": "Derslerim sekmesinden ders ekle.", "en": "Add subjects from My Subjects tab."],
        
        // --- İŞLEMLER ---
        "delete_subject": ["tr": "Dersi Sil", "en": "Delete Subject"],
        "archive_confirm": ["tr": "Bu dersi silmek istediğine emin misin?", "en": "Are you sure you want to delete this subject?"],
        "ad_space": ["tr": "REKLAM ALANI", "en": "AD SPACE"],
        
        // --- HEDEF BELİRLEME (GOALS) ---
        "set_daily_goal": ["tr": "Hedefleri Düzenle", "en": "Edit Goals"],
        "daily_goal_title": ["tr": "Günlük Hedef (Süre)", "en": "Daily Goal (Time)"],
        "daily_goal_q_title": ["tr": "Günlük Hedef (Soru)", "en": "Daily Goal (Question)"],
        "minutes_placeholder": ["tr": "Dakika (Örn: 60)", "en": "Minutes (e.g. 60)"],
        "questions_placeholder": ["tr": "Soru Sayısı (Örn: 50)", "en": "Questions (e.g. 50)"],
        "goal_prompt": ["tr": "Günlük hedeflerini belirle.", "en": "Set your daily goals."],
        "no_goals_set": ["tr": "Hedef belirlenmedi", "en": "No goals set"],
        
        // --- DERS YÖNETİMİ (ADD SUBJECT) ---
        "new_subject_title": ["tr": "YENİ DERS OLUŞTUR", "en": "CREATE NEW SUBJECT"],
        "edit_subject_title": ["tr": "DERSİ DÜZENLE", "en": "EDIT SUBJECT"],
        "subject_name_ph": ["tr": "Ders Adı (Örn: Matematik)", "en": "Subject Name (e.g. Math)"],
        "select_color": ["tr": "RENK SEÇ", "en": "SELECT COLOR"],
        "subtopics_title": ["tr": "ALT KONULAR", "en": "SUBTOPICS"],
        "add_topic_ph": ["tr": "Konu Ekle", "en": "Add Topic"],
        "existing_subjects": ["tr": "MEVCUT DERSLER", "en": "EXISTING SUBJECTS"],
        "no_subjects_added": ["tr": "Henüz ders eklenmemiş.", "en": "No subjects added yet."],
        "no_subtopic": ["tr": "Konu yok", "en": "No subtopics"],
        "manage_title": ["tr": "Ders Yönetimi", "en": "Manage Subjects"],
        
        // --- ÇALIŞMA EKLE (ADD LOG) ---
        "add_log_title": ["tr": "Çalışma Ekle", "en": "Log Session"],
        "warn_no_subject": ["tr": "Önce Ders Ekle", "en": "Add Subject First"],
        "warn_desc": ["tr": "Çalışma kaydetmek için önce ana sayfadan bir ders oluşturmalısın.", "en": "You need to create a subject from home screen first."],
        "select_subject": ["tr": "DERS SEÇ", "en": "SELECT SUBJECT"],
        "subtopic": ["tr": "ALT KONU", "en": "SUBTOPIC"],
        "subtopic_ph": ["tr": "Örn: Türev", "en": "e.g. Calculus"],
        "type_time": ["tr": "Süre", "en": "Time"],
        "type_question": ["tr": "Soru", "en": "Question"],
        "duration_label": ["tr": "SÜRE (DK)", "en": "DURATION (MIN)"],
        "question_label": ["tr": "SORU SAYISI", "en": "QUESTION COUNT"],
        "date_label": ["tr": "TARİH", "en": "DATE"],
        
        // --- ANALİZ (STATS) ---
        "period_week": ["tr": "Hafta", "en": "Week"],
        "period_month": ["tr": "Ay", "en": "Month"],
        "period_year": ["tr": "Yıl", "en": "Year"],
        "total_time": ["tr": "TOPLAM SÜRE", "en": "TOTAL TIME"],
        "total_questions": ["tr": "TOPLAM SORU", "en": "TOTAL QUESTIONS"],
        "top_focus": ["tr": "EN ÇOK ODAK", "en": "TOP FOCUS"],
        "activity_chart": ["tr": "AKTİVİTE", "en": "ACTIVITY"],
        "no_data": ["tr": "Veri yok.", "en": "No data."],
        "subject_dist": ["tr": "DERS DAĞILIMI", "en": "SUBJECT DISTRIBUTION"],
        "unit_hour": ["tr": "sa", "en": "h"],
        "unit_min": ["tr": "dk", "en": "m"],
        "unit_question": ["tr": "soru", "en": "q"],
        
        // --- DETAY (DETAIL) ---
        "questions_solved": ["tr": "Soru", "en": "Solved"],
        "sessions": ["tr": "Oturum", "en": "Sessions"],
        "total_duration": ["tr": "Süre", "en": "Time"],
        "topic_dist_time": ["tr": "KONU (SÜRE)", "en": "TOPICS (TIME)"],
        "topic_dist_question": ["tr": "KONU (SORU)", "en": "TOPICS (QUESTION)"],
        "recent_logs": ["tr": "SON KAYITLAR", "en": "RECENT LOGS"],
        "general_work": ["tr": "Genel Çalışma", "en": "General Study"],
        "goal_completed": ["tr": "Tamamlandı!", "en": "Completed!"],
        "goal_remaining": ["tr": "kaldı", "en": "left"],
        
        // --- KUTLAMA (CELEBRATION) ---
        "celebration_title": ["tr": "HEDEF TAMAMLANDI!", "en": "GOAL ACHIEVED!"],
        "celebration_message": ["tr": "Harika gidiyorsun, böyle devam et!", "en": "You're doing great, keep it up!"],
        
        // --- HATIRLATICI (REMINDER) ---
        "reminder_title": ["tr": "Hatırlatıcı Kur", "en": "Set Reminder"],
        "reminder_desc": ["tr": "%@ dersi için bildirim zamanı seç.", "en": "Select notification time for %@."],
        "reminder_set_btn": ["tr": "Hatırlatıcıyı Kur", "en": "Set Reminder"],
        "reminder_cancel_btn": ["tr": "Hatırlatıcıyı İptal Et", "en": "Cancel Reminder"],
        "reminder_select_time": ["tr": "Zaman Seç", "en": "Select Time"],
        
        // --- BİLDİRİM METNİ ---
        "notif_title": ["tr": "📚 Çalışma Vakti!", "en": "📚 Study Time!"],
        "notif_body": ["tr": "%@ dersi için çalışma zamanı! Hedefine bir adım daha yaklaş.", "en": "It's time to study %@! One step closer to your goal."],
        
        // --- KART (CARD) ---
        "total": ["tr": "Toplam", "en": "Total"],
        "short_hour": ["tr": "sa", "en": "h"],
        "short_q": ["tr": "s", "en": "q"]
    ]
    
    // Init sırasında dili belirle
    private init() {
        let langCode = Locale.preferredLanguages.first ?? "en"
        self.isTurkish = langCode.lowercased().hasPrefix("tr")
    }
    
    // Metin Sözlüğü Erişimi (Artık O(1) hızında çalışır)
    func t(_ key: String) -> String {
        return dict[key]?[isTurkish ? "tr" : "en"] ?? dict[key]?["en"] ?? key
    }
}

// Kullanımı kolaylaştırmak için kısa fonksiyon
func t(_ key: String) -> String {
    return Localization.shared.t(key)
}

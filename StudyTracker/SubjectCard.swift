import SwiftUI
import SwiftData

struct SubjectCard: View {
    let subject: Subject
    var onBellClick: () -> Void
    var onAddLogClick: () -> Void
    
    let columns = Array(repeating: GridItem(.flexible(), spacing: 3), count: 21)
    
    // OPTİMİZASYON 1: Tarihleri hesaplarken Calendar'ı her seferinde yeniden oluşturmamak için dışarı aldık
    // View her render olduğunda tekrar hesaplanmasın diye body içinde local değişken olarak kullanacağız
    var last105Days: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date()) // Saat farklarını sıfırla
        var dates: [Date] = []
        // Kapasiteyi baştan belirle (performans artışı)
        dates.reserveCapacity(105)
        
        for i in 0..<105 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                dates.append(date)
            }
        }
        return dates.reversed()
    }
    
    // OPTİMİZASYON 2: Isı haritası verisini O(N * 105) yerine O(N) karmaşıklığıyla hazırla.
    // Eski yöntemde her bir kutucuk (105 tane) için tüm logları (N) tekrar filtreliyordu.
    // Şimdi logları tek bir kez dönüp bir sözlüğe (Dictionary) kaydediyoruz.
    // Erişim hızı O(1) oluyor.
    var precalculatedDailyScores: [Date: Int] {
        let calendar = Calendar.current
        var scores: [Date: Int] = [:]
        
        for log in subject.logs {
            let day = calendar.startOfDay(for: log.date)
            let score = log.durationMinutes + (log.questionCount ?? 0)
            scores[day, default: 0] += score
        }
        return scores
    }
    
    var totalMinutes: Int { subject.logs.reduce(0) { $0 + $1.durationMinutes } }
    var totalQuestions: Int { subject.logs.compactMap { $0.questionCount }.reduce(0, +) }
    
    var body: some View {
        // Hesaplamaları View render edilmeden hemen önce bir kez yap
        let days = last105Days
        let dailyScores = precalculatedDailyScores
        
        VStack(alignment: .leading, spacing: 12) {
            // BAŞLIK VE İKONLAR
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(subject.colorHex.toColor.opacity(0.2))
                    Image(systemName: "clock")
                        .foregroundColor(subject.colorHex.toColor)
                }
                .frame(width: 44, height: 44)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(subject.colorHex.toColor.opacity(0.5), lineWidth: 1))
                
                VStack(alignment: .leading) {
                    Text(subject.name).font(.headline).foregroundColor(.white)
                    HStack(spacing: 5) {
                        Text("\(t("total")): \((Double(totalMinutes)/60.0), specifier: "%.1f") \(t("short_hour"))")
                        Text("•")
                        Text("\(totalQuestions) \(t("short_q"))")
                    }
                    .font(.caption).foregroundColor(.gray)
                }
                
                Spacer()
                
                // SAĞ TARAFTAKİ BUTONLAR
                HStack(spacing: 8) {
                    // Bildirim Butonu
                    Button(action: onBellClick) {
                        Image(systemName: subject.reminderTime != nil ? "bell.fill" : "bell.slash")
                            .foregroundColor(subject.reminderTime != nil ? .green : .gray)
                            .padding(8)
                            .background(Color(white: 0.15))
                            .clipShape(Circle())
                    }
                    .buttonStyle(BorderlessButtonStyle()) // ÖNEMLİ: List içinde çalışması için
                    
                    // Hızlı Ekleme Butonu (+)
                    Button(action: onAddLogClick) {
                        Image(systemName: "plus")
                            .foregroundColor(.white)
                            .padding(8)
                            .background(subject.colorHex.toColor) // Dersin renginde buton
                            .clipShape(Circle())
                            .shadow(color: subject.colorHex.toColor.opacity(0.5), radius: 5)
                    }
                    .buttonStyle(BorderlessButtonStyle()) // ÖNEMLİ: List içinde çalışması için
                }
            }
            
            // AKTİVİTE ISITMA HARİTASI (Heatmap)
            LazyVGrid(columns: columns, spacing: 3) {
                ForEach(days, id: \.self) { date in
                    // Artık burada ağır filtreleme işlemi yok, sadece sözlükten okuma var (Çok hızlı)
                    let score = dailyScores[date] ?? 0
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(getColorFor(score: score))
                        .aspectRatio(1, contentMode: .fit)
                }
            }
        }
        .padding(16)
        .background(Color(red: 0.07, green: 0.09, blue: 0.15))
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(white: 0.2), lineWidth: 1))
    }
    
    // Eski fonksiyon iptal edildi, yerine yukarıdaki sözlük yapısı kullanılıyor.
    // func getActivityScore(date: Date) -> Int { ... }
    
    func getColorFor(score: Int) -> Color {
        let baseColor = subject.colorHex.toColor
        if score == 0 { return Color(white: 0.15) }
        else if score < 15 { return baseColor.opacity(0.3) }
        else if score < 45 { return baseColor.opacity(0.5) }
        else if score < 90 { return baseColor.opacity(0.7) }
        else { return baseColor.opacity(1.0) }
    }
}

import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Query var subjects: [Subject]
    @State private var selectedPeriod: Period = .week
    @State private var selectedMetric: Metric = .time
    
    enum Metric: String, CaseIterable, Identifiable {
        case time, question
        var id: String { self.rawValue }
    }
    enum Period: String, CaseIterable, Identifiable {
        case week, month, year
        var id: String { self.rawValue }
        var color: Color {
            switch self {
            case .week: return .purple
            case .month: return .orange
            case .year: return .blue
            }
        }
        var localizedName: String {
            switch self {
            case .week: return t("period_week")
            case .month: return t("period_month")
            case .year: return t("period_year")
            }
        }
    }
    
    struct ChartSegment: Identifiable { let id = UUID(); let date: Date; let value: Int; let subjectName: String; let color: Color }
    
    var filteredData: (totalValue: Int, topSubject: Subject?, chartSegments: [ChartSegment]) {
        let calendar = Calendar.current; let now = Date(); var totalVal = 0; var subjectTotals: [UUID: Int] = [:]
        var dateRange: [Date] = []
        switch selectedPeriod {
        case .week: for i in 0..<7 { if let date = calendar.date(byAdding: .day, value: -i, to: now) { dateRange.append(calendar.startOfDay(for: date)) } }
        case .month: for i in 0..<30 { if let date = calendar.date(byAdding: .day, value: -i, to: now) { dateRange.append(calendar.startOfDay(for: date)) } }
        case .year: for i in 0..<12 { if let date = calendar.date(byAdding: .month, value: -i, to: now), let start = calendar.date(from: calendar.dateComponents([.year, .month], from: date)) { dateRange.append(start) } }
        }
        dateRange.sort(); let cutoffDate = dateRange.first ?? now; var segments: [ChartSegment] = []
        
        for subject in subjects {
            for log in subject.logs {
                if log.date >= cutoffDate {
                    let value = selectedMetric == .time ? log.durationMinutes : (log.questionCount ?? 0)
                    if value > 0 {
                        totalVal += value; subjectTotals[subject.id, default: 0] += value
                        let logKey = selectedPeriod == .year ? calendar.date(from: calendar.dateComponents([.year, .month], from: log.date))! : calendar.startOfDay(for: log.date)
                        segments.append(ChartSegment(date: logKey, value: value, subjectName: subject.name, color: subject.colorHex.toColor))
                    }
                }
            }
        }
        let topSubjectID = subjectTotals.max(by: { $0.value < $1.value })?.key
        let topSubject = subjects.first(where: { $0.id == topSubjectID })
        for date in dateRange {
            if !segments.contains(where: { calendar.isDate($0.date, equalTo: date, toGranularity: selectedPeriod == .year ? .month : .day) }) {
                segments.append(ChartSegment(date: date, value: 0, subjectName: "", color: .clear))
            }
        }
        segments.sort { $0.date < $1.date }
        return (totalVal, topSubject, segments)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) { // Spacing 0 yapıldı (StudiesView ile uyumlu)
                    
                    // STANDART BAŞLIK YAPISI (StatsView)
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(t("app_name")) // Study Tracker
                                    .font(.system(size: 14, weight: .black, design: .rounded))
                                    .foregroundStyle(LinearGradient(colors: [.purple, .blue, .cyan], startPoint: .leading, endPoint: .trailing))
                                    .tracking(1)
                                
                                Text(t("analysis_title")) // "Analiz"
                                    .font(.title2).fontWeight(.semibold).foregroundColor(.white)
                            }
                            Spacer()
                            
                            // YENİ EKLENDİ: Hesap Yapan Maskot
                            StatsMascotView()
                        }
                        .padding(.horizontal)
                        
                        // Ayırıcı Gradient Çizgi
                        Rectangle()
                            .fill(LinearGradient(colors: [.purple, .clear], startPoint: .leading, endPoint: .trailing))
                            .frame(height: 1).shadow(color: .purple, radius: 2)
                    }
                    .padding(.top, 10)
                    
                    // İÇERİK (ScrollView)
                    ScrollView {
                        VStack(spacing: 25) {
                            Picker("Dönem", selection: $selectedPeriod) {
                                ForEach(Period.allCases) { period in Text(period.localizedName).tag(period) } // LOCALIZED
                            }
                            .pickerStyle(.segmented).colorScheme(.dark).padding(.horizontal)
                            
                            Picker("Metrik", selection: $selectedMetric) {
                                ForEach(Metric.allCases) { metric in
                                    Text(metric == .time ? t("type_time") : t("type_question")).tag(metric) // LOCALIZED
                                }
                            }
                            .pickerStyle(.segmented).colorScheme(.dark).padding(.horizontal)
                            
                            HStack(spacing: 15) {
                                // GÜNCELLENDİ: Birim (unit) kısmı güncellendi
                                SummaryCard(title: selectedMetric == .time ? t("total_time") : t("total_questions"),
                                            value: formatValue(filteredData.totalValue),
                                            unit: selectedMetric == .time ? t("unit_hour") : "",
                                            icon: selectedMetric == .time ? "hourglass" : "pencil.and.ruler.fill",
                                            color: .purple) // LOCALIZED
                                
                                SummaryCard(title: t("top_focus"), value: filteredData.topSubject?.name ?? "-", unit: "", icon: "star.fill", color: filteredData.topSubject?.colorHex.toColor ?? .gray) // LOCALIZED
                            }
                            .padding(.horizontal)
                            
                            VStack(alignment: .leading, spacing: 15) {
                                HStack { Image(systemName: "chart.bar.fill").foregroundColor(.purple); Text(t("activity_chart")).font(.caption).bold().foregroundColor(.gray) } // LOCALIZED
                                if filteredData.totalValue == 0 {
                                    Text(t("no_data")).foregroundColor(.gray).frame(height: 220).frame(maxWidth: .infinity) // LOCALIZED
                                } else {
                                    Chart {
                                        ForEach(filteredData.chartSegments) { segment in
                                            BarMark(x: .value("Tarih", segment.date, unit: selectedPeriod == .year ? .month : .day), y: .value("Değer", segment.value))
                                                .foregroundStyle(segment.color).cornerRadius(selectedPeriod == .year ? 4 : 2)
                                        }
                                    }
                                    .chartYAxis { AxisMarks(position: .leading) { value in AxisValueLabel { if let intValue = value.as(Int.self) { Text("\(intValue)").font(.caption2).foregroundColor(.gray) } }; AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4])).foregroundStyle(Color(white: 0.2)) } }
                                    .chartXAxis {
                                        switch selectedPeriod {
                                        case .week: AxisMarks(values: .stride(by: .day)) { _ in AxisValueLabel(format: .dateTime.weekday(.abbreviated), centered: true) }
                                        case .month: AxisMarks(values: .stride(by: .day)) { value in if let date = value.as(Date.self), let day = Calendar.current.dateComponents([.day], from: date).day, day == 1 || day % 5 == 0 { AxisValueLabel(format: .dateTime.day()); AxisTick() } }
                                        case .year: AxisMarks(values: .stride(by: .month)) { _ in AxisValueLabel(format: .dateTime.month(.narrow), centered: true) }
                                        }
                                    }
                                    .frame(height: 250)
                                }
                            }
                            .padding().background(Color(white: 0.1)).cornerRadius(20).padding(.horizontal)
                            
                            VStack(alignment: .leading, spacing: 15) {
                                Label(t("subject_dist"), systemImage: "piechart").font(.caption).bold().foregroundColor(.gray) // LOCALIZED
                                if subjects.isEmpty { Text(t("no_data")).foregroundColor(.gray) } else {
                                    ForEach(subjects.sorted(by: { calculateSubjectTotal($0) > calculateSubjectTotal($1) })) { subject in
                                        let total = calculateSubjectTotal(subject)
                                        if total > 0 { DistributionRow(subject: subject, value: total, totalValue: filteredData.totalValue, isTime: selectedMetric == .time) }
                                    }
                                }
                            }
                            .padding().background(Color(white: 0.1)).cornerRadius(20).padding(.horizontal).padding(.bottom, 50)
                        }
                        .padding(.top, 15) // Başlık ile içerik arası standart boşluk
                    }
                    .scrollDismissesKeyboard(.immediately) // EKLENDİ: Klavye hemen kapansın
                }
            }
        }
    }
    
    func formatValue(_ value: Int) -> String { return selectedMetric == .time ? String(format: "%.1f", Double(value) / 60.0) : "\(value)" }
    func calculateSubjectTotal(_ subject: Subject) -> Int {
        let calendar = Calendar.current; let now = Date(); let cutoffDate: Date
        switch selectedPeriod {
        case .week: cutoffDate = calendar.date(byAdding: .day, value: -7, to: now)!
        case .month: cutoffDate = calendar.date(byAdding: .month, value: -1, to: now)!
        case .year: cutoffDate = calendar.date(byAdding: .year, value: -1, to: now)!
        }
        return subject.logs.filter { $0.date >= cutoffDate }.reduce(0) { $0 + (selectedMetric == .time ? $1.durationMinutes : ($1.questionCount ?? 0)) }
    }
}

// MARK: - STATS MASCOT (HESAP YAPAN MASKOT - APP ICON TARZI)
struct StatsMascotView: View {
    @State private var isThinking = false
    @State private var mathSymbol = ""
    let symbols = ["➕", "➖", "✖️", "➗", "∫", "√", "π", "%"]
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // MASKOT RESMİ (APP ICON STİLİ)
            // Eğer "mascot" adında bir resim Assets'e eklenmezse
            // uygulama çökmesin diye güvenli bir yapı kurduk.
            if UIImage(named: "mascot") != nil {
                Image("mascot")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50) // Standart ikon boyutu
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous)) // iOS İkon Şekli
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
            } else {
                // Resim yoksa geçici bir emoji göster
                Text("🐻")
                    .font(.system(size: 40))
                    .frame(width: 50, height: 50)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.gray.opacity(0.2)))
            }
            
            // Düşünce Balonu (Hesap Yapıyor Animasyonu)
            if isThinking {
                Text(mathSymbol)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.black)
                    .padding(6)
                    .background(Circle().fill(Color.white))
                    .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                    .offset(x: 10, y: -20)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .onAppear {
            startThinking()
        }
    }
    
    func startThinking() {
        // Her 1.5 saniyede bir yeni bir matematik sembolü düşünür
        Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { _ in
            withAnimation(.spring(bounce: 0.5)) {
                isThinking.toggle()
                if isThinking {
                    mathSymbol = symbols.randomElement() ?? "➕"
                }
            }
        }
    }
}

// YARDIMCI GÖRÜNÜMLER (StatsView'a özel olanlar)
struct SummaryCard: View {
    let title: String; let value: String; let unit: String; let icon: String; let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack { Image(systemName: icon).foregroundColor(color); Text(title).font(.caption).fontWeight(.bold).foregroundColor(.gray) }
            HStack(alignment: .lastTextBaseline, spacing: 4) { Text(value).font(.title).fontWeight(.bold).foregroundColor(.white).lineLimit(1).minimumScaleFactor(0.5); if !unit.isEmpty { Text(unit).font(.subheadline).foregroundColor(.gray) } }
        }.padding().frame(maxWidth: .infinity, alignment: .leading).background(Color(white: 0.1)).cornerRadius(15).overlay(RoundedRectangle(cornerRadius: 15).stroke(color.opacity(0.3), lineWidth: 1))
    }
}

struct DistributionRow: View {
    let subject: Subject; let value: Int; let totalValue: Int; let isTime: Bool
    var percentage: Double { return totalValue > 0 ? Double(value) / Double(totalValue) : 0 }
    var body: some View {
        VStack(spacing: 8) {
            HStack { Circle().fill(subject.colorHex.toColor).frame(width: 10, height: 10); Text(subject.name).font(.subheadline).fontWeight(.semibold).foregroundColor(.white); Spacer(); Text("\(value) \(isTime ? t("unit_min") : t("unit_question"))").font(.subheadline).foregroundColor(.gray) } // LOCALIZED
            GeometryReader { geometry in ZStack(alignment: .leading) { RoundedRectangle(cornerRadius: 4).fill(Color(white: 0.2)).frame(height: 6); RoundedRectangle(cornerRadius: 4).fill(subject.colorHex.toColor).frame(width: geometry.size.width * percentage, height: 6) } }.frame(height: 6)
        }
    }
}

import SwiftUI
import SwiftData
import UIKit
import GoogleMobileAds // AdMob Kütüphanesi

// YENİ: Görselleri uygulama açılışında RAM'e yükleyen yapı (Preload)
struct AssetCache {
    // Sadece varlık kontrolü değil, görselin kendisini hafızada tutuyoruz
    static let mascotImage: UIImage? = UIImage(named: "mascot")
    static let mascotHappyImage: UIImage? = UIImage(named: "mascot_happy")
}

struct ContentView: View {
    // Sekmelerin sırası değişti: 0 -> Çalışmalar, 1 -> İstatistikler, 2 -> Derslerim
    @State private var selectedTab = 0
    
    // GÜNCELLEŞTİRİLDİ: Hangi ders için log ekleneceğini tutan state
    @State private var selectedSubjectForLog: Subject?
    
    // GÜNCELLEŞTİRİLDİ: Hangi dersin hedefinin düzenleneceğini tutan state
    @State private var selectedSubjectForGoalSheet: Subject?
    
    // GÜNCELLEŞTİRİLDİ: Detay sayfasını sheet olarak açmak için yeni state
    @State private var selectedSubjectForDetail: Subject?
    
    // Kutlama animasyonu için state
    @State private var showCelebration = false
    
    // Açılış ekranı kontrolü
    @State private var showSplash = true
    
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.black
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.gray
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor.systemPurple
        // Tab bar'da başlıkları göstermek için bu ayarlamaları geri alıyoruz
        appearance.stackedLayoutAppearance.normal.titlePositionAdjustment = .zero
        appearance.stackedLayoutAppearance.selected.titlePositionAdjustment = .zero
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        
        // AssetCache'i tetikleyerek görsellerin RAM'e yüklenmesini sağla (Opsiyonel, static oldukları için ilk erişimde yüklenirler)
        _ = AssetCache.mascotImage
        _ = AssetCache.mascotHappyImage
    }
    
    var body: some View {
        ZStack {
            // 1. ANA UYGULAMA
            VStack(spacing: 0) {
                TabView(selection: $selectedTab) {
                    
                    // SEKME 1: ÇALIŞMALAR (tag(0) - Ana Sayfa)
                    StudiesView(
                        selectedSubjectForLog: $selectedSubjectForLog,
                        selectedSubjectForGoalSheet: $selectedSubjectForGoalSheet,
                        selectedSubjectForDetail: $selectedSubjectForDetail
                    )
                    .tabItem {
                        Label(t("studies"), systemImage: "clock.fill") // "Çalışmalar"
                    }
                    .tag(0)
                    
                    // SEKME 2: İSTATİSTİKLER (tag(1) - Yeni Sıra)
                    StatsView()
                        .tabItem {
                            Label(t("stats"), systemImage: "chart.bar.xaxis")
                        }
                        .tag(1)
                    
                    // SEKME 3: DERSLERİM (tag(2) - En Sona Kaydırıldı)
                    SubjectsView(
                        selectedSubjectForLog: $selectedSubjectForLog,
                        selectedSubjectForGoalSheet: $selectedSubjectForGoalSheet
                    )
                    .tabItem {
                        Label(t("my_subjects"), systemImage: "books.vertical.fill") // "Derslerim"
                    }
                    .tag(2)
                }
                .accentColor(.purple)
                .animation(nil, value: selectedTab)
                
                // AdMob Banner Alanı (En altta)
                BottomAdBanner()
            }
            
            // 2. KUTLAMA EFEKTİ (En üst katmanda)
            if showCelebration {
                CelebrationView()
                    .transition(.scale.combined(with: .opacity))
                    .zIndex(20)
            }
            
            // 3. AÇILIŞ EKRANI
            if showSplash {
                SplashScreenView()
                    .transition(.opacity)
                    .zIndex(10)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeOut(duration: 0.8)) {
                    showSplash = false
                }
            }
        }
        // SHEET 1: ÇALIŞMA EKLEME EKRANI
        .sheet(item: $selectedSubjectForLog) { subject in
            AddLogView(preSelectedSubject: subject, onGoalReached: {
                // Hedef tamamlanırsa kutlama yap
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    showCelebration = true
                }
                // HEDEF TAMAMLANDI: Kutlama ekranının otomatik kapanma mantığı buraya geri alındı.
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    withAnimation {
                        showCelebration = false
                    }
                }
            })
        }
        // SHEET 2: HEDEF DÜZENLEME EKRANI
        .sheet(item: $selectedSubjectForGoalSheet) { subject in
            GoalSheet(subject: subject)
        }
        // YENİ SHEET 3: DERS DETAY EKRANI (StudiesView'dan tetiklenir)
        .sheet(item: $selectedSubjectForDetail) { subject in
            // SubjectDetailView'ı NavigationStack içinde açıyoruz ki, eğer kendi içinde navigasyon yapısı varsa çalışsın.
            NavigationStack {
                SubjectDetailView(subject: subject)
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - ADMOB BANNER VIEW
struct BottomAdBanner: View {
    var body: some View {
        // GÜNCELLEŞTİRİLDİ: GeometryReader kullanarak mevcut genişliği alıyoruz
        GeometryReader { geometry in
            ZStack {
                Color(white: 0.1) // Zemin rengi
                // Genişliği AdBannerViewController'a iletiyoruz
                AdBannerViewController(adWidth: geometry.size.width)
                    // Genişliği tam ekran yapıyoruz, yüksekliği sabit tutuyoruz
                    .frame(width: geometry.size.width, height: 50)
            }
        }
        .frame(height: 60)
        // GÜNCELLEŞTİRİLDİ: Reklamın altındaki boşluğu (safe area) aynı renkle doldur
        .background(Color(white: 0.1).ignoresSafeArea(edges: .bottom))
    }
}

struct AdBannerViewController: UIViewRepresentable {
    // GÜNCELLEŞTİRİLDİ: SwiftUI'dan genişliği almak için yeni property
    let adWidth: CGFloat

    func makeUIView(context: Context) -> BannerView {
        // HATA DÜZELTMESİ: GADAdSize.currentOrientationAnchoredAdaptiveBannerAdSize metoduna erişilemediği için
        // GADAdSizeFromCGSize C fonksiyonu kullanılarak uyarlanabilir boyut (adaptive size) oluşturuluyor.
        let adSize = adSizeFor(cgSize: CGSize(width: adWidth, height: 50))
        let banner = BannerView(adSize: adSize)
        
        // OPTİMİZASYON 3: Reklam yükleme işlemini 1.0 saniye geciktiriyoruz.
        // Bu, uygulama arka plandan ön plana geldiğinde UI'ın kendine gelmesi için zaman tanır.
        // İlk kaydırma (scroll) anındaki takılmayı (stutter) önler.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            banner.rootViewController = UIApplication.shared.connectedScenes
                .filter { $0.activationState == .foregroundActive }
                .compactMap { $0 as? UIWindowScene }
                .first?.windows
                .filter { $0.isKeyWindow }.first?.rootViewController
            
            #if DEBUG
            print("📢 AdMob: Test Modunda Çalışıyor")
            banner.adUnitID = "ca-app-pub-3940256099942544/2934735716"
            #else
            banner.adUnitID = "ca-app-pub-4244659004257886/7570907794"
            #endif
            
            banner.load(Request())
        }
        
        return banner
    }
    func updateUIView(_ uiView: BannerView, context: Context) {}
}


// MARK: - HEDEF DÜZENLEME PANELİ
struct GoalSheet: View {
    @Environment(\.dismiss) var dismiss
    @Bindable var subject: Subject
    
    @State private var goalTimeInput: String = ""
    @State private var goalQuestionInput: String = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                // EKLENDİ: Klavye hemen kapansın diye ScrollView kullanıldı
                ScrollView {
                    VStack(spacing: 30) {
                        VStack(spacing: 10) {
                            Image(systemName: "target").font(.system(size: 50)).foregroundColor(subject.colorHex.toColor)
                                .padding().background(subject.colorHex.toColor.opacity(0.1)).clipShape(Circle())
                            Text(t("set_daily_goal")).font(.title2).bold().foregroundColor(.white)
                            Text(t("goal_prompt")).font(.caption).foregroundColor(.gray)
                        }.padding(.top, 30)
                        
                        VStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(t("daily_goal_title")).font(.caption).bold().foregroundColor(.gray)
                                TextField("0", text: $goalTimeInput)
                                    .keyboardType(.numberPad)
                                    .padding().background(Color(white: 0.15)).cornerRadius(12).foregroundColor(.white)
                                    .overlay(HStack { Spacer(); Text(t("unit_min")).foregroundColor(.gray).padding(.trailing) })
                            }
                            VStack(alignment: .leading, spacing: 8) {
                                Text(t("daily_goal_q_title")).font(.caption).bold().foregroundColor(.gray)
                                TextField("0", text: $goalQuestionInput)
                                    .keyboardType(.numberPad)
                                    .padding().background(Color(white: 0.15)).cornerRadius(12).foregroundColor(.white)
                                    .overlay(HStack { Spacer(); Text(t("unit_question")).foregroundColor(.gray).padding(.trailing) })
                            }
                        }.padding(.horizontal)
                    }
                    .padding(.bottom, 20)
                }
                .scrollDismissesKeyboard(.immediately) // KLAVYE ANINDA KAPANSIN
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(t("cancel")) { dismiss() }.foregroundColor(.white) }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: saveGoals) {
                        Text(t("save")).fontWeight(.bold).padding(.horizontal, 16).padding(.vertical, 6)
                            .background(subject.colorHex.toColor).foregroundColor(.white).cornerRadius(8)
                    }
                }
            }
        }
        .onAppear {
            if subject.dailyGoal > 0 { goalTimeInput = String(subject.dailyGoal) }
            if subject.dailyGoalQuestion > 0 { goalQuestionInput = String(subject.dailyGoalQuestion) }
        }
        .presentationDetents([.medium]).presentationCornerRadius(25)
    }
    func saveGoals() {
        subject.dailyGoal = Int(goalTimeInput) ?? 0
        subject.dailyGoalQuestion = Int(goalQuestionInput) ?? 0
        dismiss()
    }
}

// MARK: - KUTLAMA GÖRÜNÜMÜ
struct CelebrationView: View {
    @State private var scale = 0.5
    @State private var rotation = 0.0
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.7).ignoresSafeArea()
            VStack(spacing: 20) {
                ZStack {
                    Circle().fill(RadialGradient(colors: [.yellow.opacity(0.5), .clear], center: .center, startRadius: 10, endRadius: 150)).frame(width: 300, height: 300).blur(radius: 60).scaleEffect(scale * 1.2)
                    // GÜNCELLEME: RAM'deki görsel kullanılıyor
                    if let image = AssetCache.mascotHappyImage {
                         Image(uiImage: image).resizable().scaledToFit().frame(width: 200, height: 200).shadow(color: .yellow.opacity(0.5), radius: 20)
                    } else {
                        Text("🎉").font(.system(size: 150)).shadow(color: .purple, radius: 20)
                    }
                }.rotationEffect(.degrees(rotation))
                
                Text(t("celebration_title")).font(.largeTitle).bold().foregroundColor(.white).shadow(color: .purple, radius: 10)
                Text(t("celebration_message")).font(.headline).foregroundColor(.gray)
            }.scaleEffect(scale)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.5)) { scale = 1.0 }
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) { rotation = 10 }
        }
    }
}

// MARK: - MASKOT & SPLASH
struct MascotView: View {
    @State private var blink = false; @State private var showMessage = false; @State private var currentMessage = ""
    let messages = ["Harikasın! 🌟", "Devam et! 💪", "Su iç? 💧", "Mola? ☕️", "Odaklan! 🎯", "Süpersin! 🚀", "Başarabilirsin! ✨", "Zekisin! 🧠", "Çok iyi! 🔥", "Selam! 👋", "Kolay gelsin! 📚"]
    
    var body: some View {
        ZStack {
            // OPTİMİZASYON: RAM'deki görseli doğrudan kullanıyoruz
            if let image = AssetCache.mascotImage {
                // drawingGroup() ile GPU render'a zorluyoruz
                Image(uiImage: image)
                    .resizable().scaledToFit().frame(width: 50, height: 50).clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous)).overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.1), lineWidth: 1)).shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2).scaleEffect(blink ? 1.05 : 0.95)
                    .drawingGroup()
            } else {
                ZStack { RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.orange.gradient).frame(width: 50, height: 50); Image(systemName: "pawprint.fill").foregroundColor(.white) }.scaleEffect(blink ? 1.05 : 0.95)
            }
        }.overlay(alignment: .topLeading) { if showMessage { Text(currentMessage).font(.caption2).bold().padding(.horizontal, 8).padding(.vertical, 4).background(Color.white).foregroundColor(.black).cornerRadius(8).shadow(radius: 2).fixedSize().offset(x: -70, y: 10).transition(.scale.combined(with: .opacity)) } }
        .onTapGesture { withAnimation(.spring()) { currentMessage = messages.randomElement() ?? "Merhaba!"; showMessage = true }; DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { withAnimation { showMessage = false } } }
        .onAppear { withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) { blink = true } }
    }
}
struct SplashScreenView: View {
    @State private var isAnimating = false
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea();
            ZStack {
                Circle().fill(Color.purple.opacity(0.2)).frame(width: 300, height: 300).blur(radius: 60).offset(x: -50, y: -100);
                Circle().fill(Color.blue.opacity(0.2)).frame(width: 200, height: 200).blur(radius: 60).offset(x: 50, y: 100)
            }.scaleEffect(isAnimating ? 1.1 : 1.0);
            VStack(spacing: 25) {
                ZStack {
                    RoundedRectangle(cornerRadius: 35, style: .continuous).strokeBorder(LinearGradient(colors: [.purple, .blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 4).frame(width: 160, height: 160).shadow(color: .purple.opacity(0.5), radius: 10, x: 0, y: 0);
                    // OPTİMİZASYON: RAM'deki görsel kullanılıyor
                    if let image = AssetCache.mascotImage {
                        Image(uiImage: image).resizable().scaledToFit().frame(width: 140, height: 140).clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous)).shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 0)
                    } else {
                        Image(systemName: "pawprint.fill").font(.system(size: 80)).foregroundStyle(LinearGradient(colors: [.orange, .yellow], startPoint: .top, endPoint: .bottom)).shadow(color: .orange.opacity(0.5), radius: 10)
                    }
                }.scaleEffect(isAnimating ? 1.05 : 0.95);
                VStack(spacing: 5) {
                    Text(t("app_name")).font(.system(size: 36, weight: .black, design: .rounded)).foregroundStyle(LinearGradient(colors: [.purple, .blue, .cyan], startPoint: .leading, endPoint: .trailing)).tracking(2).shadow(color: .purple.opacity(0.5), radius: 10, x: 0, y: 0);
                    Text(t("splash_slogan")).font(.subheadline).foregroundColor(.gray).tracking(4).opacity(0.8)
                }
            }
        }.onAppear { withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) { isAnimating = true } }
    }
}

// Eski HomeView, artık sadece Çalışmalar sekmesinin içeriği olacak.
struct StudiesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Subject> { $0.isArchived == false }, sort: \Subject.createdAt) private var subjects: [Subject]
    
    @Binding var selectedSubjectForLog: Subject?
    @Binding var selectedSubjectForGoalSheet: Subject?
    @Binding var selectedSubjectForDetail: Subject?
    
    @State private var selectedSubjectForReminder: Subject?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    
                    // STANDART BAŞLIK YAPISI (StudiesView)
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(t("app_name")) // Study Tracker
                                    .font(.system(size: 14, weight: .black, design: .rounded))
                                    .foregroundStyle(LinearGradient(colors: [.purple, .blue, .cyan], startPoint: .leading, endPoint: .trailing))
                                    .tracking(1)
                                
                                Text(t("studies")) // "Çalışmalar"
                                    .font(.title2).fontWeight(.semibold).foregroundColor(.white)
                            }
                            Spacer()
                            
                            MascotView()
                        }
                        .padding(.horizontal)
                        
                        // Ayırıcı Gradient Çizgi
                        Rectangle()
                            .fill(LinearGradient(colors: [.purple, .clear], startPoint: .leading, endPoint: .trailing))
                            .frame(height: 1).shadow(color: .purple, radius: 2)
                    }
                    .padding(.top, 10)
                    
                    // Liste içeriği
                    if subjects.isEmpty {
                        EmptyStateStudiesView()
                    } else {
                        // OPTİMİZASYON: Her satırda tekrar tekrar hesaplamamak için bugünü bir kere alıyoruz
                        let today = Calendar.current.startOfDay(for: Date())
                        
                        List {
                            ForEach(subjects) { subject in
                                // OPTİMİZASYON: today değişkenini fonksiyona paslıyoruz
                                let progress = calculateProgress(for: subject, today: today)
                                let hasAnyGoal = subject.dailyGoal > 0 || subject.dailyGoalQuestion > 0
                                let isCompleted = progress >= 1.0
                                
                                VStack(spacing: 0) {
                                    // SubjectCard görünümü korundu
                                    SubjectCard(subject: subject,
                                                onBellClick: { selectedSubjectForReminder = subject },
                                                onAddLogClick: { selectedSubjectForLog = subject })
                                    .onTapGesture {
                                        selectedSubjectForDetail = subject
                                    }
                                    
                                    if hasAnyGoal {
                                        GeometryReader { geo in
                                            ZStack(alignment: .leading) {
                                                RoundedRectangle(cornerRadius: 2).fill(Color.gray.opacity(0.3)).frame(height: 4)
                                                RoundedRectangle(cornerRadius: 2).fill(isCompleted ? Color.green : Color.blue).frame(width: min(geo.size.width * progress, geo.size.width), height: 4).animation(.spring(), value: progress)
                                            }
                                        }.frame(height: 4).padding(.horizontal, 10).padding(.top, 5)
                                    }
                                }
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 15, trailing: 16))
                                
                                // Çalışma Ekleme ve Hedef Düzenleme swipe action'ları korundu.
                                .swipeActions(edge: .trailing) {
                                    Button {
                                        selectedSubjectForLog = subject
                                    } label: {
                                        Label(t("add_log_title"), systemImage: "plus.circle.fill")
                                    }
                                    .tint(.green)
                                }
                                
                                .swipeActions(edge: .leading) {
                                    Button {
                                        selectedSubjectForGoalSheet = subject
                                    } label: {
                                        Label(t("set_daily_goal"), systemImage: "target")
                                    }
                                    .tint(.blue)
                                }
                            }
                            Color.clear.frame(height: 50).listRowBackground(Color.clear).listRowSeparator(.hidden)
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        .padding(.top, 15) // Başlık ile içerik arası standart boşluk
                        .scrollDismissesKeyboard(.immediately) // EKLENDİ: Liste kaydırılınca klavye kapansın
                    }
                }
            }
            .navigationBarHidden(true)
            .navigationTitle("")
            .toolbar(.hidden)
        }
        .onAppear {
            // OPTİMİZASYON: Bildirim iznini ana thread'i bloklamadan arka planda iste
            DispatchQueue.global(qos: .background).async {
                NotificationManager.shared.requestPermission()
            }
        }
        .sheet(item: $selectedSubjectForReminder) { subject in ReminderSheet(subject: subject) }
    }
    
    // İlerleme hesaplama fonksiyonu OPTİMİZE EDİLDİ (v2)
    func calculateProgress(for subject: Subject, today: Date) -> Double {
        // OPTİMİZASYON 4: .filter fonksiyonu yeni bir array yaratır (Heap allocation).
        // Bunun yerine logs dizisini bir kez dönüp manuel toplamak (Stack allocation) çok daha hızlıdır.
        // Özellikle "foreground" anında yüzlerce log varsa bu fark yaratır.
        
        var totalMinutes = 0
        var totalQuestions = 0
        
        // Cache calendar
        let calendar = Calendar.current
        
        for log in subject.logs {
            if calendar.isDate(log.date, inSameDayAs: today) {
                totalMinutes += log.durationMinutes
                if let q = log.questionCount {
                    totalQuestions += q
                }
            }
        }
        
        var totalProgress: Double = 0
        var goalCount: Double = 0
        
        if subject.dailyGoal > 0 {
            totalProgress += min(Double(totalMinutes) / Double(subject.dailyGoal), 1.0)
            goalCount += 1
        }
        
        if subject.dailyGoalQuestion > 0 {
            totalProgress += min(Double(totalQuestions) / Double(subject.dailyGoalQuestion), 1.0)
            goalCount += 1
        }
        
        if goalCount == 0 { return 0 }
        return totalProgress / goalCount
    }
}

// Yeni boş durum görünümü (Çalışmalar sekmesi için)
struct EmptyStateStudiesView: View {
    var body: some View { VStack { Spacer(); Image(systemName: "timer").font(.system(size: 50)).foregroundColor(.gray.opacity(0.5)).padding(.bottom, 10); Text(t("no_subjects_studies")).foregroundColor(.gray).font(.headline); Text(t("add_subjects_to_start")).foregroundColor(.gray).font(.caption).padding(.top, 5); Spacer() } }
}

// Eski EmptyStateView (Derslerim sekmesinde kullanılacak)
struct EmptyStateView: View {
    var body: some View { VStack { Spacer(); Image(systemName: "notebook").font(.system(size: 50)).foregroundColor(.gray.opacity(0.5)).padding(.bottom, 10); Text(t("no_subjects")).foregroundColor(.gray).font(.headline); Text(t("add_first_subject")).foregroundColor(.gray).font(.caption).padding(.top, 5); Spacer() } }
}

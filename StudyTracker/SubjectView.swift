import SwiftUI
import SwiftData

// HomeView'daki mantığı alacak yeni "Derslerim" sekmesi
struct SubjectsView: View {
    @Environment(\.modelContext) private var modelContext
    // isArchived == false olan dersleri listele
    @Query(filter: #Predicate<Subject> { $0.isArchived == false }, sort: \Subject.createdAt) private var subjects: [Subject]
    
    // Ders Ekleme ekranını açmak için
    @State private var showAddSubject = false
    // Düzenleme görünümünü açmak için kullanılan state
    @State private var selectedSubjectForEdit: Subject?
    // Log ekleme için
    @Binding var selectedSubjectForLog: Subject?
    // Hedef düzenleme için (Artık kullanılmıyor olabilir ama binding'i bozmuyoruz)
    @Binding var selectedSubjectForGoalSheet: Subject?
    
    // Reminder ve Silme işlemleri için HomeView'dan gelen state'ler
    @State private var selectedSubjectForReminder: Subject?
    @State private var subjectToDelete: Subject?
    @State private var showDeleteAlert = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) { // Spacing 0 yapıldı (Diğer sekmelerle uyumlu)
                    
                    // STANDART BAŞLIK YAPISI (SubjectsView)
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(t("app_name")) // Study Tracker
                                    .font(.system(size: 14, weight: .black, design: .rounded))
                                    .foregroundStyle(LinearGradient(colors: [.purple, .blue, .cyan], startPoint: .leading, endPoint: .trailing))
                                    .tracking(1)
                                
                                Text(t("my_subjects")) // "Derslerim"
                                    .font(.title2).fontWeight(.semibold).foregroundColor(.white)
                            }
                            Spacer()
                            
                            // SAĞ ÜST: Ders Ekle butonu + Mascot
                            HStack(spacing: 15) {
                                // 1. Ders Ekle Butonu (Çerçeveli Artı)
                                Button(action: { showAddSubject = true }) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 20, weight: .bold)) // İkon boyutu biraz küçültüldü çerçeve içine sığması için
                                        .foregroundColor(.white)
                                        .frame(width: 44, height: 44) // Çerçeve boyutu
                                        .background(Color(white: 0.2)) // Çerçeve rengi
                                        .cornerRadius(12) // Köşe yuvarlaklığı
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.white.opacity(0.1), lineWidth: 1) // İnce kenarlık
                                        )
                                }
                                
                                // 2. İKON (MascotView) - Sona alındı
                                MascotView()
                            }
                        }
                        .padding(.horizontal)
                        
                        // Ayırıcı Gradient Çizgi
                        Rectangle()
                            .fill(LinearGradient(colors: [.purple, .clear], startPoint: .leading, endPoint: .trailing))
                            .frame(height: 1).shadow(color: .purple, radius: 2)
                    }
                    .padding(.top, 10)
                    
                    if subjects.isEmpty {
                        EmptyStateView()
                    } else {
                        List {
                            ForEach(subjects) { subject in
                                SubjectListRow(subject: subject)
                                    
                                    // 1. AKSİYON: Tıklayınca DÜZENLEME sayfası açılsın
                                    .onTapGesture {
                                        selectedSubjectForEdit = subject
                                    }
                                
                                    // Sola Kaydır (Trailing Edge) = Silme/Arşivleme
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            subjectToDelete = subject
                                            showDeleteAlert = true
                                        } label: {
                                            Label(t("archive"), systemImage: "trash.fill")
                                        }
                                    }
                                    // Sağa Kaydır (Leading Edge) = Sadece Düzenle
                                    .swipeActions(edge: .leading) {
                                        // GÜNCELLENDİ: Hedef düzenleme butonu kaldırıldı.
                                        Button {
                                            selectedSubjectForEdit = subject
                                        } label: {
                                            Label(t("edit"), systemImage: "pencil.circle.fill")
                                        }
                                        .tint(.blue)
                                    }
                                
                                // List stilini koru
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                            }
                            Color.clear.frame(height: 50).listRowBackground(Color.clear).listRowSeparator(.hidden)
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        .padding(.top, 15) // Başlık ile içerik arası standart boşluk
                        .scrollDismissesKeyboard(.immediately) // EKLENDİ: Klavye hemen kapansın
                    }
                }
            }
            .navigationBarHidden(true)
            .navigationTitle("")
            .toolbar(.hidden)
        }
        .onAppear { NotificationManager.shared.requestPermission() }
        
        // DERS EKLEME EKRANI
        .sheet(isPresented: $showAddSubject) {
            AddSubjectView()
        }
        
        // DERS DÜZENLEME EKRANI
        .sheet(item: $selectedSubjectForEdit) { subject in
            AddSubjectView(subjectToEdit: subject)
        }
        
        .sheet(item: $selectedSubjectForReminder) { subject in ReminderSheet(subject: subject) }
        
        .alert(t("delete_subject"), isPresented: $showDeleteAlert) {
            Button(t("delete"), role: .destructive) { if let subject = subjectToDelete { deleteSubject(subject) } }
            Button(t("cancel"), role: .cancel) { }
        } message: { Text(t("archive_confirm")) }
    }
    
    // Silme (arşivleme) fonksiyonu
    func deleteSubject(_ subject: Subject) {
        NotificationManager.shared.cancelReminder(id: subject.id.uuidString)
        subject.reminderTime = nil
        subject.isArchived = true
        subjectToDelete = nil
    }
}

// MARK: - LİSTE SATIRI GÖRÜNÜMÜ
struct SubjectListRow: View {
    @Bindable var subject: Subject

    var body: some View {
        HStack(spacing: 15) {
            // Renkli Dikey Ayırıcı
            RoundedRectangle(cornerRadius: 2).fill(subject.colorHex.toColor).frame(width: 4, height: 40)

            VStack(alignment: .leading, spacing: 6) { // Spacing biraz artırıldı
                Text(subject.name)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                // Hedef Özeti
                HStack(spacing: 8) {
                    if subject.dailyGoal > 0 {
                        GoalPillView(icon: "clock.fill", value: "\(subject.dailyGoal) \(t("unit_min"))", color: .blue)
                    }
                    if subject.dailyGoalQuestion > 0 {
                        GoalPillView(icon: "pencil.and.ruler.fill", value: "\(subject.dailyGoalQuestion) \(t("unit_question"))", color: .orange)
                    }
                    if subject.dailyGoal == 0 && subject.dailyGoalQuestion == 0 {
                        Text(t("no_goals_set")).font(.caption).foregroundColor(.gray.opacity(0.7))
                    }
                }
                
                // GÜNCELLENDİ: Alt Konular Listesi (Yatay Kaydırmalı)
                if !subject.knownTopics.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(subject.knownTopics, id: \.self) { topic in
                                Text(topic)
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(subject.colorHex.toColor.opacity(0.15)) // Ders renginde hafif arka plan
                                    .foregroundColor(subject.colorHex.toColor.opacity(0.9)) // Ders renginde yazı
                                    .cornerRadius(6)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(subject.colorHex.toColor.opacity(0.3), lineWidth: 0.5)
                                    )
                            }
                        }
                    }
                    .padding(.top, 2)
                }
            }
            
            Spacer()

            // Hatırlatıcı ikonu
            if subject.reminderTime != nil {
                Image(systemName: "bell.fill")
                    .foregroundColor(.yellow)
                    .font(.subheadline)
            }
            
            Image(systemName: "chevron.right").foregroundColor(Color(white: 0.3)).opacity(0)
        }
        .padding(.vertical, 10) // Padding biraz artırıldı
        .contentShape(Rectangle())
        .background(Color(white: 0.1))
        .cornerRadius(10)
    }
    
    struct GoalPillView: View {
        let icon: String
        let value: String
        let color: Color
        var body: some View {
            HStack(spacing: 5) {
                Image(systemName: icon).font(.caption2)
                Text(value).font(.caption).fontWeight(.medium)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(8)
        }
    }
}

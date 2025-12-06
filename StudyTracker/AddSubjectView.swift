import SwiftUI
import SwiftData

struct AddSubjectView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var context
    // Bu görünümden ders listesi kaldırıldı, sadece ekleme/düzenleme formu kaldı
    
    @State private var name = ""
    @State private var selectedColor = "purple"
    @FocusState private var isNameFocused: Bool
    @State private var newTopic = ""
    @State private var tempTopics: [String] = []
    
    // GÜNCELLENDİ: İki hedef için state
    @State private var dailyGoalTime = ""
    @State private var dailyGoalQuestion = ""
    
    @State private var subjectToEdit: Subject?
    
    // YENİ: Edit modunda hangi dersin düzenlendiğini dışarıdan almak için init
    init(subjectToEdit: Subject? = nil) {
        if let subject = subjectToEdit {
            _subjectToEdit = State(initialValue: subject)
            _name = State(initialValue: subject.name)
            _selectedColor = State(initialValue: subject.colorHex)
            _tempTopics = State(initialValue: subject.knownTopics)
            _dailyGoalTime = State(initialValue: subject.dailyGoal > 0 ? String(subject.dailyGoal) : "")
            _dailyGoalQuestion = State(initialValue: subject.dailyGoalQuestion > 0 ? String(subject.dailyGoalQuestion) : "")
        }
    }
    
    static let colors = ["red", "orange", "yellow", "lime", "green", "mint", "teal", "cyan", "blue", "purple", "magenta", "pink"]
    let columns = Array(repeating: GridItem(.flexible(), spacing: 15), count: 4)
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea().onTapGesture { isNameFocused = false }
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 25) {
                            // FORM
                            VStack(alignment: .leading, spacing: 15) {
                                // İçerik üstündeki küçük başlık
                                Text(subjectToEdit == nil ? t("new_subject_title") : t("edit_subject_title"))
                                    .font(.caption).bold().foregroundColor(.gray)
                                
                                ZStack(alignment: .leading) {
                                    if name.isEmpty {
                                        Text(t("subject_name_ph")).foregroundColor(Color(white: 0.5)).padding(.horizontal, 16)
                                    }
                                    TextField("", text: $name)
                                        .padding().background(Color(white: 0.15)).cornerRadius(12)
                                        .foregroundColor(.white).font(.headline)
                                        .focused($isNameFocused).submitLabel(.done)
                                }
                                
                                LazyVGrid(columns: columns, spacing: 15) {
                                    ForEach(Self.colors, id: \.self) { color in
                                        ColorSelectionCircle(color: color, isSelected: selectedColor == color)
                                            .onTapGesture {
                                                isNameFocused = false
                                                withAnimation(.easeInOut(duration: 0.2)) { selectedColor = color }
                                            }
                                    }
                                }
                                .padding().background(Color(white: 0.1)).cornerRadius(15)
                                
                                // GÜNCELLENDİ: HEDEF GİRİŞ ALANLARI (YAN YANA)
                                HStack(spacing: 15) {
                                    // SÜRE HEDEFİ
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text(t("daily_goal_title")).font(.caption2).bold().foregroundColor(.gray)
                                        TextField(t("minutes_placeholder"), text: $dailyGoalTime)
                                            .keyboardType(.numberPad)
                                            .padding()
                                            .background(Color(white: 0.15)).cornerRadius(12)
                                            .foregroundColor(.white)
                                    }
                                    
                                    // SORU HEDEFİ
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text(t("daily_goal_q_title")).font(.caption2).bold().foregroundColor(.gray)
                                        TextField(t("questions_placeholder"), text: $dailyGoalQuestion)
                                            .keyboardType(.numberPad)
                                            .padding()
                                            .background(Color(white: 0.15)).cornerRadius(12)
                                            .foregroundColor(.white)
                                    }
                                }
                                
                                VStack(alignment: .leading, spacing: 10) {
                                    Text(t("subtopics_title")).font(.caption).bold().foregroundColor(.gray)
                                    HStack {
                                        ZStack(alignment: .leading) {
                                            if newTopic.isEmpty {
                                                Text(t("add_topic_ph")).foregroundColor(Color(white: 0.5)).padding(.horizontal, 16)
                                            }
                                            TextField("", text: $newTopic)
                                                .padding().background(Color(white: 0.15)).cornerRadius(12)
                                                .foregroundColor(.white).submitLabel(.done)
                                                .onSubmit { addTopic() }
                                        }
                                        Button(action: addTopic) {
                                            Image(systemName: "plus").font(.title2).foregroundColor(.black)
                                                .frame(width: 50, height: 50).background(Color.white).cornerRadius(12)
                                        }
                                        .disabled(newTopic.trimmingCharacters(in: .whitespaces).isEmpty)
                                    }
                                    if !tempTopics.isEmpty {
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack {
                                                ForEach(tempTopics, id: \.self) { topic in
                                                    HStack(spacing: 5) {
                                                        Text(topic).font(.subheadline).fontWeight(.semibold)
                                                        Button(action: { removeTopic(topic) }) {
                                                            Image(systemName: "xmark.circle.fill").foregroundColor(.gray).font(.caption)
                                                        }
                                                    }
                                                    .padding(.horizontal, 12).padding(.vertical, 8)
                                                    .background(Color(white: 0.2)).cornerRadius(20).foregroundColor(.white)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.bottom, 10)
                            
                            Color.clear.frame(height: 50)
                        }
                        .padding()
                    }
                    .scrollDismissesKeyboard(.immediately) // Klavye hemen kapansın
                }
            }
            .navigationTitle("") // Standart başlığı boş bırakıyoruz
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                // SOL ÜST: Kapat
                ToolbarItem(placement: .cancellationAction) {
                    Button(t("close")) { dismiss() }.foregroundColor(.white)
                }
                
                // ORTA: Başlık (Tam Ortalamak İçin Principal Kullanıyoruz)
                ToolbarItem(placement: .principal) {
                    Text(subjectToEdit == nil ? t("new_subject_title") : t("edit_subject_title"))
                        .font(.headline)
                        .foregroundColor(.white)
                }
                
                // SAĞ ÜST: Ekle veya Güncelle
                ToolbarItem(placement: .confirmationAction) {
                    Button(subjectToEdit == nil ? t("add") : t("update")) {
                        saveOrUpdateSubject()
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(name.isEmpty ? .gray : .green)
                    .disabled(name.isEmpty)
                }
            }
        }
        .onAppear {
            if subjectToEdit != nil { isNameFocused = true }
        }
    }
    
    func addTopic() {
        let trimmed = newTopic.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty && !tempTopics.contains(trimmed) {
            withAnimation { tempTopics.append(trimmed) }
            newTopic = ""
        }
    }
    func removeTopic(_ topic: String) { withAnimation { tempTopics.removeAll { $0 == topic } } }
    
    func saveOrUpdateSubject() {
        guard !name.isEmpty else { return }
        let timeGoal = Int(dailyGoalTime) ?? 0
        let qGoal = Int(dailyGoalQuestion) ?? 0
        
        if let subject = subjectToEdit {
            subject.name = name
            subject.colorHex = selectedColor
            subject.knownTopics = tempTopics
            subject.dailyGoal = timeGoal
            subject.dailyGoalQuestion = qGoal
        } else {
            let newSubject = Subject(name: name, colorHex: selectedColor, isArchived: false, dailyGoal: timeGoal, dailyGoalQuestion: qGoal)
            newSubject.knownTopics = tempTopics
            context.insert(newSubject)
        }
    }
}

struct ColorSelectionCircle: View {
    let color: String; let isSelected: Bool
    var body: some View {
        ZStack {
            Circle().fill(color.toColor).frame(width: 50, height: 50).shadow(color: isSelected ? color.toColor.opacity(0.5) : .clear, radius: 10).scaleEffect(isSelected ? 1.15 : 1.0)
            if isSelected { Image(systemName: "checkmark").font(.headline).foregroundColor(isLightColor(color) ? .black : .white) }
        }
    }
    func isLightColor(_ colorName: String) -> Bool { return ["yellow", "lime", "cyan", "mint"].contains(colorName) }
}

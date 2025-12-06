import SwiftUI
import SwiftData

struct ReminderSheet: View {
    @Environment(\.dismiss) var dismiss
    @Bindable var subject: Subject
    @State private var selectedDate: Date
    
    init(subject: Subject) {
        self.subject = subject
        _selectedDate = State(initialValue: subject.reminderTime ?? Date())
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                // DÜZELTME: Spacing 40 -> 25'e düşürüldü. Elemanlar birbirine yaklaşsın.
                VStack(spacing: 25) {
                    // DÜZELTME: Spacing 15 -> 10
                    VStack(spacing: 10) {
                        // DÜZELTME: İkon boyutu 60 -> 50, üst boşluk 40 -> 20
                        Image(systemName: "bell.badge.fill")
                            .font(.system(size: 50))
                            .foregroundColor(subject.colorHex.toColor)
                            .padding(.top, 20)
                        
                        Text(t("reminder_title"))
                            .font(.title3) // title2 -> title3 (Biraz küçüldü)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text(String(format: t("reminder_desc"), subject.name))
                            .font(.caption)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center) // Çok satırlı olursa ortala
                            .padding(.horizontal)
                    }
                    
                    // DatePicker
                    DatePicker("", selection: $selectedDate, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .colorScheme(.dark)
                        .background(Color(white: 0.1))
                        .cornerRadius(15)
                        .padding(.horizontal, 40)
                    
                    // İptal Butonu
                    if subject.reminderTime != nil {
                        Button(action: removeReminder) {
                            Text(t("reminder_cancel_btn"))
                                .font(.headline)
                                .foregroundColor(.red)
                                .padding(.vertical, 12) // Buton yüksekliğini sabitle
                                .padding(.horizontal, 20)
                                .background(Color(white: 0.1))
                                .cornerRadius(10)
                        }
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle(t("reminder_select_time")) // LOCALIZED
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(t("cancel")) { dismiss() }.foregroundColor(.white) } // LOCALIZED
                ToolbarItem(placement: .confirmationAction) { Button(t("save")) { saveReminder() }.fontWeight(.bold).foregroundColor(subject.colorHex.toColor) } // LOCALIZED
            }
        }.presentationDetents([.medium]).presentationCornerRadius(25)
    }
    
    func saveReminder() {
        subject.reminderTime = selectedDate
        NotificationManager.shared.scheduleReminder(
            id: subject.id.uuidString,
            title: t("notif_title"), // LOCALIZED
            body: String(format: t("notif_body"), subject.name), // LOCALIZED Dynamic
            date: selectedDate
        )
        dismiss()
    }
    func removeReminder() {
        subject.reminderTime = nil
        NotificationManager.shared.cancelReminder(id: subject.id.uuidString)
        dismiss()
    }
}

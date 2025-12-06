import Foundation
import UserNotifications

class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    
    override init() {
        super.init()
        // Uygulama açıkken (Foreground) bildirim gelmesi için bu ayar şart
        UNUserNotificationCenter.current().delegate = self
    }
    
    // 1. İzin İste
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("✅ Bildirim izni verildi.")
            } else if let error = error {
                print("❌ Bildirim izni hatası: \(error.localizedDescription)")
            }
        }
    }
    
    // 2. Bildirim Planla (En güncel ve hatasız versiyon)
    func scheduleReminder(id: String, title: String, body: String, date: Date) {
        // Önce eski varsa silip temizleyelim
        cancelReminder(id: id)
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default
        
        // Tarihten sadece Saat ve Dakikayı al
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        
        // Her gün tekrarla (repeats: true)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Hata: Bildirim kurulamadı -> \(error)")
            } else {
                print("✅ Bildirim kuruldu: \(components.hour ?? 0):\(components.minute ?? 0)")
            }
        }
    }
    
    // 3. Bildirim İptal Et
    func cancelReminder(id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
        print("🗑️ Bildirim iptal edildi: \(id)")
    }
    
    // 4. Uygulama AÇIKKEN bildirimin görünmesini sağlayan fonksiyon
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Banner (üstten düşen kutu), Ses ve Liste olarak göster
        completionHandler([.banner, .sound, .list])
    }
}

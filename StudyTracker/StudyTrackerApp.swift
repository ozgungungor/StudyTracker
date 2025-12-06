import SwiftUI
import SwiftData
import CloudKit
import GoogleMobileAds
import AppTrackingTransparency // YENİ: ATT kütüphanesi

@main
struct StudyTrackerApp: App {
    // YENİ: Uygulama yaşam döngüsünü izlemek için daha performanslı yöntem
    @Environment(\.scenePhase) private var scenePhase
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Subject.self,
            StudyLog.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .private("iCloud.com.ozgun.StudyTracker")
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("ModelContainer oluşturulamadı: \(error)")
        }
    }()
    
    init() {
        // Reklam servisini başlat
        MobileAds.shared.start(completionHandler: nil)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
        // DÜZELTME: onReceive yerine daha hafif olan onChange(of: scenePhase) kullanıldı
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                // UI'ı bloklamamak için işlemi arka plana atıp, gecikmeli olarak ana thread'e alıyoruz
                DispatchQueue.global(qos: .background).async {
                    // Sadece izin durumu "Belirlenmemiş" ise ana thread'i rahatsız et
                    if ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            ATTrackingManager.requestTrackingAuthorization { status in
                                // Sonuçları konsola yaz (Debug için)
                                switch status {
                                case .authorized: print("✅ Takip izni verildi.")
                                case .denied: print("❌ Takip izni reddedildi.")
                                default: break
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

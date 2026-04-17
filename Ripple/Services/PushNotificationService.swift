import UIKit
import UserNotifications
import FirebaseAuth
import FirebaseFirestore

final class PushNotificationService {

    // MARK: - Singleton

    static let shared = PushNotificationService()
    private init() {}

    private let db = Firestore.firestore()

    // MARK: - Request Permission

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound]
        ) { granted, error in
            if let error {
                print("Push permission error: \(error.localizedDescription)")
                return
            }
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }

    // MARK: - FCM Token

    /// Вызывается из AppDelegate когда Firebase присылает новый FCM token
    func updateFCMToken(_ token: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("users").document(uid).updateData(["fcmToken": token]) { error in
            if let error {
                print("FCM token update error: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Badge

    func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0)
    }
}

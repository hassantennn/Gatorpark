import Foundation
import UserNotifications

final class NotificationPermissionManager {
    static let shared = NotificationPermissionManager()
    private let center = UNUserNotificationCenter.current()
    private init() {}

    func requestAuthorizationIfNeeded() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: AppStorageKey.hasRequestedNotificationPermission) else { return }

        center.requestAuthorization(options: [.alert, .sound]) { [weak self] _, error in
            if let error = error {
                print("⚠️ Notification authorization error:", error.localizedDescription)
            }
            defaults.set(true, forKey: AppStorageKey.hasRequestedNotificationPermission)
            if let self {
                self.center.getNotificationSettings { settings in
                    print("🔔 Notification settings:", settings.authorizationStatus.rawValue)
                }
            }
        }
    }
}

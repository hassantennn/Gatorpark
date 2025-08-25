import UIKit
import UserNotifications
import FirebaseCore
import FirebaseAuth
import FirebaseAppCheck

#if DEBUG
class DebugAppCheckProviderFactory: NSObject, AppCheckProviderFactory {
    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
        return AppCheckDebugProvider(app: app)
    }
}
#endif

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    private let notificationCenter = UNUserNotificationCenter.current()

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        #if DEBUG
        AppCheck.setAppCheckProviderFactory(DebugAppCheckProviderFactory())
        #endif
        
        FirebaseApp.configure()

        if Auth.auth().currentUser == nil {
            Auth.auth().signInAnonymously { result, error in
                if let error = error {
                    // 🔎 Print the full error, not just localizedDescription
                    print("❌ Firebase Auth error:", error)
                } else if let user = result?.user {
                    print("✅ Signed in anonymously with UID: \(user.uid)")
                }
            }
        }

        notificationCenter.requestAuthorization(options: [.alert, .sound]) { _, _ in }
        notificationCenter.delegate = self
        return true
    }

    // MARK: UISceneSession Lifecycle
    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Release any resources tied to discarded scenes if needed
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}

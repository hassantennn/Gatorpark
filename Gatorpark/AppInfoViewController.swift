import UIKit
import FirebaseAuth
import UserNotifications

final class AppInfoViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "About GatorPark"
        view.backgroundColor = .systemBackground
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done,
                                                            target: self,
                                                            action: #selector(dismissSelf))
        configureLayout()
    }

    private func configureLayout() {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false

        let summaryLabel = UILabel()
        summaryLabel.text = "GatorPark helps you find open parking garages around the University of Florida."
        summaryLabel.numberOfLines = 0
        summaryLabel.font = UIFont.preferredFont(forTextStyle: .body)

        let privacyButton = makeNavigationButton(title: "Privacy Policy") { [weak self] in
            self?.showDocument(PrivacyPolicyViewController())
        }
        let termsButton = makeNavigationButton(title: "Terms of Use") { [weak self] in
            self?.showDocument(TermsOfUseViewController())
        }

        let deleteAccountButton = makeDestructiveButton(title: "Delete Account") { [weak self] in
            self?.confirmAccountDeletion()
        }

        let supportButton = UIButton(type: .system)
        supportButton.setTitle("Contact Support", for: .normal)
        supportButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
        supportButton.contentHorizontalAlignment = .leading
        supportButton.addTarget(self, action: #selector(contactSupport), for: .touchUpInside)

        let footerLabel = UILabel()
        footerLabel.text = "Version 1.0"
        footerLabel.textColor = .secondaryLabel
        footerLabel.font = UIFont.preferredFont(forTextStyle: .footnote)

        stack.addArrangedSubview(summaryLabel)
        stack.addArrangedSubview(privacyButton)
        stack.addArrangedSubview(termsButton)
        stack.addArrangedSubview(deleteAccountButton)
        stack.addArrangedSubview(supportButton)
        stack.addArrangedSubview(footerLabel)

        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24)
        ])
    }

    private func makeNavigationButton(title: String, action: @escaping () -> Void) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.contentHorizontalAlignment = .leading
        button.addAction(UIAction { _ in
            action()
        }, for: .touchUpInside)
        return button
    }

    private func makeDestructiveButton(title: String, action: @escaping () -> Void) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.systemRed, for: .normal)
        button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .body)
        button.contentHorizontalAlignment = .leading
        button.addAction(UIAction { _ in
            action()
        }, for: .touchUpInside)
        return button
    }

    private func showDocument(_ viewController: UIViewController) {
        if let navigationController {
            navigationController.pushViewController(viewController, animated: true)
        } else {
            let nav = UINavigationController(rootViewController: viewController)
            present(nav, animated: true)
        }
    }

    @objc private func contactSupport() {
        guard let url = URL(string: "mailto:hassantariq233@gmail.com") else { return }
        UIApplication.shared.open(url)
    }

    private func confirmAccountDeletion() {
        let alert = UIAlertController(title: "Delete Account",
                                      message: "Deleting your account removes your parking history and notification reminders from our servers. This cannot be undone.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.deleteAccount()
        })
        present(alert, animated: true)
    }

    private func deleteAccount() {
        guard let user = Auth.auth().currentUser else {
            showSimpleAlert(title: "Account Not Found",
                            message: "We couldn't locate your account. Please restart the app and try again.")
            return
        }

        let progress = UIAlertController(title: nil,
                                         message: "Deleting account...",
                                         preferredStyle: .alert)
        present(progress, animated: true)

        user.delete { [weak self] error in
            DispatchQueue.main.async {
                progress.dismiss(animated: true) {
                    guard let self else { return }
                    if let error = error as NSError? {
                        if error.code == AuthErrorCode.requiresRecentLogin.rawValue {
                            self.showSimpleAlert(title: "Try Again",
                                                  message: "For your security, please sign in again before deleting your account.")
                        } else {
                            self.showSimpleAlert(title: "Deletion Failed",
                                                  message: error.localizedDescription)
                        }
                    } else {
                        self.clearLocalDataAfterAccountDeletion()
                        self.showSimpleAlert(title: "Account Deleted",
                                             message: "Your account has been deleted. You can continue using GatorPark as a new user.")
                    }
                }
            }
        }
    }

    private func clearLocalDataAfterAccountDeletion() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: AppStorageKey.hasCompletedOnboarding)
        defaults.removeObject(forKey: AppStorageKey.hasRequestedNotificationPermission)

        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()

        do {
            try Auth.auth().signOut()
        } catch {
            print("⚠️ Sign out after deletion failed:", error.localizedDescription)
        }
    }

    private func showSimpleAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    @objc private func dismissSelf() {
        dismiss(animated: true)
    }
}

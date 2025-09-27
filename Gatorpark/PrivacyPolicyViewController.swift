import UIKit

final class PrivacyPolicyViewController: UIViewController {
    private let privacyText = """
GatorPark Privacy Policy

Last updated: June 5, 2024

GatorPark values your privacy. This policy explains how we collect, use, and protect your information.

Information We Collect
• Location information to show nearby parking garages when you grant permission.
• App usage data to help us improve performance and reliability.

How We Use Information
We use your information to provide core features like finding open garages, to troubleshoot issues, and to improve the app experience.

Data Sharing
We do not sell your personal information. We only share data with service providers who support app functionality and are bound to protect it.

Your Choices
You may revoke location permissions at any time from your device settings. You can also delete the app to remove local data stored on your device.

Contact Us
If you have any questions about this policy, email us at hassantariq233@gmail.com.
"""

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Privacy Policy"
        view.backgroundColor = .systemBackground
        navigationItem.largeTitleDisplayMode = .never
        configureTextView()
    }

    private func configureTextView() {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isEditable = false
        textView.alwaysBounceVertical = true
        textView.backgroundColor = .clear
        textView.text = privacyText
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.textColor = .label
        textView.textContainerInset = UIEdgeInsets(top: 24, left: 20, bottom: 24, right: 20)

        view.addSubview(textView)
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            textView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

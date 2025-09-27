import UIKit

final class TermsOfUseViewController: UIViewController {
    private let termsText = """
GatorPark Terms of Use

Last updated: June 5, 2024

By using GatorPark you agree to the following terms.

1. Acceptable Use
You may use the app to locate parking garages for personal, non-commercial purposes. You agree not to misuse the service or interfere with its operation.

2. Account Responsibilities
You are responsible for maintaining the security of your device and any credentials associated with third-party services you connect to the app.

3. Service Availability
We strive to keep the app reliable, but availability is not guaranteed. Features may change or be discontinued without notice.

4. Limitation of Liability
GatorPark provides parking information as-is. We are not responsible for inaccurate garage data, parking tickets, or other damages arising from use of the app.

5. Changes to These Terms
We may update these terms from time to time. Continued use of the app after changes become effective constitutes acceptance of the revised terms.

Contact Us
If you have questions about these terms, email hassantariq233@gmail.com.
"""

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Terms of Use"
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
        textView.text = termsText
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

import UIKit
import SafariServices

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

        let privacyButton = makeLinkButton(title: "Privacy Policy",
                                           urlString: "https://gatorpark.example.com/privacy")
        let termsButton = makeLinkButton(title: "Terms of Use",
                                         urlString: "https://gatorpark.example.com/terms")

        let supportButton = UIButton(type: .system)
        supportButton.setTitle("Contact Support", for: .normal)
        supportButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
        supportButton.addTarget(self, action: #selector(contactSupport), for: .touchUpInside)

        let footerLabel = UILabel()
        footerLabel.text = "Version 1.0"
        footerLabel.textColor = .secondaryLabel
        footerLabel.font = UIFont.preferredFont(forTextStyle: .footnote)

        stack.addArrangedSubview(summaryLabel)
        stack.addArrangedSubview(privacyButton)
        stack.addArrangedSubview(termsButton)
        stack.addArrangedSubview(supportButton)
        stack.addArrangedSubview(footerLabel)

        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24)
        ])
    }

    private func makeLinkButton(title: String, urlString: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.contentHorizontalAlignment = .leading
        button.addAction(UIAction { [weak self] _ in
            guard let url = URL(string: urlString) else { return }
            let safari = SFSafariViewController(url: url)
            self?.present(safari, animated: true)
        }, for: .touchUpInside)
        return button
    }

    @objc private func contactSupport() {
        guard let url = URL(string: "mailto:support@gatorpark.example.com") else { return }
        UIApplication.shared.open(url)
    }

    @objc private func dismissSelf() {
        dismiss(animated: true)
    }
}

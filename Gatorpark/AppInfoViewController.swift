import UIKit

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

    private func makeNavigationButton(title: String, action: @escaping () -> Void) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
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

    @objc private func dismissSelf() {
        dismiss(animated: true)
    }
}

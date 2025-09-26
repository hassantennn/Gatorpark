import UIKit
import SafariServices

final class OnboardingViewController: UIViewController {
    var completion: (() -> Void)?

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        isModalInPresentation = true
        configureLayout()
    }

    private func configureLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])

        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])

        let titleLabel = UILabel()
        titleLabel.text = "Welcome to GatorPark"
        titleLabel.font = UIFont.preferredFont(forTextStyle: .largeTitle)
        titleLabel.numberOfLines = 0

        let subtitleLabel = UILabel()
        subtitleLabel.text = "Before you start, please review how we handle your data."
        subtitleLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        subtitleLabel.numberOfLines = 0

        let locationLabel = makeBodyLabel(text: "• Location access allows us to show garages near you.")
        let notificationLabel = makeBodyLabel(text: "• Notifications remind you to check out when your parking session is almost over.")
        let privacyLabel = makeBodyLabel(text: "We respect your privacy and only collect the minimum information needed to operate the app.")

        let privacyButton = makeLinkButton(title: "View Privacy Policy", urlString: "https://gatorpark.example.com/privacy")
        let termsButton = makeLinkButton(title: "View Terms of Use", urlString: "https://gatorpark.example.com/terms")

        let continueButton = UIButton(type: .system)
        continueButton.setTitle("I Understand", for: .normal)
        continueButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
        continueButton.backgroundColor = .systemBlue
        continueButton.setTitleColor(.white, for: .normal)
        continueButton.layer.cornerRadius = 12
        continueButton.contentEdgeInsets = UIEdgeInsets(top: 14, left: 24, bottom: 14, right: 24)
        continueButton.addTarget(self, action: #selector(didTapContinue), for: .touchUpInside)
        continueButton.translatesAutoresizingMaskIntoConstraints = false

        contentStack.setCustomSpacing(12, after: subtitleLabel)
        contentStack.setCustomSpacing(24, after: termsButton)

        contentStack.addArrangedSubview(titleLabel)
        contentStack.addArrangedSubview(subtitleLabel)
        contentStack.addArrangedSubview(locationLabel)
        contentStack.addArrangedSubview(notificationLabel)
        contentStack.addArrangedSubview(privacyLabel)
        contentStack.addArrangedSubview(privacyButton)
        contentStack.addArrangedSubview(termsButton)
        contentStack.addArrangedSubview(continueButton)

        continueButton.widthAnchor.constraint(equalTo: contentStack.widthAnchor).isActive = true
    }

    private func makeBodyLabel(text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.numberOfLines = 0
        return label
    }

    private func makeLinkButton(title: String, urlString: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .body)
        button.contentHorizontalAlignment = .leading
        button.addAction(UIAction { [weak self] _ in
            guard let url = URL(string: urlString) else { return }
            let safari = SFSafariViewController(url: url)
            self?.present(safari, animated: true)
        }, for: .touchUpInside)
        return button
    }

    @objc private func didTapContinue() {
        UserDefaults.standard.set(true, forKey: AppStorageKey.hasCompletedOnboarding)
        dismiss(animated: true) { [weak self] in
            self?.completion?()
        }
    }
}

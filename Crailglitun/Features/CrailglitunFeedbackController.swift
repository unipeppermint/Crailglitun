import UIKit
import MessageUI

final class CrailglitunFeedbackController: UIViewController,
    UITextFieldDelegate, UITextViewDelegate, MFMailComposeViewControllerDelegate {
    private let supportEmail = "cressidal@trademarkroofing.homes"
    private let emailField = UITextField()
    private let descriptionField = UITextView()
    private let placeholder = label("Tell us what you think…", 16, .regular, Palette.secondary)
    private let validationLabel = label("", 13, .regular, .systemRed)
    private let scrollView = UIScrollView()

    private lazy var submitButton = button("Submit Feedback", icon: "paperplane", filled: true) { [weak self] in
        self?.submitFeedback()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Feedback"
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = Palette.background
        configureFields()
        configureLayout()
    }

    private func configureFields() {
        emailField.placeholder = "your@email.com"
        emailField.accessibilityLabel = "Your email address"
        emailField.keyboardType = .emailAddress
        emailField.textContentType = .emailAddress
        emailField.autocapitalizationType = .none
        emailField.autocorrectionType = .no
        emailField.spellCheckingType = .no
        emailField.clearButtonMode = .whileEditing
        emailField.returnKeyType = .next
        emailField.font = .preferredFont(forTextStyle: .body)
        emailField.adjustsFontForContentSizeCategory = true
        emailField.textColor = Palette.ink
        emailField.delegate = self
        emailField.heightAnchor.constraint(greaterThanOrEqualToConstant: 30).isActive = true
        emailField.addTarget(self, action: #selector(clearValidation), for: .editingChanged)

        descriptionField.delegate = self
        descriptionField.font = .preferredFont(forTextStyle: .body)
        descriptionField.adjustsFontForContentSizeCategory = true
        descriptionField.textColor = Palette.ink
        descriptionField.backgroundColor = .clear
        descriptionField.textContainerInset = UIEdgeInsets(top: 4, left: 0, bottom: 8, right: 0)
        descriptionField.textContainer.lineFragmentPadding = 0
        descriptionField.accessibilityLabel = "Feedback description"
        descriptionField.heightAnchor.constraint(equalToConstant: 240).isActive = true

        placeholder.isUserInteractionEnabled = false
        placeholder.isAccessibilityElement = false
        placeholder.translatesAutoresizingMaskIntoConstraints = false
        descriptionField.addSubview(placeholder)
        NSLayoutConstraint.activate([
            placeholder.topAnchor.constraint(equalTo: descriptionField.frameLayoutGuide.topAnchor, constant: 4),
            placeholder.leadingAnchor.constraint(equalTo: descriptionField.frameLayoutGuide.leadingAnchor),
            placeholder.trailingAnchor.constraint(equalTo: descriptionField.frameLayoutGuide.trailingAnchor)
        ])

        let toolbar = UIToolbar()
        toolbar.items = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissKeyboard))
        ]
        toolbar.sizeToFit()
        emailField.inputAccessoryView = toolbar
        descriptionField.inputAccessoryView = toolbar
    }

    private func configureLayout() {
        scrollView.keyboardDismissMode = .interactive
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        let emailSection = stack([
            label("EMAIL ADDRESS", 13, .semibold, Palette.secondary),
            card(emailField)
        ], spacing: 10)
        let descriptionSection = stack([
            label("DESCRIPTION", 13, .semibold, Palette.secondary),
            card(descriptionField)
        ], spacing: 10)
        validationLabel.isHidden = true
        let form = stack([
            label("Have an idea or need help? We’d love to hear from you.", 15, .regular, Palette.secondary),
            emailSection,
            descriptionSection,
            validationLabel
        ], spacing: 24)
        form.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(form)

        let deliveryNote = label(
            "Review and send your feedback in the email draft that opens next.",
            12,
            .regular,
            Palette.secondary
        )
        deliveryNote.textAlignment = .center
        let copyButton = UIButton(type: .system)
        copyButton.setTitle("Copy Support Email", for: .normal)
        copyButton.titleLabel?.font = .preferredFont(forTextStyle: .footnote)
        copyButton.titleLabel?.adjustsFontForContentSizeCategory = true
        copyButton.tintColor = Palette.teal
        copyButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        copyButton.addAction(UIAction { [weak self] _ in
            guard let self = self else { return }
            UIPasteboard.general.string = self.supportEmail
            self.notify("Email Address Copied", self.supportEmail)
        }, for: .touchUpInside)

        let footer = stack([submitButton, deliveryNote, copyButton], spacing: 8)
        footer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(footer)

        let safeArea = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: safeArea.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: footer.topAnchor, constant: -12),
            form.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 24),
            form.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -16),
            form.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 20),
            form.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -20),
            form.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -40),
            footer.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 20),
            footer.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -20),
            footer.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor, constant: -8)
        ])
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc private func clearValidation() {
        validationLabel.isHidden = true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        descriptionField.becomeFirstResponder()
        return false
    }

    func textViewDidChange(_ textView: UITextView) {
        placeholder.isHidden = !textView.text.isEmpty
        clearValidation()
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        scrollView.scrollRectToVisible(textView.convert(textView.bounds, to: scrollView), animated: true)
    }

    private func showValidation(_ message: String, field: UIView) {
        validationLabel.text = message
        validationLabel.isHidden = false
        field.becomeFirstResponder()
        view.layoutIfNeeded()
        scrollView.scrollRectToVisible(validationLabel.convert(validationLabel.bounds, to: scrollView), animated: true)
        UIAccessibility.post(notification: .announcement, argument: message)
    }

    private func submitFeedback() {
        let email = (emailField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let description = descriptionField.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let emailPattern = #"^[^\s@]+@[^\s@.]+(?:\.[^\s@.]+)+$"#
        guard email.count <= 254, email.range(of: emailPattern, options: .regularExpression) != nil else {
            showValidation("Please enter a valid email address so we can reply.", field: emailField)
            return
        }
        guard !description.isEmpty else {
            showValidation("Please describe your feedback before submitting.", field: descriptionField)
            return
        }
        guard description.count <= 5000 else {
            showValidation("Please keep your feedback within 5,000 characters.", field: descriptionField)
            return
        }

        view.endEditing(true)
        clearValidation()
        let message = "Reply contact: \(email)\n\nFeedback:\n\(description)"
        if MFMailComposeViewController.canSendMail() {
            let composer = MFMailComposeViewController()
            composer.mailComposeDelegate = self
            composer.setToRecipients([supportEmail])
            composer.setSubject("TurnScene Feedback")
            composer.setMessageBody(message, isHTML: false)
            present(composer, animated: true)
        } else {
            openExternalEmail(message: message)
        }
    }

    private func openExternalEmail(message: String) {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = supportEmail
        components.queryItems = [
            URLQueryItem(name: "subject", value: "TurnScene Feedback"),
            URLQueryItem(name: "body", value: message)
        ]
        guard let url = components.url else {
            showEmailUnavailable(message: message)
            return
        }

        submitButton.isEnabled = false
        UIApplication.shared.open(url, options: [:]) { [weak self] opened in
            guard let self = self else { return }
            self.submitButton.isEnabled = true
            if !opened {
                self.showEmailUnavailable(message: message)
            }
        }
    }

    private func showEmailUnavailable(message: String) {
        let alert = UIAlertController(
            title: "Unable to Open Email",
            message: "Your feedback is still here. Copy it and send it to \(supportEmail) using your preferred email service.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Copy Feedback & Email", style: .default) { [weak self] _ in
            guard let self = self else { return }
            UIPasteboard.general.string = "To: \(self.supportEmail)\nSubject: TurnScene Feedback\n\n\(message)"
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    func mailComposeController(
        _ controller: MFMailComposeViewController,
        didFinishWith result: MFMailComposeResult,
        error: Error?
    ) {
        controller.dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            if result == .failed || error != nil {
                self.notify("Email Could Not Be Sent", "Your feedback is still here. Please try again or copy the support email.")
            } else if result == .sent {
                self.emailField.text = ""
                self.descriptionField.text = ""
                self.placeholder.isHidden = false
                self.notify("Thank You", "Your feedback has been handed to Mail for sending.")
            }
        }
    }
}

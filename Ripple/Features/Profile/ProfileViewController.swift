import UIKit
import FirebaseAuth
import FirebaseFirestore

final class ProfileViewController: UIViewController {

    // MARK: - Callbacks

    var onLogout: (() -> Void)?

    // MARK: - Private

    private let db = Firestore.firestore()
    private var currentName: String = ""

    // MARK: - UI

    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 50
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 22, weight: .semibold)
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let emailLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 15)
        l.textColor = .secondaryLabel
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var editNameButton: UIButton = {
        var config = UIButton.Configuration.tinted()
        config.title = "Изменить имя"
        config.image = UIImage(systemName: "pencil")
        config.imagePadding = 6
        config.cornerStyle = .medium
        let btn = UIButton(configuration: config)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(editNameTapped), for: .touchUpInside)
        return btn
    }()

    private lazy var logoutButton: UIButton = {
        var config = UIButton.Configuration.tinted()
        config.title = "Выйти из аккаунта"
        config.image = UIImage(systemName: "rectangle.portrait.and.arrow.right")
        config.imagePadding = 6
        config.cornerStyle = .medium
        config.baseBackgroundColor = .systemRed
        config.baseForegroundColor = .systemRed
        let btn = UIButton(configuration: config)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(logoutTapped), for: .touchUpInside)
        return btn
    }()

    private let divider: UIView = {
        let v = UIView()
        v.backgroundColor = .separator
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadUserData()
    }

    // MARK: - Setup

    private func setupUI() {
        title = "Профиль"
        view.backgroundColor = .systemGroupedBackground
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeTapped)
        )

        let stack = UIStackView(arrangedSubviews: [
            avatarImageView, nameLabel, emailLabel,
            editNameButton, divider, logoutButton
        ])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.setCustomSpacing(8, after: nameLabel)
        stack.setCustomSpacing(24, after: emailLabel)
        stack.setCustomSpacing(24, after: editNameButton)
        stack.setCustomSpacing(24, after: divider)

        view.addSubview(stack)

        NSLayoutConstraint.activate([
            avatarImageView.widthAnchor.constraint(equalToConstant: 100),
            avatarImageView.heightAnchor.constraint(equalToConstant: 100),

            divider.widthAnchor.constraint(equalTo: stack.widthAnchor),
            divider.heightAnchor.constraint(equalToConstant: 0.5),

            editNameButton.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -48),
            logoutButton.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -48),

            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 32),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    private func loadUserData() {
        guard let user = Auth.auth().currentUser else { return }
        let name = user.displayName ?? user.email ?? "Пользователь"
        currentName = name
        nameLabel.text = name
        emailLabel.text = user.email
        avatarImageView.setInitialsAvatar(name: name, size: 100)
    }

    // MARK: - Actions

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    @objc private func editNameTapped() {
        let alert = UIAlertController(title: "Изменить имя", message: nil, preferredStyle: .alert)
        alert.addTextField { [weak self] tf in
            tf.text = self?.currentName
            tf.autocapitalizationType = .words
        }
        alert.addAction(UIAlertAction(title: "Сохранить", style: .default) { [weak self] _ in
            guard let self,
                  let newName = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespaces),
                  !newName.isEmpty
            else { return }
            self.saveName(newName)
        })
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        present(alert, animated: true)
    }

    @objc private func logoutTapped() {
        showConfirmAlert(
            title: "Выйти из аккаунта?",
            message: "Вы уверены?",
            confirmTitle: "Выйти"
        ) { [weak self] in
            self?.performLogout()
        }
    }

    // MARK: - Helpers

    private func saveName(_ name: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        showSpinner()

        // Обновляем в Firestore
        db.collection("users").document(uid).updateData(["displayName": name]) { [weak self] error in
            self?.hideSpinner()
            if let error {
                self?.showAlert(title: "Ошибка", message: error.localizedDescription)
                return
            }
            self?.currentName = name
            self?.nameLabel.text = name
            self?.avatarImageView.setInitialsAvatar(name: name, size: 100)
        }
    }

    private func performLogout() {
        do {
            try AuthService().signOut()
            dismiss(animated: true) { [weak self] in
                self?.onLogout?()
            }
        } catch {
            showAlert(title: "Ошибка", message: error.localizedDescription)
        }
    }
}

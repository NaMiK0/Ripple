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

    private let headerCard: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.clipsToBounds = true
        return v
    }()

    private var headerGradient: CAGradientLayer?

    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 48
        iv.layer.cornerCurve = .continuous
        iv.layer.borderWidth = 3
        iv.layer.borderColor = UIColor.white.withAlphaComponent(0.6).cgColor
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 22, weight: .bold)
        l.textColor = .white
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let emailLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14)
        l.textColor = UIColor.white.withAlphaComponent(0.75)
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let contentCard: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.systemBackground
        v.layer.cornerRadius = 28
        v.layer.cornerCurve = .continuous
        v.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private lazy var editNameButton: RippleActionRow = {
        RippleActionRow(
            icon: "pencil.circle.fill",
            iconColor: .ripplePrimary,
            title: "Изменить имя",
            action: { [weak self] in self?.editNameTapped() }
        )
    }()

    private lazy var logoutButton: RippleActionRow = {
        RippleActionRow(
            icon: "rectangle.portrait.and.arrow.right",
            iconColor: UIColor(hex: "#ED4245"),
            title: "Выйти из аккаунта",
            textColor: UIColor(hex: "#ED4245"),
            action: { [weak self] in self?.logoutTapped() }
        )
    }()

    private let versionLabel: UILabel = {
        let l = UILabel()
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        l.text = "Ripple v\(version)"
        l.font = .systemFont(ofSize: 12)
        l.textColor = .rippleTextSecondary
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadUserData()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if headerGradient == nil {
            let g = CAGradientLayer.rippleHero(frame: headerCard.bounds)
            headerCard.layer.insertSublayer(g, at: 0)
            headerGradient = g
        } else {
            headerGradient?.frame = headerCard.bounds
        }
    }

    // MARK: - Setup

    private func setupUI() {
        title = "Профиль"
        view.backgroundColor = .rippleBackground
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeTapped)
        )

        view.addSubview(headerCard)
        headerCard.addSubview(avatarImageView)
        headerCard.addSubview(nameLabel)
        headerCard.addSubview(emailLabel)

        view.addSubview(contentCard)

        let divider = makeDivider()
        let actionStack = UIStackView(arrangedSubviews: [editNameButton, divider, logoutButton])
        actionStack.axis = .vertical
        actionStack.spacing = 0
        actionStack.translatesAutoresizingMaskIntoConstraints = false

        contentCard.addSubview(actionStack)
        contentCard.addSubview(versionLabel)

        NSLayoutConstraint.activate([
            headerCard.topAnchor.constraint(equalTo: view.topAnchor),
            headerCard.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerCard.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerCard.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.38),

            avatarImageView.centerXAnchor.constraint(equalTo: headerCard.centerXAnchor),
            avatarImageView.centerYAnchor.constraint(equalTo: headerCard.centerYAnchor, constant: -20),
            avatarImageView.widthAnchor.constraint(equalToConstant: 96),
            avatarImageView.heightAnchor.constraint(equalToConstant: 96),

            nameLabel.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 12),
            nameLabel.leadingAnchor.constraint(equalTo: headerCard.leadingAnchor, constant: 24),
            nameLabel.trailingAnchor.constraint(equalTo: headerCard.trailingAnchor, constant: -24),

            emailLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            emailLabel.leadingAnchor.constraint(equalTo: headerCard.leadingAnchor, constant: 24),
            emailLabel.trailingAnchor.constraint(equalTo: headerCard.trailingAnchor, constant: -24),

            contentCard.topAnchor.constraint(equalTo: headerCard.bottomAnchor, constant: -24),
            contentCard.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentCard.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentCard.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            actionStack.topAnchor.constraint(equalTo: contentCard.topAnchor, constant: 32),
            actionStack.leadingAnchor.constraint(equalTo: contentCard.leadingAnchor),
            actionStack.trailingAnchor.constraint(equalTo: contentCard.trailingAnchor),

            versionLabel.bottomAnchor.constraint(equalTo: contentCard.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            versionLabel.centerXAnchor.constraint(equalTo: contentCard.centerXAnchor)
        ])
    }

    private func makeDivider() -> UIView {
        let v = UIView()
        v.backgroundColor = UIColor.rippleTextSecondary.withAlphaComponent(0.15)
        v.translatesAutoresizingMaskIntoConstraints = false
        v.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        return v
    }

    private func loadUserData() {
        guard let user = Auth.auth().currentUser else { return }
        let name = user.displayName ?? user.email ?? "Пользователь"
        currentName = name
        nameLabel.text = name
        emailLabel.text = user.email
        avatarImageView.setInitialsAvatar(name: name, size: 96)
    }

    // MARK: - Actions

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    private func editNameTapped() {
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

    private func logoutTapped() {
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
        db.collection("users").document(uid).updateData(["displayName": name]) { [weak self] error in
            self?.hideSpinner()
            if let error {
                self?.showAlert(title: "Ошибка", message: error.localizedDescription)
                return
            }
            self?.currentName = name
            self?.nameLabel.text = name
            self?.avatarImageView.setInitialsAvatar(name: name, size: 96)
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

// MARK: - RippleActionRow

/// Строка-кнопка в стиле настроек iOS с иконкой и заголовком
private final class RippleActionRow: UIView {

    private let action: () -> Void

    init(icon: String, iconColor: UIColor, title: String,
         textColor: UIColor = .rippleTextPrimary, action: @escaping () -> Void) {
        self.action = action
        super.init(frame: .zero)

        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 56).isActive = true

        let iconBg = UIView()
        iconBg.backgroundColor = iconColor.withAlphaComponent(0.12)
        iconBg.layer.cornerRadius = 10
        iconBg.translatesAutoresizingMaskIntoConstraints = false

        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.tintColor = iconColor
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false

        iconBg.addSubview(iconView)

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = textColor
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = UIColor.rippleTextSecondary.withAlphaComponent(0.5)
        chevron.contentMode = .scaleAspectFit
        chevron.translatesAutoresizingMaskIntoConstraints = false

        addSubview(iconBg)
        addSubview(titleLabel)
        addSubview(chevron)

        NSLayoutConstraint.activate([
            iconBg.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            iconBg.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconBg.widthAnchor.constraint(equalToConstant: 36),
            iconBg.heightAnchor.constraint(equalToConstant: 36),

            iconView.centerXAnchor.constraint(equalTo: iconBg.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconBg.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 18),
            iconView.heightAnchor.constraint(equalToConstant: 18),

            titleLabel.leadingAnchor.constraint(equalTo: iconBg.trailingAnchor, constant: 14),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            chevron.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            chevron.centerYAnchor.constraint(equalTo: centerYAnchor),
            chevron.widthAnchor.constraint(equalToConstant: 12),
            chevron.heightAnchor.constraint(equalToConstant: 12)
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
        addGestureRecognizer(tap)
        isUserInteractionEnabled = true
    }

    required init?(coder: NSCoder) { fatalError() }

    @objc private func tapped() {
        UIView.animate(withDuration: 0.08, animations: {
            self.alpha = 0.5
        }) { _ in
            UIView.animate(withDuration: 0.12) {
                self.alpha = 1.0
            }
        }
        action()
    }
}

import UIKit
import Combine

final class AuthViewController: UIViewController {

    // MARK: - Properties

    private let viewModel: AuthViewModel
    private var cancellables = Set<AnyCancellable>()
    private var gradientLayer: CAGradientLayer?
    private var submitGradient: CAGradientLayer?

    // MARK: - Hero Section

    private let heroView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.clipsToBounds = true
        return v
    }()

    private let logoContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        v.layer.cornerRadius = 28
        v.layer.cornerCurve = .continuous
        return v
    }()

    private let logoImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "bubble.left.and.bubble.right.fill"))
        iv.tintColor = .white
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let appNameLabel: UILabel = {
        let l = UILabel()
        l.text = "Ripple"
        l.font = .systemFont(ofSize: 36, weight: .bold)
        l.textColor = .white
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let taglineLabel: UILabel = {
        let l = UILabel()
        l.text = "Общайся свободно"
        l.font = .systemFont(ofSize: 16)
        l.textColor = UIColor.white.withAlphaComponent(0.85)
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // MARK: - Card

    private let cardView: UIView = {
        let v = UIView()
        v.backgroundColor = .rippleCard
        v.layer.cornerRadius = 32
        v.layer.cornerCurve = .continuous
        v.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        v.translatesAutoresizingMaskIntoConstraints = false
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.08
        v.layer.shadowOffset = CGSize(width: 0, height: -4)
        v.layer.shadowRadius = 16
        return v
    }()

    private let modeLabel: UILabel = {
        let l = UILabel()
        l.text = "Добро пожаловать"
        l.font = .systemFont(ofSize: 24, weight: .bold)
        l.textColor = .rippleTextPrimary
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let segmentedControl: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["Войти", "Регистрация"])
        sc.selectedSegmentIndex = 0
        sc.selectedSegmentTintColor = .ripplePrimary
        sc.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        sc.setTitleTextAttributes([.foregroundColor: UIColor.rippleTextSecondary], for: .normal)
        sc.backgroundColor = .rippleSurface
        sc.translatesAutoresizingMaskIntoConstraints = false
        return sc
    }()

    private let nameField    = AuthTextField(placeholder: "Имя",    icon: "person",   isSecure: false)
    private let emailField   = AuthTextField(placeholder: "Email",   icon: "envelope", isSecure: false)
    private let passwordField = AuthTextField(placeholder: "Пароль", icon: "lock",     isSecure: true)

    private let submitButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle("Войти", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        btn.setTitleColor(.white, for: .normal)
        btn.setTitleColor(UIColor.white.withAlphaComponent(0.5), for: .disabled)
        btn.layer.cornerRadius = 16
        btn.layer.cornerCurve = .continuous
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let ai = UIActivityIndicatorView(style: .medium)
        ai.color = .white
        ai.hidesWhenStopped = true
        ai.translatesAutoresizingMaskIntoConstraints = false
        return ai
    }()

    private let errorLabel: UILabel = {
        let l = UILabel()
        l.textColor = UIColor(hex: "#E74C3C")
        l.font = .systemFont(ofSize: 13)
        l.numberOfLines = 0
        l.textAlignment = .center
        l.isHidden = true
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let fieldsStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 12
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let topStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 16
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    // MARK: - Init

    init(viewModel: AuthViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
        bindViewModel()
        observeKeyboard()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer?.frame = heroView.bounds
        submitGradient?.frame = submitButton.bounds
        submitGradient?.cornerRadius = submitButton.layer.cornerRadius
    }

    // MARK: - Setup UI

    private func setupUI() {
        view.backgroundColor = .rippleBackground

        // Hero gradient background
        let gradient = CAGradientLayer.rippleHero(frame: view.bounds)
        heroView.layer.insertSublayer(gradient, at: 0)
        gradientLayer = gradient

        // Hero subviews
        view.addSubview(heroView)
        heroView.addSubview(logoContainer)
        logoContainer.addSubview(logoImageView)
        heroView.addSubview(appNameLabel)
        heroView.addSubview(taglineLabel)

        // Card
        view.addSubview(cardView)
        topStack.addArrangedSubview(modeLabel)
        topStack.addArrangedSubview(segmentedControl)
        cardView.addSubview(topStack)

        fieldsStack.addArrangedSubview(nameField)
        fieldsStack.addArrangedSubview(emailField)
        fieldsStack.addArrangedSubview(passwordField)
        cardView.addSubview(fieldsStack)
        cardView.addSubview(submitButton)
        cardView.addSubview(activityIndicator)
        cardView.addSubview(errorLabel)

        // Submit gradient
        let sg = CAGradientLayer.ripplePrimary(frame: .zero)
        sg.cornerRadius = 16
        submitButton.layer.insertSublayer(sg, at: 0)
        submitGradient = sg

        nameField.isHidden = true

        NSLayoutConstraint.activate([
            // Hero
            heroView.topAnchor.constraint(equalTo: view.topAnchor),
            heroView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            heroView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            heroView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.38),

            logoContainer.centerXAnchor.constraint(equalTo: heroView.centerXAnchor),
            logoContainer.centerYAnchor.constraint(equalTo: heroView.centerYAnchor, constant: -28),
            logoContainer.widthAnchor.constraint(equalToConstant: 72),
            logoContainer.heightAnchor.constraint(equalToConstant: 72),

            logoImageView.centerXAnchor.constraint(equalTo: logoContainer.centerXAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: logoContainer.centerYAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: 36),
            logoImageView.heightAnchor.constraint(equalToConstant: 36),

            appNameLabel.topAnchor.constraint(equalTo: logoContainer.bottomAnchor, constant: 14),
            appNameLabel.centerXAnchor.constraint(equalTo: heroView.centerXAnchor),

            taglineLabel.topAnchor.constraint(equalTo: appNameLabel.bottomAnchor, constant: 6),
            taglineLabel.centerXAnchor.constraint(equalTo: heroView.centerXAnchor),

            // Card
            cardView.topAnchor.constraint(equalTo: heroView.bottomAnchor, constant: -24),
            cardView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            cardView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            topStack.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 32),
            topStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 24),
            topStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -24),

            fieldsStack.topAnchor.constraint(equalTo: topStack.bottomAnchor, constant: 24),
            fieldsStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 24),
            fieldsStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -24),

            submitButton.topAnchor.constraint(equalTo: fieldsStack.bottomAnchor, constant: 24),
            submitButton.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 24),
            submitButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -24),
            submitButton.heightAnchor.constraint(equalToConstant: 52),

            activityIndicator.centerXAnchor.constraint(equalTo: submitButton.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: submitButton.centerYAnchor),

            errorLabel.topAnchor.constraint(equalTo: submitButton.bottomAnchor, constant: 12),
            errorLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 24),
            errorLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -24)
        ])
    }

    // MARK: - Actions

    private func setupActions() {
        segmentedControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        submitButton.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)

        NotificationCenter.default
            .publisher(for: UITextField.textDidChangeNotification, object: emailField.textField)
            .compactMap { ($0.object as? UITextField)?.text }
            .assign(to: \.email, on: viewModel)
            .store(in: &cancellables)

        NotificationCenter.default
            .publisher(for: UITextField.textDidChangeNotification, object: passwordField.textField)
            .compactMap { ($0.object as? UITextField)?.text }
            .assign(to: \.password, on: viewModel)
            .store(in: &cancellables)

        NotificationCenter.default
            .publisher(for: UITextField.textDidChangeNotification, object: nameField.textField)
            .compactMap { ($0.object as? UITextField)?.text }
            .assign(to: \.displayName, on: viewModel)
            .store(in: &cancellables)
    }

    @objc private func segmentChanged() {
        viewModel.mode = segmentedControl.selectedSegmentIndex == 0 ? .login : .register
    }

    @objc private func submitTapped() {
        viewModel.submit()
    }

    // MARK: - Bind ViewModel

    private func bindViewModel() {
        viewModel.$mode
            .receive(on: RunLoop.main)
            .sink { [weak self] mode in
                guard let self else { return }
                let isRegister = mode == .register
                UIView.animate(withDuration: 0.3) {
                    self.nameField.isHidden = !isRegister
                    self.modeLabel.text = isRegister ? "Создать аккаунт" : "Добро пожаловать"
                    self.submitButton.setTitle(isRegister ? "Зарегистрироваться" : "Войти", for: .normal)
                    self.fieldsStack.layoutIfNeeded()
                }
            }
            .store(in: &cancellables)

        viewModel.$isFormValid
            .receive(on: RunLoop.main)
            .sink { [weak self] valid in
                guard let self else { return }
                UIView.animate(withDuration: 0.2) {
                    self.submitGradient?.opacity = valid ? 1.0 : 0.4
                    self.submitButton.isEnabled = valid
                }
            }
            .store(in: &cancellables)

        viewModel.$isLoading
            .receive(on: RunLoop.main)
            .sink { [weak self] loading in
                guard let self else { return }
                if loading {
                    self.submitButton.setTitle("", for: .normal)
                    self.activityIndicator.startAnimating()
                } else {
                    self.activityIndicator.stopAnimating()
                    let title = self.viewModel.mode == .register ? "Зарегистрироваться" : "Войти"
                    self.submitButton.setTitle(title, for: .normal)
                }
                self.submitButton.isEnabled = !loading && self.viewModel.isFormValid
            }
            .store(in: &cancellables)

        viewModel.$errorMessage
            .receive(on: RunLoop.main)
            .sink { [weak self] message in
                guard let self else { return }
                self.errorLabel.text = message
                UIView.animate(withDuration: 0.2) {
                    self.errorLabel.isHidden = message == nil
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Keyboard

    private func observeKeyboard() {
        NotificationCenter.default
            .publisher(for: UIResponder.keyboardWillChangeFrameNotification)
            .compactMap { $0.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect }
            .sink { [weak self] frame in
                guard let self else { return }
                let keyboardTop = frame.minY
                let screenHeight = UIScreen.main.bounds.height
                let offset = max(0, screenHeight - keyboardTop)
                UIView.animate(withDuration: 0.3) {
                    self.cardView.transform = CGAffineTransform(translationX: 0, y: -offset * 0.45)
                }
            }
            .store(in: &cancellables)

        NotificationCenter.default
            .publisher(for: UIResponder.keyboardWillHideNotification)
            .sink { [weak self] _ in
                UIView.animate(withDuration: 0.3) {
                    self?.cardView.transform = .identity
                }
            }
            .store(in: &cancellables)

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc private func dismissKeyboard() { view.endEditing(true) }
}

// MARK: - AuthTextField

final class AuthTextField: UIView {

    let textField: UITextField = {
        let tf = UITextField()
        tf.font = .systemFont(ofSize: 16)
        tf.textColor = .rippleTextPrimary
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.autocorrectionType = .no
        tf.spellCheckingType = .no
        return tf
    }()

    private let iconView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .rippleTextSecondary
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    init(placeholder: String, icon: String, isSecure: Bool) {
        super.init(frame: .zero)
        textField.placeholder = placeholder
        textField.isSecureTextEntry = isSecure
        textField.autocapitalizationType = isSecure ? .none : .none
        iconView.image = UIImage(systemName: icon)
        setupUI()
        textField.delegate = self
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        backgroundColor = .rippleSurface
        layer.cornerRadius = 14
        layer.cornerCurve = .continuous
        translatesAutoresizingMaskIntoConstraints = false

        addSubview(iconView)
        addSubview(textField)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 52),

            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 20),
            iconView.heightAnchor.constraint(equalToConstant: 20),

            textField.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            textField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            textField.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
}

extension AuthTextField: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        UIView.animate(withDuration: 0.2) {
            self.layer.borderWidth = 1.5
            self.layer.borderColor = UIColor.ripplePrimary.cgColor
            self.iconView.tintColor = .ripplePrimary
        }
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        UIView.animate(withDuration: 0.2) {
            self.layer.borderWidth = 0
            self.iconView.tintColor = .rippleTextSecondary
        }
    }
}

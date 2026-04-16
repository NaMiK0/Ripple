import UIKit
import Combine

final class AuthViewController: UIViewController {

    // MARK: - Properties

    private let viewModel: AuthViewModel
    private var cancellables = Set<AnyCancellable>()

    // MARK: - UI

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.keyboardDismissMode = .onDrag
        return sv
    }()

    private let contentStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 16
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Ripple"
        label.font = .systemFont(ofSize: 34, weight: .bold)
        label.textAlignment = .center
        return label
    }()

    private let segmentedControl: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["Войти", "Регистрация"])
        sc.selectedSegmentIndex = 0
        return sc
    }()

    private let nameField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Имя"
        tf.borderStyle = .roundedRect
        tf.autocorrectionType = .no
        tf.isHidden = true
        return tf
    }()

    private let emailField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Email"
        tf.borderStyle = .roundedRect
        tf.keyboardType = .emailAddress
        tf.autocapitalizationType = .none
        tf.autocorrectionType = .no
        return tf
    }()

    private let passwordField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Пароль (минимум 6 символов)"
        tf.borderStyle = .roundedRect
        tf.isSecureTextEntry = true
        return tf
    }()

    private let submitButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Войти"
        config.cornerStyle = .medium
        let btn = UIButton(configuration: config)
        btn.isEnabled = false
        return btn
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let ai = UIActivityIndicatorView(style: .medium)
        ai.hidesWhenStopped = true
        return ai
    }()

    private let errorLabel: UILabel = {
        let label = UILabel()
        label.textColor = .systemRed
        label.font = .systemFont(ofSize: 14)
        label.numberOfLines = 0
        label.textAlignment = .center
        label.isHidden = true
        return label
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
        observeKeyboardForScrollView()
    }

    // MARK: - Setup UI

    private func setupUI() {
        view.backgroundColor = .systemBackground

        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        [titleLabel, segmentedControl, nameField, emailField,
         passwordField, submitButton, activityIndicator, errorLabel]
            .forEach { contentStack.addArrangedSubview($0) }

        contentStack.setCustomSpacing(32, after: titleLabel)
        contentStack.setCustomSpacing(24, after: segmentedControl)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 40),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 24),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -24),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -24),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -48)
        ])
    }

    // MARK: - Actions

    private func setupActions() {
        segmentedControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        submitButton.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)

        // Биндим текстовые поля на ViewModel через Combine
        NotificationCenter.default
            .publisher(for: UITextField.textDidChangeNotification, object: emailField)
            .compactMap { ($0.object as? UITextField)?.text }
            .assign(to: \.email, on: viewModel)
            .store(in: &cancellables)

        NotificationCenter.default
            .publisher(for: UITextField.textDidChangeNotification, object: passwordField)
            .compactMap { ($0.object as? UITextField)?.text }
            .assign(to: \.password, on: viewModel)
            .store(in: &cancellables)

        NotificationCenter.default
            .publisher(for: UITextField.textDidChangeNotification, object: nameField)
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
        // Переключение режима Login / Register
        viewModel.$mode
            .receive(on: RunLoop.main)
            .sink { [weak self] mode in
                guard let self else { return }
                let isRegister = mode == .register
                self.nameField.isHidden = !isRegister
                var config = self.submitButton.configuration
                config?.title = isRegister ? "Зарегистрироваться" : "Войти"
                self.submitButton.configuration = config
            }
            .store(in: &cancellables)

        // Активность кнопки
        viewModel.$isFormValid
            .receive(on: RunLoop.main)
            .assign(to: \.isEnabled, on: submitButton)
            .store(in: &cancellables)

        // Индикатор загрузки
        viewModel.$isLoading
            .receive(on: RunLoop.main)
            .sink { [weak self] loading in
                guard let self else { return }
                loading ? self.activityIndicator.startAnimating()
                        : self.activityIndicator.stopAnimating()
                self.submitButton.isEnabled = !loading && self.viewModel.isFormValid
            }
            .store(in: &cancellables)

        // Ошибки
        viewModel.$errorMessage
            .receive(on: RunLoop.main)
            .sink { [weak self] message in
                guard let self else { return }
                self.errorLabel.text = message
                self.errorLabel.isHidden = message == nil
            }
            .store(in: &cancellables)
    }

    // MARK: - Keyboard

    private func observeKeyboardForScrollView() {
        NotificationCenter.default
            .publisher(for: UIResponder.keyboardWillShowNotification)
            .compactMap { $0.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect }
            .sink { [weak self] frame in
                self?.scrollView.contentInset.bottom = frame.height
            }
            .store(in: &cancellables)

        NotificationCenter.default
            .publisher(for: UIResponder.keyboardWillHideNotification)
            .sink { [weak self] _ in
                self?.scrollView.contentInset.bottom = 0
            }
            .store(in: &cancellables)
    }
}

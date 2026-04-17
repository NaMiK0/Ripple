import UIKit
import Combine

final class ChatViewController: UIViewController {

    // MARK: - Properties

    private let viewModel: ChatViewModel
    private var cancellables = Set<AnyCancellable>()

    // MARK: - UI

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.register(OutgoingMessageCell.self, forCellReuseIdentifier: OutgoingMessageCell.reuseId)
        tv.register(IncomingMessageCell.self, forCellReuseIdentifier: IncomingMessageCell.reuseId)
        tv.separatorStyle = .none
        tv.backgroundColor = .rippleBackground
        tv.rowHeight = UITableView.automaticDimension
        tv.estimatedRowHeight = 60
        tv.keyboardDismissMode = .interactive
        // Инвертируем таблицу — новые сообщения снизу
        tv.transform = CGAffineTransform(scaleX: 1, y: -1)
        return tv
    }()

    private lazy var typingLabel: UILabel = {
        let l = UILabel()
        l.font = .italicSystemFont(ofSize: 13)
        l.textColor = .rippleTextSecondary
        l.translatesAutoresizingMaskIntoConstraints = false
        l.alpha = 0
        return l
    }()

    // MARK: - Input Bar

    /// Фон input bar — белая плашка с тенью сверху
    private let inputContainer: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.systemBackground
        v.translatesAutoresizingMaskIntoConstraints = false
        let line = UIView()
        line.backgroundColor = UIColor.rippleTextSecondary.withAlphaComponent(0.15)
        line.translatesAutoresizingMaskIntoConstraints = false
        v.addSubview(line)
        NSLayoutConstraint.activate([
            line.topAnchor.constraint(equalTo: v.topAnchor),
            line.leadingAnchor.constraint(equalTo: v.leadingAnchor),
            line.trailingAnchor.constraint(equalTo: v.trailingAnchor),
            line.heightAnchor.constraint(equalToConstant: 0.5)
        ])
        return v
    }()

    private let inputField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Сообщение..."
        tf.font = .systemFont(ofSize: 16)
        tf.backgroundColor = .rippleSurface
        tf.layer.cornerRadius = 20
        tf.layer.cornerCurve = .continuous
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        tf.leftViewMode = .always
        tf.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        tf.rightViewMode = .always
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    /// Кнопка отправки — градиентный круг
    private let sendButton: UIButton = {
        let btn = UIButton(type: .custom)
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .bold)
        let img = UIImage(systemName: "arrow.up", withConfiguration: config)?
            .withTintColor(.white, renderingMode: .alwaysOriginal)
        btn.setImage(img, for: .normal)
        btn.setImage(img, for: .disabled)
        btn.layer.cornerRadius = 18
        btn.layer.cornerCurve = .continuous
        btn.clipsToBounds = true
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.isEnabled = false
        btn.alpha = 0.45
        return btn
    }()

    private var sendButtonGradient: CAGradientLayer?
    private var inputContainerBottomConstraint: NSLayoutConstraint!

    // MARK: - Init

    init(viewModel: ChatViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
        bindViewModel()
        viewModel.onViewDidLoad()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if sendButtonGradient == nil {
            let g = CAGradientLayer.ripplePrimary(frame: sendButton.bounds)
            sendButton.layer.insertSublayer(g, at: 0)
            sendButtonGradient = g
        } else {
            sendButtonGradient?.frame = sendButton.bounds
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        viewModel.onViewDidDisappear()
    }

    // MARK: - Setup UI

    private func setupUI() {
        view.backgroundColor = .rippleBackground
        navigationItem.largeTitleDisplayMode = .never

        view.addSubview(tableView)
        view.addSubview(typingLabel)
        view.addSubview(inputContainer)
        inputContainer.addSubview(inputField)
        inputContainer.addSubview(sendButton)

        inputContainerBottomConstraint = inputContainer.bottomAnchor
            .constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)

        NSLayoutConstraint.activate([
            inputContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            inputContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            inputContainerBottomConstraint,

            inputField.topAnchor.constraint(equalTo: inputContainer.topAnchor, constant: 10),
            inputField.leadingAnchor.constraint(equalTo: inputContainer.leadingAnchor, constant: 12),
            inputField.bottomAnchor.constraint(equalTo: inputContainer.bottomAnchor, constant: -10),
            inputField.heightAnchor.constraint(equalToConstant: 40),

            sendButton.leadingAnchor.constraint(equalTo: inputField.trailingAnchor, constant: 8),
            sendButton.trailingAnchor.constraint(equalTo: inputContainer.trailingAnchor, constant: -12),
            sendButton.centerYAnchor.constraint(equalTo: inputField.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 36),
            sendButton.heightAnchor.constraint(equalToConstant: 36),

            typingLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            typingLabel.bottomAnchor.constraint(equalTo: inputContainer.topAnchor, constant: -4),

            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: typingLabel.topAnchor, constant: -4)
        ])

        tableView.delegate = self
        tableView.dataSource = self
    }

    // MARK: - Actions

    private func setupActions() {
        sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        inputField.addTarget(self, action: #selector(textChanged), for: .editingChanged)
        inputField.addTarget(self, action: #selector(textChanged), for: .editingDidEnd)

        NotificationCenter.default
            .publisher(for: UIResponder.keyboardWillChangeFrameNotification)
            .compactMap { $0.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect }
            .sink { [weak self] frame in
                guard let self else { return }
                let keyboardHeight = UIScreen.main.bounds.height - frame.minY
                let safeBottom = self.view.safeAreaInsets.bottom
                let offset = max(0, keyboardHeight - safeBottom)
                self.inputContainerBottomConstraint.constant = -offset
                UIView.animate(withDuration: 0.25) { self.view.layoutIfNeeded() }
            }
            .store(in: &cancellables)
    }

    @objc private func sendTapped() {
        guard let text = inputField.text, !text.isEmpty else { return }
        viewModel.send(text: text)
        inputField.text = ""
        setSendEnabled(false)
        viewModel.stopTyping()
    }

    @objc private func textChanged() {
        let hasText = !(inputField.text?.isEmpty ?? true)
        setSendEnabled(hasText)
        if hasText { viewModel.userIsTyping() }
    }

    private func setSendEnabled(_ enabled: Bool) {
        sendButton.isEnabled = enabled
        UIView.animate(withDuration: 0.15) {
            self.sendButton.alpha = enabled ? 1.0 : 0.45
        }
    }

    // MARK: - Bind ViewModel

    private func bindViewModel() {
        viewModel.$messages
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.tableView.reloadData()
            }
            .store(in: &cancellables)

        viewModel.$typingText
            .receive(on: RunLoop.main)
            .sink { [weak self] text in
                guard let self else { return }
                self.typingLabel.text = text
                UIView.animate(withDuration: 0.2) {
                    self.typingLabel.alpha = text.isEmpty ? 0 : 1
                }
            }
            .store(in: &cancellables)

        viewModel.$errorMessage
            .compactMap { $0 }
            .receive(on: RunLoop.main)
            .sink { [weak self] message in
                let alert = UIAlertController(title: "Ошибка", message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self?.present(alert, animated: true)
            }
            .store(in: &cancellables)
    }
}

// MARK: - UITableViewDataSource

extension ChatViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = viewModel.messages[indexPath.row]
        let isOutgoing = message.senderId == viewModel.currentUserId

        if isOutgoing {
            let cell = tableView.dequeueReusableCell(
                withIdentifier: OutgoingMessageCell.reuseId, for: indexPath
            ) as! OutgoingMessageCell
            cell.configure(message: message, isRead: message.status == .read)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(
                withIdentifier: IncomingMessageCell.reuseId, for: indexPath
            ) as! IncomingMessageCell
            cell.configure(message: message)
            return cell
        }
    }
}

// MARK: - UITableViewDelegate

extension ChatViewController: UITableViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let threshold = scrollView.contentSize.height - scrollView.frame.height - 100
        if offsetY > threshold {
            viewModel.loadMoreIfNeeded()
        }
    }
}

import UIKit
import Combine
import SkeletonView

final class ConversationsViewController: UIViewController {

    // MARK: - Properties

    private let viewModel: ConversationsViewModel
    private var cancellables = Set<AnyCancellable>()
    private var dataSource: UITableViewDiffableDataSource<Int, Conversation>!

    // MARK: - UI

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.register(ConversationCell.self, forCellReuseIdentifier: ConversationCell.reuseId)
        tv.rowHeight = UITableView.automaticDimension
        tv.estimatedRowHeight = 72
        tv.separatorInset = UIEdgeInsets(top: 0, left: 76, bottom: 0, right: 0)
        tv.isSkeletonable = true
        return tv
    }()

    private let emptyStateView: UIView = {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.isHidden = true

        let imageView = UIImageView(image: UIImage(systemName: "bubble.left.and.bubble.right"))
        imageView.tintColor = .systemGray3
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = "Нет чатов\nНажмите + чтобы начать"
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 15)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView(arrangedSubviews: [imageView, label])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(stack)
        NSLayoutConstraint.activate([
            imageView.heightAnchor.constraint(equalToConstant: 60),
            stack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        return container
    }()

    // MARK: - Init

    init(viewModel: ConversationsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavBar()
        setupDataSource()
        bindViewModel()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel.onViewDidAppear()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        viewModel.onViewDidDisappear()
    }

    // MARK: - Setup UI

    private func setupUI() {
        view.backgroundColor = .systemBackground
        view.addSubview(tableView)
        view.addSubview(emptyStateView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyStateView.topAnchor.constraint(equalTo: view.topAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyStateView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupNavBar() {
        title = "Chats"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .compose,
            target: self,
            action: #selector(newConversationTapped)
        )
    }

    // MARK: - DataSource (Diffable)

    private func setupDataSource() {
        dataSource = UITableViewDiffableDataSource(
            tableView: tableView
        ) { [weak self] tableView, indexPath, conversation -> UITableViewCell in
            guard let self,
                  let cell = tableView.dequeueReusableCell(
                      withIdentifier: ConversationCell.reuseId,
                      for: indexPath
                  ) as? ConversationCell
            else { return UITableViewCell() }

            cell.configure(
                name: self.viewModel.companionName(for: conversation),
                lastMessage: conversation.lastMessage,
                timestamp: conversation.lastMessageTimestamp.dateValue(),
                avatarURL: nil,
                unreadCount: self.viewModel.unreadCount(for: conversation),
                isOnline: false
            )
            return cell
        }

        // Свайп для удаления
        tableView.delegate = self
    }

    // MARK: - Bind ViewModel

    private func bindViewModel() {
        // Skeleton пока грузим
        viewModel.$isLoading
            .receive(on: RunLoop.main)
            .sink { [weak self] loading in
                guard let self else { return }
                if loading {
                    self.tableView.showAnimatedGradientSkeleton()
                } else {
                    self.tableView.hideSkeleton(reloadDataAfter: false)
                }
            }
            .store(in: &cancellables)

        // Обновляем список
        viewModel.$conversations
            .receive(on: RunLoop.main)
            .sink { [weak self] conversations in
                guard let self else { return }
                self.emptyStateView.isHidden = !conversations.isEmpty
                var snapshot = NSDiffableDataSourceSnapshot<Int, Conversation>()
                snapshot.appendSections([0])
                snapshot.appendItems(conversations)
                self.dataSource.apply(snapshot, animatingDifferences: true)
            }
            .store(in: &cancellables)

        // Ошибки
        viewModel.$errorMessage
            .compactMap { $0 }
            .receive(on: RunLoop.main)
            .sink { [weak self] message in
                self?.showErrorAlert(message: message)
            }
            .store(in: &cancellables)
    }

    // MARK: - Actions

    @objc private func newConversationTapped() {
        viewModel.newConversationTapped()
    }

    // MARK: - Helpers

    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "Ошибка", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDelegate

extension ConversationsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let conversation = dataSource.itemIdentifier(for: indexPath) else { return }
        viewModel.select(conversation: conversation)
    }

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let delete = UIContextualAction(style: .destructive, title: "Удалить") {
            [weak self] _, _, completion in
            self?.viewModel.delete(at: indexPath)
            completion(true)
        }
        delete.image = UIImage(systemName: "trash")
        return UISwipeActionsConfiguration(actions: [delete])
    }
}

import UIKit
import Combine
import FirebaseFirestore
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
        tv.separatorInset = UIEdgeInsets(top: 0, left: 80, bottom: 0, right: 0)
        tv.separatorColor = UIColor.rippleTextSecondary.withAlphaComponent(0.15)
        tv.backgroundColor = .rippleBackground
        tv.isSkeletonable = true
        return tv
    }()

    private let emptyStateView: UIView = {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.isHidden = true

        let iconWrapper = UIView()
        iconWrapper.translatesAutoresizingMaskIntoConstraints = false
        iconWrapper.layer.cornerRadius = 44
        iconWrapper.clipsToBounds = true

        let iconBg = CAGradientLayer.rippleHero(frame: CGRect(x: 0, y: 0, width: 88, height: 88))
        iconWrapper.layer.addSublayer(iconBg)

        let imageView = UIImageView(image: UIImage(systemName: "bubble.left.and.bubble.right.fill"))
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false

        iconWrapper.addSubview(imageView)
        NSLayoutConstraint.activate([
            iconWrapper.widthAnchor.constraint(equalToConstant: 88),
            iconWrapper.heightAnchor.constraint(equalToConstant: 88),
            imageView.centerXAnchor.constraint(equalTo: iconWrapper.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: iconWrapper.centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 40),
            imageView.heightAnchor.constraint(equalToConstant: 40)
        ])

        let titleLabel = UILabel()
        titleLabel.text = "Нет чатов"
        titleLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        titleLabel.textColor = .rippleTextPrimary
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let subtitleLabel = UILabel()
        subtitleLabel.text = "Нажмите + чтобы начать переписку"
        subtitleLabel.font = .systemFont(ofSize: 15)
        subtitleLabel.textColor = .rippleTextSecondary
        subtitleLabel.textAlignment = .center
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView(arrangedSubviews: [iconWrapper, titleLabel, subtitleLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 12
        stack.setCustomSpacing(20, after: iconWrapper)
        stack.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: container.centerYAnchor, constant: -40)
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
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
        view.backgroundColor = .rippleBackground
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
        title = "Ripple"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "square.and.pencil"),
            style: .plain,
            target: self,
            action: #selector(newConversationTapped)
        )
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "person.circle.fill"),
            style: .plain,
            target: self,
            action: #selector(profileTapped)
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

        tableView.delegate = self
    }

    // MARK: - Bind ViewModel

    private func bindViewModel() {
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

    @objc private func profileTapped() {
        viewModel.onProfileTapped?()
    }

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
        delete.backgroundColor = UIColor(hex: "#ED4245")
        return UISwipeActionsConfiguration(actions: [delete])
    }
}

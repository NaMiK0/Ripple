import UIKit
import Kingfisher

/// Экран выбора пользователя для создания нового чата
final class NewConversationViewController: UIViewController {

    // MARK: - Properties

    private let conversationService: ConversationServiceProtocol
    private let currentUserId: String
    private let currentUserName: String
    private let onConversationCreated: (String) -> Void

    private var users: [User] = []
    private var filteredUsers: [User] = []
    private var dataSource: UITableViewDiffableDataSource<Int, User>!

    // MARK: - UI

    private lazy var searchController: UISearchController = {
        let sc = UISearchController(searchResultsController: nil)
        sc.searchResultsUpdater = self
        sc.obscuresBackgroundDuringPresentation = false
        sc.searchBar.placeholder = "Поиск пользователей"
        sc.searchBar.tintColor = .ripplePrimary
        return sc
    }()

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.register(NewConversationCell.self, forCellReuseIdentifier: NewConversationCell.reuseId)
        tv.rowHeight = UITableView.automaticDimension
        tv.estimatedRowHeight = 64
        tv.backgroundColor = .rippleBackground
        tv.separatorInset = UIEdgeInsets(top: 0, left: 80, bottom: 0, right: 0)
        tv.separatorColor = UIColor.rippleTextSecondary.withAlphaComponent(0.15)
        return tv
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let ai = UIActivityIndicatorView(style: .medium)
        ai.color = .ripplePrimary
        ai.translatesAutoresizingMaskIntoConstraints = false
        ai.hidesWhenStopped = true
        return ai
    }()

    private let emptyLabel: UILabel = {
        let l = UILabel()
        l.text = "Пользователи не найдены"
        l.font = .systemFont(ofSize: 16)
        l.textColor = .rippleTextSecondary
        l.textAlignment = .center
        l.isHidden = true
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // MARK: - Init

    init(
        conversationService: ConversationServiceProtocol,
        currentUserId: String,
        currentUserName: String,
        onConversationCreated: @escaping (String) -> Void
    ) {
        self.conversationService = conversationService
        self.currentUserId = currentUserId
        self.currentUserName = currentUserName
        self.onConversationCreated = onConversationCreated
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupDataSource()
        loadUsers()
    }

    // MARK: - Setup

    private func setupUI() {
        title = "Новый чат"
        view.backgroundColor = .rippleBackground

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false

        view.addSubview(tableView)
        view.addSubview(activityIndicator)
        view.addSubview(emptyLabel)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        tableView.delegate = self
    }

    private func setupDataSource() {
        dataSource = UITableViewDiffableDataSource(
            tableView: tableView
        ) { tableView, indexPath, user -> UITableViewCell in
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: NewConversationCell.reuseId, for: indexPath
            ) as? NewConversationCell else { return UITableViewCell() }
            cell.configure(user: user)
            return cell
        }
    }

    private func loadUsers() {
        activityIndicator.startAnimating()
        emptyLabel.isHidden = true
        Task { @MainActor in
            defer { activityIndicator.stopAnimating() }
            do {
                users = try await conversationService.fetchUsers(excluding: currentUserId)
                filteredUsers = users
                applySnapshot(users)
                emptyLabel.isHidden = !users.isEmpty
            } catch {
                showAlert(title: "Ошибка", message: error.localizedDescription)
            }
        }
    }

    private func applySnapshot(_ users: [User]) {
        emptyLabel.isHidden = !users.isEmpty
        var snapshot = NSDiffableDataSourceSnapshot<Int, User>()
        snapshot.appendSections([0])
        snapshot.appendItems(users)
        dataSource.apply(snapshot, animatingDifferences: true)
    }

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
}

// MARK: - UITableViewDelegate

extension NewConversationViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let user = dataSource.itemIdentifier(for: indexPath) else { return }

        showSpinner()
        Task { @MainActor in
            defer { hideSpinner() }
            do {
                let conversationId = try await conversationService.createConversation(
                    currentUserId: currentUserId,
                    currentUserName: currentUserName,
                    otherUserId: user.id,
                    otherUserName: user.displayName
                )
                onConversationCreated(conversationId)
            } catch {
                showAlert(title: "Ошибка", message: error.localizedDescription)
            }
        }
    }
}

// MARK: - UISearchResultsUpdating

extension NewConversationViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        let query = searchController.searchBar.text?.lowercased() ?? ""
        filteredUsers = query.isEmpty
            ? users
            : users.filter { $0.displayName.lowercased().contains(query) }
        applySnapshot(filteredUsers)
    }
}

// MARK: - NewConversationCell

private final class NewConversationCell: UITableViewCell {
    static let reuseId = "NewConversationCell"

    private let avatarView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 24
        iv.layer.cornerCurve = .continuous
        iv.backgroundColor = .rippleSurface
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 16, weight: .semibold)
        l.textColor = .rippleTextPrimary
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13)
        l.textColor = .rippleTextSecondary
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .rippleBackground

        let selectedBg = UIView()
        selectedBg.backgroundColor = UIColor.ripplePrimary.withAlphaComponent(0.06)
        selectedBackgroundView = selectedBg

        let textStack = UIStackView(arrangedSubviews: [nameLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 3
        textStack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(avatarView)
        contentView.addSubview(textStack)

        NSLayoutConstraint.activate([
            avatarView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            avatarView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: 48),
            avatarView.heightAnchor.constraint(equalToConstant: 48),
            avatarView.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: 10),
            avatarView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -10),

            textStack.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 12),
            textStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            textStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(user: User) {
        nameLabel.text = user.displayName
        subtitleLabel.text = user.isOnline ? "В сети" : "Не в сети"
        subtitleLabel.textColor = user.isOnline
            ? UIColor(hex: "#43B581")
            : .rippleTextSecondary

        if let urlStr = user.avatarURL, let url = URL(string: urlStr) {
            avatarView.kf.setImage(with: url, options: [.transition(.fade(0.2))])
        } else {
            avatarView.setInitialsAvatar(name: user.displayName, size: 48)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        avatarView.kf.cancelDownloadTask()
        avatarView.image = nil
    }
}

// MARK: - Hashable conformance for User (needed for DiffableDataSource)

extension User: Hashable {
    static func == (lhs: User, rhs: User) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

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
        return sc
    }()

    private lazy var tableView: UITableView = {
        let tv = UITableView()
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "UserCell")
        tv.rowHeight = UITableView.automaticDimension
        tv.estimatedRowHeight = 56
        return tv
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let ai = UIActivityIndicatorView(style: .medium)
        ai.translatesAutoresizingMaskIntoConstraints = false
        ai.hidesWhenStopped = true
        return ai
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
        view.backgroundColor = .systemBackground

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )
        navigationItem.searchController = searchController

        view.addSubview(tableView)
        view.addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func setupDataSource() {
        dataSource = UITableViewDiffableDataSource(
            tableView: tableView
        ) { tableView, indexPath, user -> UITableViewCell in
            var cell = tableView.dequeueReusableCell(withIdentifier: "UserCell", for: indexPath)
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: "UserCell")
            cell.textLabel?.text = user.displayName
            if let urlStr = user.avatarURL, let url = URL(string: urlStr) {
                cell.imageView?.kf.setImage(with: url, placeholder: UIImage(systemName: "person.circle.fill"))
            } else {
                cell.imageView?.image = UIImage(systemName: "person.circle.fill")
            }
            return cell
        }

        tableView.delegate = self
    }

    private func loadUsers() {
        activityIndicator.startAnimating()
        Task { @MainActor in
            defer { activityIndicator.stopAnimating() }
            do {
                users = try await conversationService.fetchUsers(excluding: currentUserId)
                filteredUsers = users
                applySnapshot(users)
            } catch {
                let alert = UIAlertController(title: "Ошибка", message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                present(alert, animated: true)
            }
        }
    }

    private func applySnapshot(_ users: [User]) {
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

        Task { @MainActor in
            do {
                let conversationId = try await conversationService.createConversation(
                    currentUserId: currentUserId,
                    currentUserName: currentUserName,
                    otherUserId: user.id,
                    otherUserName: user.displayName
                )
                onConversationCreated(conversationId)
            } catch {
                let alert = UIAlertController(title: "Ошибка", message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                present(alert, animated: true)
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

// MARK: - Hashable conformance for User (needed for DiffableDataSource)

extension User: Hashable {
    static func == (lhs: User, rhs: User) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

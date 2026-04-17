import UIKit
import FirebaseAuth

final class ConversationsCoordinator {

    // MARK: - Properties

    private let navigationController: UINavigationController
    private var chatCoordinator: ChatCoordinator?

    // MARK: - Init

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    // MARK: - Start

    func start() {
        let conversationService = ConversationService()
        let authService = AuthService()

        let viewModel = ConversationsViewModel(
            conversationService: conversationService,
            authService: authService
        )

        viewModel.onOpenConversation = { [weak self] conversationId in
            self?.openChat(conversationId: conversationId)
        }

        viewModel.onNewConversation = { [weak self] in
            self?.showNewConversation(
                conversationService: conversationService,
                authService: authService
            )
        }

        let viewController = ConversationsViewController(viewModel: viewModel)
        navigationController.setViewControllers([viewController], animated: false)
    }

    // MARK: - Navigation

    func openChat(conversationId: String) {
        // ChatCoordinator подключим в следующей части
        // Пока — заглушка
        let vc = UIViewController()
        vc.view.backgroundColor = .systemBackground
        vc.title = "Chat"
        navigationController.pushViewController(vc, animated: true)
    }

    private func showNewConversation(
        conversationService: ConversationServiceProtocol,
        authService: AuthServiceProtocol
    ) {
        guard let currentUserId = authService.currentUser?.uid,
              let currentUserName = authService.currentUser?.displayName ?? authService.currentUser?.email
        else { return }

        let vc = NewConversationViewController(
            conversationService: conversationService,
            currentUserId: currentUserId,
            currentUserName: currentUserName
        ) { [weak self] conversationId in
            self?.navigationController.dismiss(animated: true)
            self?.openChat(conversationId: conversationId)
        }

        let nav = UINavigationController(rootViewController: vc)
        navigationController.present(nav, animated: true)
    }
}

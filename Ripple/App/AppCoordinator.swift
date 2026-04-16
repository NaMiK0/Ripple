import UIKit
import FirebaseAuth

final class AppCoordinator {

    // MARK: - Properties

    private let window: UIWindow
    private let navigationController: UINavigationController
    private var authCoordinator: AuthCoordinator?

    // Используется для deep link из push-уведомления (приложение было убито)
    static var pendingDeepLink: String?

    // MARK: - Init

    init(window: UIWindow) {
        self.window = window
        self.navigationController = UINavigationController()
        self.navigationController.navigationBar.prefersLargeTitles = true
    }

    // MARK: - Start

    func start() {
        window.rootViewController = navigationController
        window.makeKeyAndVisible()

        if Auth.auth().currentUser != nil {
            showMainFlow()
        } else {
            showAuthFlow()
        }
    }

    // MARK: - Auth Flow

    private func showAuthFlow() {
        let coordinator = AuthCoordinator(navigationController: navigationController)
        coordinator.onAuthenticated = { [weak self] in
            self?.authCoordinator = nil
            self?.showMainFlow()
        }
        authCoordinator = coordinator
        coordinator.start()
    }

    // MARK: - Main Flow

    // ConversationsCoordinator будет добавлен в следующих частях.
    // Пока — заглушка, чтобы проект компилировался.
    private func showMainFlow() {
        let placeholder = UIViewController()
        placeholder.view.backgroundColor = .systemBackground
        placeholder.title = "Chats"
        navigationController.setViewControllers([placeholder], animated: false)

        // Обрабатываем deep link, если приложение открылось через уведомление
        if let conversationId = AppCoordinator.pendingDeepLink {
            AppCoordinator.pendingDeepLink = nil
            // openChat(conversationId: conversationId) — подключим позже
            _ = conversationId
        }
    }
}

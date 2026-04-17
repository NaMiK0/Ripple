import UIKit
import FirebaseAuth

@MainActor
final class AppCoordinator {

    // MARK: - Properties

    private let window: UIWindow
    private let navigationController: UINavigationController
    private var authCoordinator: AuthCoordinator?
    private var conversationsCoordinator: ConversationsCoordinator?

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

        // Слушаем deep link из push-уведомления когда приложение работает в фоне
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleOpenConversation(_:)),
            name: .openConversation,
            object: nil
        )

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

    private func showMainFlow() {
        // Запрашиваем разрешение на push-уведомления
        PushNotificationService.shared.requestAuthorization()

        // Подписываемся на восстановление сети → flush офлайн-очереди
        OfflineMessageQueue.shared.onConnectionRestored = { [weak self] in
            self?.flushOfflineQueue()
        }

        let coordinator = ConversationsCoordinator(navigationController: navigationController)
        coordinator.onLogout = { [weak self] in
            self?.conversationsCoordinator = nil
            self?.showAuthFlow()
        }
        conversationsCoordinator = coordinator
        coordinator.start()

        // Обрабатываем deep link, если приложение открылось через уведомление (terminated state)
        if let conversationId = AppCoordinator.pendingDeepLink {
            AppCoordinator.pendingDeepLink = nil
            coordinator.openChat(conversationId: conversationId)
        }
    }

    // MARK: - Offline Queue Flush

    private func flushOfflineQueue() {
        let pending = OfflineMessageQueue.shared.pendingMessages
        guard !pending.isEmpty else { return }

        let messageService = MessageService()
        for queued in pending {
            Task {
                do {
                    try await messageService.send(
                        text: queued.text,
                        in: queued.conversationId,
                        senderId: queued.senderId,
                        senderName: queued.senderName
                    )
                    OfflineMessageQueue.shared.dequeue(id: queued.id)
                } catch {
                    print("Failed to flush queued message \(queued.id): \(error)")
                }
            }
        }
    }

    // MARK: - Deep Link

    @objc private func handleOpenConversation(_ notification: Notification) {
        guard let conversationId = notification.object as? String else { return }
        conversationsCoordinator?.openChat(conversationId: conversationId)
    }
}

import UIKit

@MainActor
final class ChatCoordinator {

    private let navigationController: UINavigationController
    private let conversationId: String

    init(navigationController: UINavigationController, conversationId: String) {
        self.navigationController = navigationController
        self.conversationId = conversationId
    }

    func start() {
        let messageService = MessageService()
        let conversationService = ConversationService()

        let viewModel = ChatViewModel(
            conversationId: conversationId,
            messageService: messageService,
            conversationService: conversationService
        )

        let viewController = ChatViewController(viewModel: viewModel)
        viewController.title = "Чат"
        navigationController.pushViewController(viewController, animated: true)
    }
}

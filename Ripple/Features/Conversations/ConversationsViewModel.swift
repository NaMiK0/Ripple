import Combine
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class ConversationsViewModel: ObservableObject {

    // MARK: - Output

    @Published private(set) var conversations: [Conversation] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?

    // MARK: - Callbacks

    var onOpenConversation: ((String) -> Void)?
    var onNewConversation: (() -> Void)?
    var onProfileTapped: (() -> Void)?

    // MARK: - Private

    private let conversationService: ConversationServiceProtocol
    private let authService: AuthServiceProtocol
    private var listener: ListenerRegistration?

    var currentUserId: String {
        authService.currentUser?.uid ?? ""
    }

    // MARK: - Init

    init(
        conversationService: ConversationServiceProtocol,
        authService: AuthServiceProtocol
    ) {
        self.conversationService = conversationService
        self.authService = authService
    }

    // MARK: - Lifecycle

    func onViewDidAppear() {
        guard !currentUserId.isEmpty else { return }
        startListening()
    }

    func onViewDidDisappear() {
        stopListening()
    }

    // MARK: - Listener

    private func startListening() {
        isLoading = true
        listener = conversationService.listenToConversations(userId: currentUserId) {
            [weak self] conversations in
            guard let self else { return }
            self.isLoading = false
            self.conversations = conversations
        }
    }

    private func stopListening() {
        listener?.remove()
        listener = nil
    }

    // MARK: - Actions

    func select(conversation: Conversation) {
        guard let id = conversation.id else { return }
        onOpenConversation?(id)
    }

    func delete(at indexPath: IndexPath) {
        // Удаляем только локально — Firestore-документ не трогаем,
        // чтобы второй участник не потерял историю
        conversations.remove(at: indexPath.row)
    }

    func newConversationTapped() {
        onNewConversation?()
    }

    // MARK: - Helpers

    /// Имя собеседника для отображения в ячейке
    func companionName(for conversation: Conversation) -> String {
        conversation.participantNames
            .first { $0.key != currentUserId }?.value ?? "Неизвестный"
    }

    /// Количество непрочитанных для текущего пользователя
    func unreadCount(for conversation: Conversation) -> Int {
        conversation.unreadCount[currentUserId] ?? 0
    }
}

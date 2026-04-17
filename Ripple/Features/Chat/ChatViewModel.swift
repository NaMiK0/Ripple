import Combine
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class ChatViewModel: ObservableObject {

    // MARK: - Output

    @Published private(set) var messages: [Message] = []
    @Published private(set) var isLoadingMore = false
    @Published private(set) var canLoadMore = true
    @Published private(set) var typingText: String = ""
    @Published private(set) var errorMessage: String?

    // MARK: - Public

    let conversationId: String

    var currentUserId: String {
        Auth.auth().currentUser?.uid ?? ""
    }

    var currentUserName: String {
        Auth.auth().currentUser?.displayName
            ?? Auth.auth().currentUser?.email
            ?? "Unknown"
    }

    // MARK: - Private

    private let messageService: MessageServiceProtocol
    private let conversationService: ConversationServiceProtocol
    private let cache: MessageCache

    private var messageListener: ListenerRegistration?
    private var typingListener: ListenerRegistration?
    private var typingDebounce: Task<Void, Never>?

    private static let pageSize = 20

    // MARK: - Init

    init(
        conversationId: String,
        messageService: MessageServiceProtocol,
        conversationService: ConversationServiceProtocol,
        cache: MessageCache = MessageCache()
    ) {
        self.conversationId = conversationId
        self.messageService = messageService
        self.conversationService = conversationService
        self.cache = cache
    }

    // MARK: - Lifecycle

    func onViewDidLoad() {
        startMessageListener()
        startTypingListener()
        markAsRead()
    }

    func onViewDidDisappear() {
        messageListener?.remove()
        typingListener?.remove()
        stopTyping()
    }

    // MARK: - Listeners

    private func startMessageListener() {
        messageListener = messageService.listenToMessages(
            conversationId: conversationId
        ) { [weak self] newMessages in
            guard let self else { return }
            Task {
                for msg in newMessages {
                    await self.cache.append(msg, to: self.conversationId)
                }
                self.messages = await self.cache.messages(for: self.conversationId)
                    .sorted { $0.timestamp.dateValue() > $1.timestamp.dateValue() }
            }
        }
    }

    private func startTypingListener() {
        typingListener = conversationService.listenToTypingStatus(
            conversationId: conversationId
        ) { [weak self] typingUsers in
            guard let self else { return }
            let others = typingUsers.filter { $0 != self.currentUserId }
            self.typingText = others.isEmpty ? "" : "печатает..."
        }
    }

    // MARK: - Send

    func send(text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Нет сети — кладём в офлайн-очередь
        guard OfflineMessageQueue.shared.isConnected else {
            let queued = QueuedMessage(
                conversationId: conversationId,
                text: trimmed,
                senderId: currentUserId,
                senderName: currentUserName
            )
            OfflineMessageQueue.shared.enqueue(queued)
            // Показываем сообщение локально (оптимистичный UI)
            errorMessage = "Нет сети. Сообщение будет отправлено автоматически."
            return
        }

        Task {
            do {
                try await messageService.send(
                    text: trimmed,
                    in: conversationId,
                    senderId: currentUserId,
                    senderName: currentUserName
                )
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Pagination

    func loadMoreIfNeeded() {
        guard canLoadMore, !isLoadingMore else { return }

        Task {
            isLoadingMore = true
            defer { isLoadingMore = false }

            guard let lastDoc = await cache.lastDocument(for: conversationId) else {
                canLoadMore = false
                return
            }

            do {
                let (older, newLastDoc) = try await messageService.loadMoreMessages(
                    conversationId: conversationId,
                    before: lastDoc,
                    limit: Self.pageSize
                )

                if older.isEmpty {
                    canLoadMore = false
                    return
                }

                for msg in older {
                    await cache.append(msg, to: conversationId)
                }
                if let doc = newLastDoc {
                    await cache.setLastDocument(doc, for: conversationId)
                }

                messages = await cache.messages(for: conversationId)
                    .sorted { $0.timestamp.dateValue() > $1.timestamp.dateValue() }

            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Typing

    func userIsTyping() {
        typingDebounce?.cancel()
        Task {
            try? await conversationService.updateTypingStatus(
                conversationId: conversationId,
                userId: currentUserId,
                isTyping: true
            )
        }
        // Через 3 сек без ввода — сбрасываем статус
        typingDebounce = Task {
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            stopTyping()
        }
    }

    func stopTyping() {
        typingDebounce?.cancel()
        Task {
            try? await conversationService.updateTypingStatus(
                conversationId: conversationId,
                userId: currentUserId,
                isTyping: false
            )
        }
    }

    // MARK: - Helpers

    private func markAsRead() {
        Task {
            try? await messageService.markAsRead(
                conversationId: conversationId,
                userId: currentUserId
            )
        }
    }
}

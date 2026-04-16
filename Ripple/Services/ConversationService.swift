import FirebaseFirestore
import FirebaseFirestoreSwift

// MARK: - Protocol

protocol ConversationServiceProtocol {
    func listenToConversations(
        userId: String,
        onUpdate: @escaping ([Conversation]) -> Void
    ) -> ListenerRegistration

    func createConversation(
        currentUserId: String,
        currentUserName: String,
        otherUserId: String,
        otherUserName: String
    ) async throws -> String

    func listenToTypingStatus(
        conversationId: String,
        onUpdate: @escaping ([String]) -> Void
    ) -> ListenerRegistration

    func updateTypingStatus(
        conversationId: String,
        userId: String,
        isTyping: Bool
    ) async throws

    func fetchUsers(excluding userId: String) async throws -> [User]
}

// MARK: - Firebase Implementation

final class ConversationService: ConversationServiceProtocol {
    private let db = Firestore.firestore()

    // MARK: - Listen to Conversations

    func listenToConversations(
        userId: String,
        onUpdate: @escaping ([Conversation]) -> Void
    ) -> ListenerRegistration {
        db.collection("conversations")
            .whereField("participantIds", arrayContains: userId)
            .order(by: "lastMessageTimestamp", descending: true)
            .addSnapshotListener { snapshot, error in
                guard let snapshot, error == nil else { return }
                let conversations = snapshot.documents.compactMap {
                    try? $0.data(as: Conversation.self)
                }
                Task { @MainActor in
                    onUpdate(conversations)
                }
            }
    }

    // MARK: - Create Conversation

    func createConversation(
        currentUserId: String,
        currentUserName: String,
        otherUserId: String,
        otherUserName: String
    ) async throws -> String {
        // Проверяем, нет ли уже чата между этими двумя пользователями
        let existing = try await db.collection("conversations")
            .whereField("participantIds", arrayContains: currentUserId)
            .getDocuments()

        if let found = existing.documents.first(where: { doc in
            guard let ids = doc.data()["participantIds"] as? [String] else { return false }
            return ids.contains(otherUserId)
        }) {
            return found.documentID
        }

        // Создаём новый чат
        let ref = db.collection("conversations").document()
        let conversation = Conversation(
            participantIds: [currentUserId, otherUserId],
            participantNames: [
                currentUserId: currentUserName,
                otherUserId: otherUserName
            ],
            lastMessage: "",
            lastMessageTimestamp: Timestamp(date: .now),
            unreadCount: [currentUserId: 0, otherUserId: 0]
        )
        try ref.setData(from: conversation)
        return ref.documentID
    }

    // MARK: - Typing Status

    func listenToTypingStatus(
        conversationId: String,
        onUpdate: @escaping ([String]) -> Void
    ) -> ListenerRegistration {
        db.collection("typingStatus")
            .document(conversationId)
            .addSnapshotListener { snapshot, _ in
                let typingUsers = snapshot?.data()?["typingUsers"] as? [String] ?? []
                Task { @MainActor in
                    onUpdate(typingUsers)
                }
            }
    }

    func updateTypingStatus(
        conversationId: String,
        userId: String,
        isTyping: Bool
    ) async throws {
        let ref = db.collection("typingStatus").document(conversationId)
        if isTyping {
            try await ref.setData(
                ["typingUsers": FieldValue.arrayUnion([userId])],
                merge: true
            )
        } else {
            try await ref.setData(
                ["typingUsers": FieldValue.arrayRemove([userId])],
                merge: true
            )
        }
    }

    // MARK: - Fetch Users

    func fetchUsers(excluding userId: String) async throws -> [User] {
        let snapshot = try await db.collection("users")
            .whereField("id", isNotEqualTo: userId)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: User.self) }
    }
}

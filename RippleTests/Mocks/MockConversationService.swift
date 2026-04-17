import FirebaseFirestore
@testable import Ripple

final class MockConversationService: ConversationServiceProtocol {

    // MARK: - Configuration

    var stubbedConversations: [Conversation] = []
    var stubbedUsers: [User] = []
    var stubbedConversationId = "mock-conversation-id"
    var shouldFail = false

    // MARK: - Tracking

    private(set) var createConversationCallCount = 0
    private(set) var typingStatusUpdates: [(userId: String, isTyping: Bool)] = []

    // MARK: - Protocol

    func listenToConversations(
        userId: String,
        onUpdate: @escaping ([Conversation]) -> Void
    ) -> ListenerRegistration {
        onUpdate(stubbedConversations)
        return MockListenerRegistration()
    }

    func createConversation(
        currentUserId: String, currentUserName: String,
        otherUserId: String, otherUserName: String
    ) async throws -> String {
        createConversationCallCount += 1
        if shouldFail {
            throw NSError(domain: "test", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Create failed"])
        }
        return stubbedConversationId
    }

    func listenToTypingStatus(
        conversationId: String,
        onUpdate: @escaping ([String]) -> Void
    ) -> ListenerRegistration {
        onUpdate([])
        return MockListenerRegistration()
    }

    func updateTypingStatus(
        conversationId: String, userId: String, isTyping: Bool
    ) async throws {
        typingStatusUpdates.append((userId: userId, isTyping: isTyping))
    }

    func fetchUsers(excluding userId: String) async throws -> [User] {
        if shouldFail {
            throw NSError(domain: "test", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Fetch failed"])
        }
        return stubbedUsers
    }
}

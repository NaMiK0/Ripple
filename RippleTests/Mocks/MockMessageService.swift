import UIKit
import FirebaseFirestore
@testable import Ripple

final class MockMessageService: MessageServiceProtocol {

    // MARK: - Configuration

    var shouldFail = false
    var stubbedMessages: [Message] = []
    var stubbedPaginatedMessages: [Message] = []

    // MARK: - Tracking

    private(set) var sendCallCount = 0
    private(set) var markAsReadCallCount = 0
    private(set) var lastSentText: String?
    private(set) var lastConversationId: String?

    // MARK: - Protocol

    func listenToMessages(
        conversationId: String,
        onUpdate: @escaping ([Message]) -> Void
    ) -> ListenerRegistration {
        onUpdate(stubbedMessages)
        return MockListenerRegistration()
    }

    func send(text: String, in conversationId: String,
              senderId: String, senderName: String) async throws {
        sendCallCount += 1
        lastSentText = text
        lastConversationId = conversationId
        if shouldFail {
            throw NSError(domain: "test", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Send failed"])
        }
    }

    func sendImage(_ image: UIImage, in conversationId: String,
                   senderId: String, senderName: String) async throws {
        if shouldFail {
            throw NSError(domain: "test", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Send image failed"])
        }
    }

    func markAsRead(conversationId: String, userId: String) async throws {
        markAsReadCallCount += 1
    }

    func loadMoreMessages(
        conversationId: String,
        before document: DocumentSnapshot,
        limit: Int
    ) async throws -> ([Message], DocumentSnapshot?) {
        return (stubbedPaginatedMessages, nil)
    }
}

// MARK: - MockListenerRegistration

final class MockListenerRegistration: NSObject, ListenerRegistration {
    private(set) var removeCallCount = 0
    func remove() { removeCallCount += 1 }
}

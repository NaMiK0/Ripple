import XCTest
@testable import Ripple

final class OfflineMessageQueueTests: XCTestCase {

    private var sut: OfflineMessageQueue!
    private let udKey = "ripple_offline_queue" // должен совпадать с ключом в сервисе

    override func setUp() {
        super.setUp()
        // Очищаем реальный ключ перед каждым тестом
        UserDefaults.standard.removeObject(forKey: udKey)
        sut = OfflineMessageQueue()
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: udKey)
        sut = nil
        super.tearDown()
    }

    // MARK: - Enqueue

    func test_enqueue_addsMessageToPending() {
        let msg = makeQueuedMessage(text: "Hello")
        sut.enqueue(msg)
        XCTAssertEqual(sut.pendingMessages.count, 1)
        XCTAssertEqual(sut.pendingMessages.first?.text, "Hello")
    }

    func test_enqueue_multipleMessages_preservesOrder() {
        let texts = ["First", "Second", "Third"]
        texts.forEach { sut.enqueue(makeQueuedMessage(text: $0)) }
        XCTAssertEqual(sut.pendingMessages.map(\.text), texts)
    }

    // MARK: - Dequeue

    func test_dequeue_removesMessageById() {
        let msg1 = makeQueuedMessage(text: "First")
        let msg2 = makeQueuedMessage(text: "Second")
        sut.enqueue(msg1)
        sut.enqueue(msg2)

        sut.dequeue(id: msg1.id)

        XCTAssertEqual(sut.pendingMessages.count, 1)
        XCTAssertEqual(sut.pendingMessages.first?.text, "Second")
    }

    func test_dequeue_nonExistentId_doesNothing() {
        sut.enqueue(makeQueuedMessage(text: "Hello"))
        sut.dequeue(id: "nonexistent-id")
        XCTAssertEqual(sut.pendingMessages.count, 1)
    }

    func test_dequeue_allMessages_emptyQueue() {
        let msg = makeQueuedMessage(text: "Only one")
        sut.enqueue(msg)
        sut.dequeue(id: msg.id)
        XCTAssertTrue(sut.pendingMessages.isEmpty)
    }

    // MARK: - QueuedMessage Codable

    func test_queuedMessage_codable_roundTrip() throws {
        let original = makeQueuedMessage(text: "Test message")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(QueuedMessage.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.text, original.text)
        XCTAssertEqual(decoded.senderId, original.senderId)
        XCTAssertEqual(decoded.senderName, original.senderName)
        XCTAssertEqual(decoded.conversationId, original.conversationId)
    }

    // MARK: - QueuedMessage Init

    func test_queuedMessage_hasUniqueIds() {
        let msg1 = makeQueuedMessage(text: "A")
        let msg2 = makeQueuedMessage(text: "B")
        XCTAssertNotEqual(msg1.id, msg2.id)
    }

    func test_queuedMessage_createdAtIsRecent() {
        let msg = makeQueuedMessage(text: "Hello")
        XCTAssertLessThan(Date.now.timeIntervalSince(msg.createdAt), 1.0)
    }

    // MARK: - Helpers

    private func makeQueuedMessage(text: String) -> QueuedMessage {
        QueuedMessage(
            conversationId: "test-conv",
            text: text,
            senderId: "user123",
            senderName: "Test User"
        )
    }
}

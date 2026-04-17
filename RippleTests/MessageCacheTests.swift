import XCTest
import FirebaseFirestore
@testable import Ripple

final class MessageCacheTests: XCTestCase {

    private var sut: MessageCache!

    override func setUp() {
        super.setUp()
        sut = MessageCache()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Store & Retrieve

    func test_store_andRetrieve_returnsStoredMessages() async {
        let messages = makeMessages(count: 3, conversationId: "conv1")
        await sut.store(messages, for: "conv1")

        let result = await sut.messages(for: "conv1")
        XCTAssertEqual(result.count, 3)
    }

    func test_messages_emptyConversation_returnsEmpty() async {
        let result = await sut.messages(for: "nonexistent")
        XCTAssertTrue(result.isEmpty)
    }

    // MARK: - Append

    func test_append_addsMessage() async {
        let message = makeMessage(id: "msg1", conversationId: "conv1")
        await sut.append(message, to: "conv1")

        let result = await sut.messages(for: "conv1")
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.id, "msg1")
    }

    func test_append_multipleTimes_accumulatesMessages() async {
        for i in 1...5 {
            let msg = makeMessage(id: "msg\(i)", conversationId: "conv1")
            await sut.append(msg, to: "conv1")
        }
        let result = await sut.messages(for: "conv1")
        XCTAssertEqual(result.count, 5)
    }

    // MARK: - Deduplication

    func test_append_duplicateId_deduplicates() async {
        let message = makeMessage(id: "msg1", conversationId: "conv1")
        await sut.append(message, to: "conv1")
        await sut.append(message, to: "conv1") // дубль

        let result = await sut.messages(for: "conv1")
        XCTAssertEqual(result.count, 1, "Duplicate messages should be deduplicated")
    }

    func test_append_differentIds_noDeduplicate() async {
        await sut.append(makeMessage(id: "msg1", conversationId: "conv1"), to: "conv1")
        await sut.append(makeMessage(id: "msg2", conversationId: "conv1"), to: "conv1")

        let result = await sut.messages(for: "conv1")
        XCTAssertEqual(result.count, 2)
    }

    // MARK: - Isolation (different conversations)

    func test_store_differentConversations_isolated() async {
        let msgs1 = makeMessages(count: 2, conversationId: "conv1")
        let msgs2 = makeMessages(count: 3, conversationId: "conv2")

        await sut.store(msgs1, for: "conv1")
        await sut.store(msgs2, for: "conv2")

        let result1 = await sut.messages(for: "conv1")
        let result2 = await sut.messages(for: "conv2")

        XCTAssertEqual(result1.count, 2)
        XCTAssertEqual(result2.count, 3)
    }

    // MARK: - Helpers

    private func makeMessage(id: String, conversationId: String) -> Message {
        // Синтезированный memberwise init у struct с @DocumentID включает id: String?
        // Передаём id явно — он корректно устанавливается через wrapped value
        Message(
            id: id,
            senderId: "user1",
            senderName: "Test User",
            text: "Hello \(id)",
            timestamp: Timestamp(date: .now),
            status: .sent,
            imageURL: nil
        )
    }

    private func makeMessages(count: Int, conversationId: String) -> [Message] {
        (1...count).map { makeMessage(id: "msg\($0)-\(conversationId)", conversationId: conversationId) }
    }
}

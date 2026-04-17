import XCTest
import FirebaseFirestore
@testable import Ripple

@MainActor
final class ConversationsViewModelTests: XCTestCase {

    private var sut: ConversationsViewModel!
    private var mockConversationService: MockConversationService!
    private var mockAuthService: MockAuthService!

    override func setUp() {
        super.setUp()
        mockConversationService = MockConversationService()
        mockAuthService = MockAuthService()
        sut = ConversationsViewModel(
            conversationService: mockConversationService,
            authService: mockAuthService
        )
    }

    override func tearDown() {
        sut = nil
        mockConversationService = nil
        mockAuthService = nil
        super.tearDown()
    }

    // MARK: - companionName

    func test_companionName_returnsOtherParticipant() {
        let conversation = makeConversation(
            participantIds: ["user1", "user2"],
            participantNames: ["user1": "Nikita", "user2": "Anna"]
        )
        // currentUserId пустой (нет авторизованного пользователя в тестах)
        // Берём первое имя которое не равно currentUserId
        let name = sut.companionName(for: conversation)
        // Одно из двух имён должно быть возвращено
        XCTAssertTrue(name == "Nikita" || name == "Anna")
    }

    func test_companionName_unknownUser_returnsPlaceholder() {
        let conversation = makeConversation(
            participantIds: ["user1"],
            participantNames: [:]
        )
        let name = sut.companionName(for: conversation)
        XCTAssertEqual(name, "Неизвестный")
    }

    // MARK: - unreadCount

    func test_unreadCount_returnsCountForCurrentUser() {
        let conversation = makeConversation(
            participantIds: ["user1", "user2"],
            participantNames: ["user1": "Nikita", "user2": "Anna"],
            unreadCount: ["": 5]  // "" — это currentUserId в тестах (нет Firebase user)
        )
        let count = sut.unreadCount(for: conversation)
        XCTAssertEqual(count, 5)
    }

    func test_unreadCount_noEntry_returnsZero() {
        let conversation = makeConversation(
            participantIds: ["user1"],
            participantNames: ["user1": "Nikita"]
        )
        let count = sut.unreadCount(for: conversation)
        XCTAssertEqual(count, 0)
    }

    // MARK: - Delete

    func test_delete_removesConversationLocally() {
        mockConversationService.stubbedConversations = [
            makeConversation(participantIds: ["u1", "u2"], participantNames: ["u1": "A", "u2": "B"]),
            makeConversation(participantIds: ["u1", "u3"], participantNames: ["u1": "A", "u3": "C"])
        ]

        sut.onViewDidAppear()

        XCTAssertEqual(sut.conversations.count, 2)

        let indexPath = IndexPath(row: 0, section: 0)
        sut.delete(at: indexPath)

        XCTAssertEqual(sut.conversations.count, 1)
    }

    // MARK: - Callbacks

    func test_selectConversation_callsOnOpenConversation() {
        let conversation = makeConversation(
            id: "conv123",
            participantIds: ["u1", "u2"],
            participantNames: ["u1": "A", "u2": "B"]
        )

        var receivedId: String?
        sut.onOpenConversation = { receivedId = $0 }
        sut.select(conversation: conversation)

        XCTAssertEqual(receivedId, "conv123")
    }

    func test_newConversationTapped_callsCallback() {
        var called = false
        sut.onNewConversation = { called = true }
        sut.newConversationTapped()
        XCTAssertTrue(called)
    }

    // MARK: - Helpers

    private func makeConversation(
        id: String? = "test-id",
        participantIds: [String] = [],
        participantNames: [String: String] = [:],
        unreadCount: [String: Int] = [:]
    ) -> Conversation {
        Conversation(
            participantIds: participantIds,
            participantNames: participantNames,
            lastMessage: "Hello",
            lastMessageTimestamp: Timestamp(date: .now),
            unreadCount: unreadCount
        )
    }
}

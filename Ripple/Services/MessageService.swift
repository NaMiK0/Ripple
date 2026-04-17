import UIKit
import FirebaseFirestore


// MARK: - Protocol

protocol MessageServiceProtocol {
    func listenToMessages(
        conversationId: String,
        onUpdate: @escaping ([Message]) -> Void
    ) -> ListenerRegistration

    func send(
        text: String,
        in conversationId: String,
        senderId: String,
        senderName: String
    ) async throws

    func sendImage(
        _ image: UIImage,
        in conversationId: String,
        senderId: String,
        senderName: String
    ) async throws

    func markAsRead(
        conversationId: String,
        userId: String
    ) async throws

    func loadMoreMessages(
        conversationId: String,
        before document: DocumentSnapshot,
        limit: Int
    ) async throws -> ([Message], DocumentSnapshot?)
}

// MARK: - Firebase Implementation

final class MessageService: MessageServiceProtocol {
    private let db = Firestore.firestore()
    private let imageUploadService: ImageUploadServiceProtocol

    init(imageUploadService: ImageUploadServiceProtocol = ImageUploadService()) {
        self.imageUploadService = imageUploadService
    }

    // MARK: - Listen

    func listenToMessages(
        conversationId: String,
        onUpdate: @escaping ([Message]) -> Void
    ) -> ListenerRegistration {
        db.collection("conversations")
            .document(conversationId)
            .collection("messages")
            .order(by: "timestamp", descending: true)
            .limit(to: 30)
            .addSnapshotListener { snapshot, error in
                guard let docs = snapshot?.documentChanges, error == nil else { return }
                let messages = docs
                    .filter { $0.type == .added }
                    .compactMap { try? $0.document.data(as: Message.self) }
                guard !messages.isEmpty else { return }
                Task { @MainActor in
                    onUpdate(messages)
                }
            }
    }

    // MARK: - Send Text

    func send(
        text: String,
        in conversationId: String,
        senderId: String,
        senderName: String
    ) async throws {
        let message = Message(
            senderId: senderId,
            senderName: senderName,
            text: text,
            timestamp: Timestamp(date: .now),
            status: .sent,
            imageURL: nil
        )
        try await saveMessage(message, in: conversationId)
    }

    // MARK: - Send Image

    func sendImage(
        _ image: UIImage,
        in conversationId: String,
        senderId: String,
        senderName: String
    ) async throws {
        let path = "chat_images/\(conversationId)/\(UUID().uuidString).jpg"
        let imageURL = try await imageUploadService.uploadImage(image, path: path)

        let message = Message(
            senderId: senderId,
            senderName: senderName,
            text: "",
            timestamp: Timestamp(date: .now),
            status: .sent,
            imageURL: imageURL
        )
        try await saveMessage(message, in: conversationId)
    }

    // MARK: - Mark as Read

    func markAsRead(conversationId: String, userId: String) async throws {
        try await db.collection("conversations")
            .document(conversationId)
            .updateData(["unreadCount.\(userId)": 0])
    }

    // MARK: - Pagination

    func loadMoreMessages(
        conversationId: String,
        before document: DocumentSnapshot,
        limit: Int
    ) async throws -> ([Message], DocumentSnapshot?) {
        let snapshot = try await db.collection("conversations")
            .document(conversationId)
            .collection("messages")
            .order(by: "timestamp", descending: true)
            .start(afterDocument: document)
            .limit(to: limit)
            .getDocuments()

        let messages = snapshot.documents.compactMap { try? $0.data(as: Message.self) }
        let lastDocument = snapshot.documents.last
        return (messages, lastDocument)
    }

    // MARK: - Private Helpers

    private func saveMessage(_ message: Message, in conversationId: String) async throws {
        let ref = db.collection("conversations")
            .document(conversationId)
            .collection("messages")
            .document()

        try ref.setData(from: message)

        // Обновляем lastMessage и lastMessageTimestamp в документе чата
        let preview = message.imageURL != nil ? "📷 Фото" : message.text
        try await db.collection("conversations")
            .document(conversationId)
            .updateData([
                "lastMessage": preview,
                "lastMessageTimestamp": message.timestamp
            ])
    }
}

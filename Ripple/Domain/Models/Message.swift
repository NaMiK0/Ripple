import FirebaseFirestore


struct Message: Codable, Identifiable, Hashable {
    @DocumentID var id: String?
    let senderId: String
    let senderName: String
    let text: String
    let timestamp: Timestamp
    var status: MessageStatus
    let imageURL: String?

    enum MessageStatus: String, Codable {
        case sent, delivered, read
    }
}

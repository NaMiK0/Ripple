import FirebaseFirestore
import FirebaseFirestoreSwift

struct Conversation: Codable, Identifiable, Hashable {
    @DocumentID var id: String?
    let participantIds: [String]
    let participantNames: [String: String]   // uid → displayName
    let lastMessage: String
    let lastMessageTimestamp: Timestamp
    var unreadCount: [String: Int]           // uid → count
}

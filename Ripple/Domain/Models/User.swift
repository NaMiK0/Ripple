import FirebaseFirestore


struct User: Codable, Identifiable {
    let id: String
    let displayName: String
    let avatarURL: String?
    let fcmToken: String?
    let isOnline: Bool
    let lastSeen: Timestamp
}

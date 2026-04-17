import FirebaseAuth
import FirebaseFirestore

// MARK: - Protocol

protocol AuthServiceProtocol {
    var currentUser: FirebaseAuth.User? { get }
    /// UID авторизованного пользователя (пустая строка если не авторизован)
    var currentUserId: String { get }
    func signIn(email: String, password: String) async throws
    func register(email: String, password: String, displayName: String) async throws
    func signOut() throws
}

// MARK: - Firebase Implementation

final class AuthService: AuthServiceProtocol {
    private let auth = Auth.auth()
    private let db = Firestore.firestore()

    var currentUser: FirebaseAuth.User? {
        auth.currentUser
    }

    var currentUserId: String {
        auth.currentUser?.uid ?? ""
    }

    func signIn(email: String, password: String) async throws {
        try await auth.signIn(withEmail: email, password: password)
    }

    func register(email: String, password: String, displayName: String) async throws {
        let result = try await auth.createUser(withEmail: email, password: password)
        let uid = result.user.uid

        let userData: [String: Any] = [
            "id": uid,
            "displayName": displayName,
            "avatarURL": NSNull(),
            "fcmToken": NSNull(),
            "isOnline": true,
            "lastSeen": Timestamp(date: .now)
        ]
        try await db.collection("users").document(uid).setData(userData)
    }

    func signOut() throws {
        try auth.signOut()
    }
}

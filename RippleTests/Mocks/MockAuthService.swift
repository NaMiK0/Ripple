import FirebaseAuth
@testable import Ripple

final class MockAuthService: AuthServiceProtocol {

    // MARK: - Configuration

    var shouldFail = false
    var errorToThrow: Error = NSError(domain: "test", code: -1,
                                       userInfo: [NSLocalizedDescriptionKey: "Mock error"])
    var stubbedUser: FirebaseAuth.User? = nil
    /// Возвращается из currentUserId, не требует реального Firebase User
    var stubbedCurrentUserId: String = "test-user-id"

    // MARK: - Tracking

    private(set) var signInCallCount = 0
    private(set) var registerCallCount = 0
    private(set) var signOutCallCount = 0
    private(set) var lastEmail: String?
    private(set) var lastPassword: String?
    private(set) var lastDisplayName: String?

    // MARK: - Protocol

    var currentUser: FirebaseAuth.User? { stubbedUser }
    var currentUserId: String { stubbedCurrentUserId }

    func signIn(email: String, password: String) async throws {
        signInCallCount += 1
        lastEmail = email
        lastPassword = password
        if shouldFail { throw errorToThrow }
    }

    func register(email: String, password: String, displayName: String) async throws {
        registerCallCount += 1
        lastEmail = email
        lastPassword = password
        lastDisplayName = displayName
        if shouldFail { throw errorToThrow }
    }

    func signOut() throws {
        signOutCallCount += 1
        if shouldFail { throw errorToThrow }
    }
}

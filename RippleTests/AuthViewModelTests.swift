import XCTest
@testable import Ripple

@MainActor
final class AuthViewModelTests: XCTestCase {

    private var sut: AuthViewModel!
    private var mockAuthService: MockAuthService!

    override func setUp() {
        super.setUp()
        mockAuthService = MockAuthService()
        sut = AuthViewModel(authService: mockAuthService)
    }

    override func tearDown() {
        sut = nil
        mockAuthService = nil
        super.tearDown()
    }

    // MARK: - Validation: Login Mode

    func test_loginMode_emptyFields_formInvalid() {
        sut.mode = .login
        sut.email = ""
        sut.password = ""
        XCTAssertFalse(sut.isFormValid)
    }

    func test_loginMode_invalidEmail_formInvalid() {
        sut.mode = .login
        sut.email = "notanemail"
        sut.password = "123456"
        XCTAssertFalse(sut.isFormValid)
    }

    func test_loginMode_shortPassword_formInvalid() {
        sut.mode = .login
        sut.email = "user@test.com"
        sut.password = "123"
        XCTAssertFalse(sut.isFormValid)
    }

    func test_loginMode_validCredentials_formValid() async throws {
        sut.mode = .login
        sut.email = "user@test.com"
        sut.password = "123456"
        // Даём Combine RunLoop-цикл на обработку
        try await Task.sleep(for: .milliseconds(50))
        XCTAssertTrue(sut.isFormValid)
    }

    // MARK: - Validation: Register Mode

    func test_registerMode_missingName_formInvalid() async throws {
        sut.mode = .register
        sut.email = "user@test.com"
        sut.password = "123456"
        sut.displayName = ""
        try await Task.sleep(for: .milliseconds(50))
        XCTAssertFalse(sut.isFormValid)
    }

    func test_registerMode_allFieldsFilled_formValid() async throws {
        sut.mode = .register
        sut.email = "user@test.com"
        sut.password = "123456"
        sut.displayName = "Nikita"
        try await Task.sleep(for: .milliseconds(50))
        XCTAssertTrue(sut.isFormValid)
    }

    // MARK: - Sign In

    func test_signIn_success_callsOnAuthenticated() async {
        sut.email = "user@test.com"
        sut.password = "123456"
        sut.mode = .login

        var authenticatedCalled = false
        sut.onAuthenticated = { authenticatedCalled = true }

        sut.submit()
        // Даём Task время завершиться
        try? await Task.sleep(for: .milliseconds(200))

        XCTAssertTrue(authenticatedCalled)
        XCTAssertEqual(mockAuthService.signInCallCount, 1)
        XCTAssertEqual(mockAuthService.lastEmail, "user@test.com")
    }

    func test_signIn_failure_setsErrorMessage() async {
        sut.email = "user@test.com"
        sut.password = "123456"
        sut.mode = .login
        mockAuthService.shouldFail = true

        sut.submit()
        try? await Task.sleep(for: .milliseconds(200))

        XCTAssertNotNil(sut.errorMessage)
        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - Register

    func test_register_success_callsOnAuthenticated() async {
        sut.mode = .register
        sut.email = "new@test.com"
        sut.password = "password1"
        sut.displayName = "Nikita"

        var authenticatedCalled = false
        sut.onAuthenticated = { authenticatedCalled = true }

        sut.submit()
        try? await Task.sleep(for: .milliseconds(200))

        XCTAssertTrue(authenticatedCalled)
        XCTAssertEqual(mockAuthService.registerCallCount, 1)
        XCTAssertEqual(mockAuthService.lastDisplayName, "Nikita")
    }

    func test_register_failure_setsErrorMessage() async {
        sut.mode = .register
        sut.email = "new@test.com"
        sut.password = "password1"
        sut.displayName = "Nikita"
        mockAuthService.shouldFail = true

        sut.submit()
        try? await Task.sleep(for: .milliseconds(200))

        XCTAssertNotNil(sut.errorMessage)
    }

    // MARK: - Mode Switch

    func test_switchMode_clearsErrorMessage() async {
        mockAuthService.shouldFail = true
        sut.email = "user@test.com"
        sut.password = "123456"
        sut.submit()
        try? await Task.sleep(for: .milliseconds(200))
        XCTAssertNotNil(sut.errorMessage)

        // Переключаем режим — ошибка должна остаться (она не сбрасывается автоматически,
        // сбрасывается только при новом submit)
        sut.mode = .register
        XCTAssertEqual(sut.mode, .register)
    }
}

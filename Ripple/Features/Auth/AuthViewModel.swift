import Combine
import Foundation

enum AuthMode {
    case login, register
}

@MainActor
final class AuthViewModel: ObservableObject {

    // MARK: - Input

    @Published var email: String = ""
    @Published var password: String = ""
    @Published var displayName: String = ""
    @Published var mode: AuthMode = .login

    // MARK: - Output

    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var isFormValid: Bool = false

    // MARK: - Callbacks

    var onAuthenticated: (() -> Void)?

    // MARK: - Private

    private let authService: AuthServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init(authService: AuthServiceProtocol) {
        self.authService = authService
        bindValidation()
    }

    // MARK: - Validation

    private func bindValidation() {
        // Все 4 поля включены в один CombineLatest — форма перевалидируется
        // при изменении любого из них (в том числе displayName)
        Publishers.CombineLatest3($email, $password, $mode)
            .combineLatest($displayName) { tuple, name -> Bool in
                let (email, password, mode) = tuple
                let emailValid = email.contains("@") && email.contains(".")
                let passwordValid = password.count >= 6
                if mode == .register {
                    return emailValid && passwordValid
                        && !name.trimmingCharacters(in: .whitespaces).isEmpty
                }
                return emailValid && passwordValid
            }
            .assign(to: &$isFormValid)
    }

    // MARK: - Actions

    func submit() {
        switch mode {
        case .login:  signIn()
        case .register: register()
        }
    }

    private func signIn() {
        isLoading = true
        errorMessage = nil
        Task {
            defer { isLoading = false }
            do {
                try await authService.signIn(email: email, password: password)
                onAuthenticated?()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func register() {
        isLoading = true
        errorMessage = nil
        Task {
            defer { isLoading = false }
            do {
                try await authService.register(
                    email: email,
                    password: password,
                    displayName: displayName.trimmingCharacters(in: .whitespaces)
                )
                onAuthenticated?()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

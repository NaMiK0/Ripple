import UIKit

@MainActor
final class AuthCoordinator {

    // MARK: - Properties

    private let navigationController: UINavigationController
    var onAuthenticated: (() -> Void)?

    // MARK: - Init

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    // MARK: - Start

    func start() {
        let authService = AuthService()
        let viewModel = AuthViewModel(authService: authService)
        viewModel.onAuthenticated = { [weak self] in
            self?.onAuthenticated?()
        }
        let viewController = AuthViewController(viewModel: viewModel)
        viewController.navigationItem.largeTitleDisplayMode = .always
        navigationController.setViewControllers([viewController], animated: false)
    }
}

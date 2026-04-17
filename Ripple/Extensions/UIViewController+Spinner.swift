import UIKit

private var spinnerKey: UInt8 = 0

extension UIViewController {

    private var spinner: UIActivityIndicatorView? {
        get { objc_getAssociatedObject(self, &spinnerKey) as? UIActivityIndicatorView }
        set { objc_setAssociatedObject(self, &spinnerKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    func showSpinner() {
        guard spinner == nil else { return }
        let ai = UIActivityIndicatorView(style: .large)
        ai.translatesAutoresizingMaskIntoConstraints = false
        ai.color = .systemBlue
        view.addSubview(ai)
        NSLayoutConstraint.activate([
            ai.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            ai.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        ai.startAnimating()
        spinner = ai
        view.isUserInteractionEnabled = false
    }

    func hideSpinner() {
        spinner?.stopAnimating()
        spinner?.removeFromSuperview()
        spinner = nil
        view.isUserInteractionEnabled = true
    }
}

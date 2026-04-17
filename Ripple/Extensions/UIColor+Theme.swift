import UIKit

extension UIColor {

    // MARK: - Brand

    /// Основной акцент — Discord Purple
    static let ripplePrimary   = UIColor(hex: "#7289DA")
    /// Вторичный акцент — мягкий фиолет
    static let rippleSecondary = UIColor(hex: "#9B72CF")

    // MARK: - Backgrounds

    static let rippleBackground     = UIColor(hex: "#FAFAFA")
    static let rippleCard           = UIColor.white
    static let rippleSurface        = UIColor(hex: "#F2F3F5")

    // MARK: - Bubbles

    static let outgoingBubbleStart  = UIColor(hex: "#7289DA")
    static let outgoingBubbleEnd    = UIColor(hex: "#9B72CF")
    static let incomingBubble       = UIColor(hex: "#F2F3F5")

    // MARK: - Text

    static let rippleTextPrimary    = UIColor(hex: "#2E3338")
    static let rippleTextSecondary  = UIColor(hex: "#72767D")

    // MARK: - Hex Init

    convenience init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.hasPrefix("#") ? String(hexSanitized.dropFirst()) : hexSanitized
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255
        let g = CGFloat((rgb & 0x00FF00) >> 8)  / 255
        let b = CGFloat(rgb & 0x0000FF)          / 255
        self.init(red: r, green: g, blue: b, alpha: 1)
    }
}

// MARK: - Gradient Helper

extension CAGradientLayer {

    static func ripplePrimary(frame: CGRect) -> CAGradientLayer {
        let layer = CAGradientLayer()
        layer.colors = [
            UIColor.outgoingBubbleStart.cgColor,
            UIColor.outgoingBubbleEnd.cgColor
        ]
        layer.startPoint = CGPoint(x: 0, y: 0.5)
        layer.endPoint   = CGPoint(x: 1, y: 0.5)
        layer.frame = frame
        return layer
    }

    static func rippleHero(frame: CGRect) -> CAGradientLayer {
        let layer = CAGradientLayer()
        layer.colors = [
            UIColor(hex: "#7289DA").cgColor,
            UIColor(hex: "#9B72CF").cgColor,
            UIColor(hex: "#C44EF5").withAlphaComponent(0.7).cgColor
        ]
        layer.startPoint = CGPoint(x: 0, y: 0)
        layer.endPoint   = CGPoint(x: 1, y: 1)
        layer.frame = frame
        return layer
    }
}

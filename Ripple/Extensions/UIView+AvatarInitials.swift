import UIKit

extension UIImageView {

    /// Аватар из инициалов с градиентным фоном
    func setInitialsAvatar(name: String, size: CGFloat = 48) {
        let initials = name
            .components(separatedBy: " ")
            .compactMap { $0.first }
            .prefix(2)
            .map { String($0).uppercased() }
            .joined()

        // Стабильный градиент на основе хеша имени
        let gradients: [(UIColor, UIColor)] = [
            (UIColor(hex: "#7289DA"), UIColor(hex: "#9B72CF")),
            (UIColor(hex: "#FF6B9D"), UIColor(hex: "#C44EF5")),
            (UIColor(hex: "#00C9A7"), UIColor(hex: "#00B4D8")),
            (UIColor(hex: "#F5A623"), UIColor(hex: "#FF6B6B")),
            (UIColor(hex: "#5B9BF0"), UIColor(hex: "#7289DA")),
            (UIColor(hex: "#C44EF5"), UIColor(hex: "#7289DA"))
        ]
        let idx = abs(name.hashValue) % gradients.count
        let (startColor, endColor) = gradients[idx]

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        let image = renderer.image { ctx in
            let rect = CGRect(x: 0, y: 0, width: size, height: size)

            // Обрезаем по кругу
            UIBezierPath(ovalIn: rect).addClip()

            // Рисуем градиент
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [startColor.cgColor, endColor.cgColor] as CFArray,
                locations: [0, 1]
            )!
            ctx.cgContext.drawLinearGradient(
                gradient,
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: size, y: size),
                options: []
            )

            // Инициалы
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: size * 0.38, weight: .semibold),
                .foregroundColor: UIColor.white
            ]
            let str = NSAttributedString(string: initials, attributes: attrs)
            let textSize = str.size()
            let textRect = CGRect(
                x: (size - textSize.width) / 2,
                y: (size - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            str.draw(in: textRect)
        }

        self.image = image
    }
}

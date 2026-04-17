import UIKit

extension UIImageView {

    /// Отрисовывает аватар из инициалов если нет фото
    func setInitialsAvatar(name: String, size: CGFloat = 48) {
        let initials = name
            .components(separatedBy: " ")
            .compactMap { $0.first }
            .prefix(2)
            .map { String($0).uppercased() }
            .joined()

        let colors: [UIColor] = [
            .systemBlue, .systemPurple, .systemGreen,
            .systemOrange, .systemPink, .systemTeal
        ]
        // Стабильный цвет на основе хеша имени
        let colorIndex = abs(name.hashValue) % colors.count
        let bgColor = colors[colorIndex]

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        let image = renderer.image { ctx in
            bgColor.setFill()
            ctx.cgContext.fillEllipse(in: CGRect(x: 0, y: 0, width: size, height: size))

            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: size * 0.38, weight: .semibold),
                .foregroundColor: UIColor.white
            ]
            let str = NSAttributedString(string: initials, attributes: attrs)
            let textSize = str.size()
            let rect = CGRect(
                x: (size - textSize.width) / 2,
                y: (size - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            str.draw(in: rect)
        }
        self.image = image
    }
}

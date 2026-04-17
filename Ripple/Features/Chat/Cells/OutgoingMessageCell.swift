import UIKit
import FirebaseFirestore

final class OutgoingMessageCell: UITableViewCell {
    static let reuseId = "OutgoingMessageCell"

    // MARK: - UI

    private let bubbleView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 18
        v.layer.cornerCurve = .continuous
        v.clipsToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private var bubbleGradient: CAGradientLayer?

    private let messageLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 16)
        l.textColor = .white
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let timeLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 11)
        l.textColor = UIColor.white.withAlphaComponent(0.7)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let statusLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 11)
        l.textColor = UIColor.white.withAlphaComponent(0.7)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if bubbleGradient == nil {
            let gradient = CAGradientLayer.ripplePrimary(frame: bubbleView.bounds)
            bubbleView.layer.insertSublayer(gradient, at: 0)
            bubbleGradient = gradient
        } else {
            bubbleGradient?.frame = bubbleView.bounds
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Setup

    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none

        // Ячейка инвертирована вместе с таблицей — возвращаем обратно
        transform = CGAffineTransform(scaleX: 1, y: -1)

        contentView.addSubview(bubbleView)
        bubbleView.addSubview(messageLabel)
        bubbleView.addSubview(timeLabel)
        bubbleView.addSubview(statusLabel)

        NSLayoutConstraint.activate([
            bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            bubbleView.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 60),

            messageLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 10),
            messageLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 14),
            messageLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -14),

            timeLabel.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 4),
            timeLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 14),
            timeLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -8),

            statusLabel.centerYAnchor.constraint(equalTo: timeLabel.centerYAnchor),
            statusLabel.leadingAnchor.constraint(equalTo: timeLabel.trailingAnchor, constant: 4),
            statusLabel.trailingAnchor.constraint(lessThanOrEqualTo: bubbleView.trailingAnchor, constant: -14)
        ])
    }

    // MARK: - Configure

    func configure(message: Message, isRead: Bool) {
        messageLabel.text = message.text
        timeLabel.text = message.timestamp.dateValue().timeFormatted()
        statusLabel.text = statusIcon(for: message.status)
    }

    private func statusIcon(for status: Message.MessageStatus) -> String {
        switch status {
        case .sent:      return "✓"
        case .delivered: return "✓✓"
        case .read:      return "✓✓"
        }
    }
}

// MARK: - Date Helper

private extension Date {
    func timeFormatted() -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: self)
    }
}

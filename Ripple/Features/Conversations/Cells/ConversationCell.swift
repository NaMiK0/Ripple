import UIKit
import Kingfisher
import SkeletonView

final class ConversationCell: UITableViewCell {
    static let reuseId = "ConversationCell"

    // MARK: - UI

    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 26
        iv.layer.cornerCurve = .continuous
        iv.backgroundColor = .rippleSurface
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.isSkeletonable = true
        return iv
    }()

    private let onlineIndicator: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hex: "#43B581") // Discord online green
        view.layer.cornerRadius = 7
        view.layer.borderWidth = 2.5
        view.layer.borderColor = UIColor.rippleBackground.cgColor
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .rippleTextPrimary
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isSkeletonable = true
        return label
    }()

    private let lastMessageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .rippleTextSecondary
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isSkeletonable = true
        return label
    }()

    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .rippleTextSecondary
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let unreadBadge: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 11, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        label.layer.cornerRadius = 10
        label.clipsToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()

    private var badgeGradient: CAGradientLayer?

    private let textStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 4
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        isSkeletonable = true
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        if let gradient = badgeGradient {
            gradient.frame = unreadBadge.bounds
        }
    }

    // MARK: - Setup

    private func setupUI() {
        backgroundColor = .rippleBackground
        selectionStyle = .none

        let highlightView = UIView()
        highlightView.backgroundColor = UIColor.ripplePrimary.withAlphaComponent(0.06)
        selectedBackgroundView = highlightView

        contentView.addSubview(avatarImageView)
        contentView.addSubview(onlineIndicator)
        contentView.addSubview(textStack)
        contentView.addSubview(timeLabel)
        contentView.addSubview(unreadBadge)

        textStack.addArrangedSubview(nameLabel)
        textStack.addArrangedSubview(lastMessageLabel)

        NSLayoutConstraint.activate([
            avatarImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            avatarImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 52),
            avatarImageView.heightAnchor.constraint(equalToConstant: 52),
            avatarImageView.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: 10),
            avatarImageView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -10),

            onlineIndicator.widthAnchor.constraint(equalToConstant: 14),
            onlineIndicator.heightAnchor.constraint(equalToConstant: 14),
            onlineIndicator.trailingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 1),
            onlineIndicator.bottomAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 1),

            textStack.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 12),
            textStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            textStack.trailingAnchor.constraint(lessThanOrEqualTo: timeLabel.leadingAnchor, constant: -8),

            timeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            timeLabel.topAnchor.constraint(equalTo: nameLabel.topAnchor),

            unreadBadge.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            unreadBadge.bottomAnchor.constraint(equalTo: lastMessageLabel.bottomAnchor),
            unreadBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 20),
            unreadBadge.heightAnchor.constraint(equalToConstant: 20)
        ])
    }

    // MARK: - Configure

    func configure(
        name: String,
        lastMessage: String,
        timestamp: Date,
        avatarURL: String?,
        unreadCount: Int,
        isOnline: Bool
    ) {
        nameLabel.text = name
        lastMessageLabel.text = lastMessage.isEmpty ? "Нет сообщений" : lastMessage
        timeLabel.text = timestamp.chatFormatted()
        onlineIndicator.isHidden = !isOnline

        timeLabel.textColor = unreadCount > 0 ? .ripplePrimary : .rippleTextSecondary

        if let urlString = avatarURL, let url = URL(string: urlString) {
            avatarImageView.kf.setImage(with: url, options: [.transition(.fade(0.2))])
        } else {
            avatarImageView.setInitialsAvatar(name: name, size: 52)
        }

        if unreadCount > 0 {
            unreadBadge.text = unreadCount > 99 ? "99+" : "\(unreadCount)"
            unreadBadge.isHidden = false
            if badgeGradient == nil {
                let g = CAGradientLayer.ripplePrimary(frame: unreadBadge.bounds)
                unreadBadge.layer.insertSublayer(g, at: 0)
                badgeGradient = g
            }
        } else {
            unreadBadge.isHidden = true
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        avatarImageView.kf.cancelDownloadTask()
        avatarImageView.image = nil
        unreadBadge.isHidden = true
        onlineIndicator.isHidden = true
        timeLabel.textColor = .rippleTextSecondary
    }
}

// MARK: - Date Formatting Helper

private extension Date {
    func chatFormatted() -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(self) {
            let f = DateFormatter()
            f.dateFormat = "HH:mm"
            return f.string(from: self)
        } else if calendar.isDateInYesterday(self) {
            return "Вчера"
        } else {
            let f = DateFormatter()
            f.dateFormat = "dd.MM.yy"
            return f.string(from: self)
        }
    }
}

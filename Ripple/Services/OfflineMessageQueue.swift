import Foundation
import Network

// MARK: - Queued Message Model

struct QueuedMessage: Codable {
    let id: String
    let conversationId: String
    let text: String
    let senderId: String
    let senderName: String
    let createdAt: Date

    init(conversationId: String, text: String, senderId: String, senderName: String) {
        self.id = UUID().uuidString
        self.conversationId = conversationId
        self.text = text
        self.senderId = senderId
        self.senderName = senderName
        self.createdAt = .now
    }
}

// MARK: - OfflineMessageQueue

final class OfflineMessageQueue {

    // MARK: - Singleton

    static let shared = OfflineMessageQueue()

    /// `internal` init для тестов; в продакшне используй `.shared`
    init() {
        loadQueue()
        startMonitoring()
    }

    // MARK: - Properties

    private(set) var isConnected = false
    private var queue: [QueuedMessage] = []
    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "com.ripple.networkMonitor")
    private let userDefaultsKey = "ripple_offline_queue"

    var onConnectionRestored: (() -> Void)?
    var onConnectionLost: (() -> Void)?

    // MARK: - Monitoring

    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            let connected = path.status == .satisfied
            let wasDisconnected = !self.isConnected

            self.isConnected = connected

            DispatchQueue.main.async {
                if connected {
                    self.onConnectionRestored?()
                    if wasDisconnected {
                        self.flushQueue()
                    }
                } else {
                    self.onConnectionLost?()
                }
            }
        }
        monitor.start(queue: monitorQueue)
    }

    // MARK: - Queue Management

    func enqueue(_ message: QueuedMessage) {
        queue.append(message)
        saveQueue()
    }

    func dequeue(id: String) {
        queue.removeAll { $0.id == id }
        saveQueue()
    }

    var pendingMessages: [QueuedMessage] { queue }

    private func flushQueue() {
        guard !queue.isEmpty else { return }
        onConnectionRestored?()
    }

    // MARK: - Persistence (UserDefaults)

    private func saveQueue() {
        guard let data = try? JSONEncoder().encode(queue) else { return }
        UserDefaults.standard.set(data, forKey: userDefaultsKey)
    }

    private func loadQueue() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let saved = try? JSONDecoder().decode([QueuedMessage].self, from: data)
        else { return }
        queue = saved
    }
}

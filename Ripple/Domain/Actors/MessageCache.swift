import FirebaseFirestore

actor MessageCache {
    private var cache: [String: [Message]] = [:]
    private var lastDocuments: [String: DocumentSnapshot] = [:]

    func messages(for conversationId: String) -> [Message] {
        cache[conversationId] ?? []
    }

    func store(_ messages: [Message], for conversationId: String) {
        cache[conversationId] = messages
    }

    func append(_ message: Message, to conversationId: String) {
        cache[conversationId, default: []].append(message)
        // Дедупликация по id — убираем дубли, сохраняем порядок
        var seen = Set<String>()
        cache[conversationId] = cache[conversationId]?.filter {
            guard let id = $0.id else { return true }
            return seen.insert(id).inserted
        }
    }

    func lastDocument(for conversationId: String) -> DocumentSnapshot? {
        lastDocuments[conversationId]
    }

    func setLastDocument(_ doc: DocumentSnapshot, for conversationId: String) {
        lastDocuments[conversationId] = doc
    }
}

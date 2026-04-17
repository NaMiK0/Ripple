import UIKit

// MARK: - Protocol

protocol ImageUploadServiceProtocol {
    func uploadImage(_ image: UIImage, path: String) async throws -> String
}

// MARK: - Stub (Firebase Storage требует Blaze plan)
// Когда перейдёшь на Blaze — раскомментируй реализацию ниже и удали этот класс

final class ImageUploadService: ImageUploadServiceProtocol {
    func uploadImage(_ image: UIImage, path: String) async throws -> String {
        throw UploadError.notAvailable
    }

    enum UploadError: LocalizedError {
        case notAvailable

        var errorDescription: String? {
            "Загрузка фото недоступна на Spark плане Firebase"
        }
    }
}

// MARK: - Firebase Implementation (раскомментировать после перехода на Blaze)
/*
import FirebaseStorage

final class ImageUploadService: ImageUploadServiceProtocol {
    private let storage = Storage.storage()

    func uploadImage(_ image: UIImage, path: String) async throws -> String {
        guard let data = image.jpegData(compressionQuality: 0.75) else {
            throw UploadError.compressionFailed
        }
        let ref = storage.reference().child(path)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        _ = try await ref.putDataAsync(data, metadata: metadata)
        let url = try await ref.downloadURL()
        return url.absoluteString
    }

    enum UploadError: LocalizedError {
        case compressionFailed
        var errorDescription: String? { "Не удалось сжать изображение" }
    }
}
*/

import UIKit
import FirebaseStorage

// MARK: - Protocol

protocol ImageUploadServiceProtocol {
    func uploadImage(_ image: UIImage, path: String) async throws -> String
}

// MARK: - Firebase Implementation

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

        var errorDescription: String? {
            "Не удалось сжать изображение"
        }
    }
}

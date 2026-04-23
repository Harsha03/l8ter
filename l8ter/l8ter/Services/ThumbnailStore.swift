import Foundation

/// Downloads a thumbnail URL into the app's Documents/thumbnails directory
/// and returns the relative path to store on Item.thumbnailPath.
///
/// In Phase 4 this moves to the shared App Group container so the share
/// extension can write here too. Until then, Documents is fine.
enum ThumbnailStore {
    enum ThumbnailStoreError: Error {
        case downloadFailed(statusCode: Int)
        case writeFailed(Error)
    }

    static let directoryName = "thumbnails"

    /// Download `url` and save as `thumbnails/<itemID>.jpg`. Returns the
    /// relative path (e.g. "thumbnails/ABC.jpg") suitable for Item.thumbnailPath.
    static func download(from url: URL, itemID: UUID) async throws -> String {
        let (data, response) = try await URLSession.shared.data(from: url)
        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw ThumbnailStoreError.downloadFailed(statusCode: http.statusCode)
        }

        let dir = try thumbnailsDirectory()
        let filename = "\(itemID.uuidString).jpg"
        let fileURL = dir.appendingPathComponent(filename)

        do {
            try data.write(to: fileURL, options: .atomic)
        } catch {
            throw ThumbnailStoreError.writeFailed(error)
        }

        return "\(directoryName)/\(filename)"
    }

    /// Resolve a relative path from Item.thumbnailPath back to an absolute file URL.
    static func absoluteURL(for relativePath: String) -> URL? {
        guard let docs = try? documentsDirectory() else { return nil }
        return docs.appendingPathComponent(relativePath)
    }

    private static func documentsDirectory() throws -> URL {
        try FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        )
    }

    private static func thumbnailsDirectory() throws -> URL {
        let dir = try documentsDirectory().appendingPathComponent(directoryName)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try FileManager.default.createDirectory(
                at: dir,
                withIntermediateDirectories: true
            )
        }
        return dir
    }
}

import Foundation
import CryptoKit

nonisolated struct CrailglitunBackupManifest: Codable {
    struct Photo: Codable {
        let name: String
        let size: Int
        let sha256: String
    }

    let format: String
    let version: Int
    let createdAt: Date
    let creations: [Creation]
    let photos: [Photo]
}

nonisolated struct CrailglitunPreparedBackup {
    let url: URL
    let manifest: CrailglitunBackupManifest
}

nonisolated enum CrailglitunBackupError: LocalizedError {
    case empty
    case invalid
    case unsupportedVersion
    case tooLarge

    var errorDescription: String? {
        switch self {
        case .empty:
            return "There is no work or draft to back up yet."
        case .invalid:
            return "This backup is incomplete or damaged. Choose another TurnScene backup."
        case .unsupportedVersion:
            return "This backup uses a newer format. Update TurnScene before restoring it."
        case .tooLarge:
            return "This backup is too large to process. Keep each backup below 2 GB."
        }
    }
}

/// A document package keeps photos on disk instead of loading an entire backup into memory.
nonisolated enum CrailglitunBackupArchive {
    static let fileExtension = "turnscenebackup"
    private static let format = "TurnScene Backup"
    static let maximumPhotoSize = 64 * 1024 * 1024
    private static let maximumBackupSize = 2 * 1024 * 1024 * 1024
    static let maximumManifestSize = 20 * 1024 * 1024

    static func create(
        creations: [Creation],
        mediaRoot: URL,
        temporaryRoot: URL = FileManager.default.temporaryDirectory
    ) throws -> CrailglitunPreparedBackup {
        guard !creations.isEmpty else { throw CrailglitunBackupError.empty }
        try validate(creations)
        let url = try makePackage(in: temporaryRoot)

        do {
            let names = Set(creations.flatMap { $0.photos.compactMap { $0 } }).sorted()
            var photos: [CrailglitunBackupManifest.Photo] = []
            var totalSize = 0

            for name in names {
                let source = mediaRoot.appendingPathComponent(name)
                let size = try regularFileSize(source, limit: maximumPhotoSize)
                totalSize += size
                guard totalSize <= maximumBackupSize else { throw CrailglitunBackupError.tooLarge }
                let target = url.appendingPathComponent("Photos").appendingPathComponent(name)
                try FileManager.default.copyItem(at: source, to: target)
                photos.append(.init(name: name, size: size, sha256: try checksum(target)))
            }

            let manifest = CrailglitunBackupManifest(
                format: format,
                version: 1,
                createdAt: Date(),
                creations: creations,
                photos: photos
            )
            let data = try JSONEncoder().encode(manifest)
            guard data.count <= maximumManifestSize else { throw CrailglitunBackupError.tooLarge }
            try data.write(to: url.appendingPathComponent("manifest.json"), options: .atomic)
            return .init(url: url, manifest: manifest)
        } catch {
            remove(url)
            throw error
        }
    }

    /// Validate a private local copy before adding any records to the app database.
    static func prepareImport(
        from source: URL,
        temporaryRoot: URL = FileManager.default.temporaryDirectory
    ) throws -> CrailglitunPreparedBackup {
        try requireDirectory(source)
        let manifestURL = source.appendingPathComponent("manifest.json")
        _ = try regularFileSize(manifestURL, limit: maximumManifestSize)
        let data = try Data(contentsOf: manifestURL)
        let manifest = try decodeManifest(data)
        let photoDirectory = source.appendingPathComponent("Photos")
        try requireDirectory(photoDirectory)
        let url = try makePackage(in: temporaryRoot)

        do {
            for photo in manifest.photos {
                let file = photoDirectory.appendingPathComponent(photo.name)
                let size = try regularFileSize(file, limit: maximumPhotoSize)
                guard size == photo.size else { throw CrailglitunBackupError.invalid }
                let target = url.appendingPathComponent("Photos").appendingPathComponent(photo.name)
                try FileManager.default.copyItem(at: file, to: target)
                guard try checksum(target) == photo.sha256 else { throw CrailglitunBackupError.invalid }
            }
            try data.write(to: url.appendingPathComponent("manifest.json"), options: .atomic)
            return .init(url: url, manifest: manifest)
        } catch {
            remove(url)
            throw error
        }
    }

    /// Validate the remote manifest before its paths or sizes are used for downloads.
    static func decodeManifest(_ data: Data) throws -> CrailglitunBackupManifest {
        guard data.count <= maximumManifestSize else { throw CrailglitunBackupError.tooLarge }
        let manifest = try JSONDecoder().decode(CrailglitunBackupManifest.self, from: data)
        guard manifest.format == format else { throw CrailglitunBackupError.invalid }
        guard manifest.version == 1 else { throw CrailglitunBackupError.unsupportedVersion }
        try validate(manifest.creations)
        guard !manifest.creations.isEmpty else { throw CrailglitunBackupError.empty }

        let names = Set(manifest.creations.flatMap { $0.photos.compactMap { $0 } })
        guard Set(manifest.photos.map(\.name)) == names,
              manifest.photos.count == names.count else { throw CrailglitunBackupError.invalid }
        var total = 0
        for photo in manifest.photos {
            guard photo.size > 0, photo.size <= maximumPhotoSize,
                  photo.sha256.count == 64,
                  photo.sha256.allSatisfy({ "0123456789abcdef".contains($0) }) else {
                throw CrailglitunBackupError.invalid
            }
            total += photo.size
            guard total <= maximumBackupSize else { throw CrailglitunBackupError.tooLarge }
        }
        return manifest
    }

    /// Restoring creates independent copies, preserving relationships within the backup.
    static func copyForRestore(
        _ backup: CrailglitunPreparedBackup,
        mediaRoot: URL
    ) throws -> [Creation] {
        let fileManager = FileManager.default
        try fileManager.createDirectory(at: mediaRoot, withIntermediateDirectories: true)
        let identifiers = Dictionary(uniqueKeysWithValues: backup.manifest.creations.map { ($0.id, UUID()) })
        var photoNames: [String: String] = [:]

        do {
            for photo in backup.manifest.photos {
                let newName = UUID().uuidString + ".jpg"
                let target = mediaRoot.appendingPathComponent(newName)
                do {
                    try fileManager.copyItem(
                        at: backup.url.appendingPathComponent("Photos").appendingPathComponent(photo.name),
                        to: target
                    )
                } catch {
                    remove(target)
                    throw error
                }
                photoNames[photo.name] = newName
            }

            return backup.manifest.creations.map { original in
                var copy = original
                copy.id = identifiers[original.id]!
                copy.photos = original.photos.map { $0.flatMap { photoNames[$0] } }
                copy.editingArtworkID = original.editingArtworkID.flatMap { identifiers[$0] }
                return copy
            }
        } catch {
            photoNames.values.forEach { remove(mediaRoot.appendingPathComponent($0)) }
            throw error
        }
    }

    static func remove(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    private static func validate(_ creations: [Creation]) throws {
        guard creations.count <= 10_000,
              Set(creations.map(\.id)).count == creations.count,
              creations.allSatisfy({ creation in
                  creation.isValid && creation.photos.compactMap { $0 }.allSatisfy { name in
                      // Only app-owned JPEG names are restored; no arbitrary paths or database files.
                      name.hasSuffix(".jpg") && UUID(uuidString: String(name.dropLast(4))) != nil
                  }
              }) else { throw CrailglitunBackupError.invalid }
    }

    private static func makePackage(in root: URL) throws -> URL {
        let date = DateFormatter()
        date.locale = Locale(identifier: "en_US_POSIX")
        date.dateFormat = "yyyy-MM-dd-HHmmss"
        let name = "TurnScene-\(date.string(from: Date()))-\(UUID().uuidString.prefix(8)).\(fileExtension)"
        let url = root.appendingPathComponent(name, isDirectory: true)
        try FileManager.default.createDirectory(
            at: url.appendingPathComponent("Photos"),
            withIntermediateDirectories: true
        )
        return url
    }

    private static func requireDirectory(_ url: URL) throws {
        let values = try url.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey])
        guard values.isDirectory == true, values.isSymbolicLink != true else {
            throw CrailglitunBackupError.invalid
        }
    }

    private static func regularFileSize(_ url: URL, limit: Int) throws -> Int {
        let values = try url.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey, .fileSizeKey])
        guard values.isRegularFile == true, values.isSymbolicLink != true,
              let size = values.fileSize, size > 0 else { throw CrailglitunBackupError.invalid }
        guard size <= limit else { throw CrailglitunBackupError.tooLarge }
        return size
    }

    private static func checksum(_ url: URL) throws -> String {
        let file = try FileHandle(forReadingFrom: url)
        defer { try? file.close() }
        var hash = SHA256()
        while let data = try file.read(upToCount: 1024 * 1024), !data.isEmpty {
            hash.update(data: data)
        }
        return hash.finalize().map { String(format: "%02x", $0) }.joined()
    }
}

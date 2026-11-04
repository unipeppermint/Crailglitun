import FirebaseAuth
import FirebaseCore
import FirebaseStorage
import Foundation

nonisolated struct CrailglitunCloudBackup: Identifiable {
    let id: String
    let createdAt: Date?
    let workCount: Int
    let draftCount: Int
    let isComplete: Bool
}

@MainActor
final class CrailglitunCloudBackupService {
    private var uploadTask: StorageUploadTask?
    private var downloadTask: StorageDownloadTask?

    func cancel() {
        uploadTask?.cancel()
        downloadTask?.cancel()
    }

    func list(uid: String) async throws -> [CrailglitunCloudBackup] {
        let root = try accountRoot(uid: uid)
        let folders = try await root.listAll().prefixes
        var backups: [CrailglitunCloudBackup] = []
        for folder in folders where UUID(uuidString: folder.name) != nil {
            try checkAccount(uid)
            do {
                let metadata = try await folder.child("manifest.json").getMetadata()
                let info = metadata.customMetadata ?? [:]
                backups.append(.init(
                    id: folder.name,
                    createdAt: metadata.timeCreated,
                    workCount: Int(info["works"] ?? "") ?? 0,
                    draftCount: Int(info["drafts"] ?? "") ?? 0,
                    isComplete: true
                ))
            } catch {
                guard isMissing(error) else { throw error }
                backups.append(.init(id: folder.name, createdAt: nil, workCount: 0, draftCount: 0, isComplete: false))
            }
        }
        try checkAccount(uid)
        return backups.sorted { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) }
    }

    func upload(
        _ backup: CrailglitunPreparedBackup,
        uid: String,
        progress: @escaping (String) -> Void
    ) async throws {
        let folder = try accountRoot(uid: uid).child(UUID().uuidString)
        for (index, photo) in backup.manifest.photos.enumerated() {
            try checkAccount(uid)
            progress("Uploading photo \(index + 1) of \(backup.manifest.photos.count)…")
            try await uploadFile(
                backup.url.appendingPathComponent("Photos").appendingPathComponent(photo.name),
                to: folder.child("Photos").child(photo.name),
                contentType: "image/jpeg"
            )
        }
        try checkAccount(uid)
        progress("Finishing cloud backup…")
        let works = backup.manifest.creations.filter(\.completed).count
        // The manifest is the commit marker. Interrupted uploads never appear as restorable backups.
        try await uploadFile(
            backup.url.appendingPathComponent("manifest.json"),
            to: folder.child("manifest.json"),
            contentType: "application/json",
            metadata: ["works": String(works), "drafts": String(backup.manifest.creations.count - works)]
        )
        // Do not report cancellation after the commit has succeeded.
    }

    func download(
        id: String,
        uid: String,
        progress: @escaping (String) -> Void
    ) async throws -> CrailglitunPreparedBackup {
        let folder = try backupRoot(id: id, uid: uid)
        let data = try await folder.child("manifest.json").data(maxSize: Int64(CrailglitunBackupArchive.maximumManifestSize))
        let manifest = try CrailglitunBackupArchive.decodeManifest(data)
        let local = FileManager.default.temporaryDirectory.appendingPathComponent("CrailglitunCloud-" + UUID().uuidString)
        try FileManager.default.createDirectory(at: local.appendingPathComponent("Photos"), withIntermediateDirectories: true)
        defer { MediaStore.queue.async { CrailglitunBackupArchive.remove(local) } }
        try data.write(to: local.appendingPathComponent("manifest.json"), options: .atomic)

        for (index, photo) in manifest.photos.enumerated() {
            try checkAccount(uid)
            let remote = folder.child("Photos").child(photo.name)
            let metadata = try await remote.getMetadata()
            guard metadata.size == Int64(photo.size) else { throw CrailglitunBackupError.invalid }
            progress("Downloading photo \(index + 1) of \(manifest.photos.count)…")
            try await downloadFile(remote, to: local.appendingPathComponent("Photos").appendingPathComponent(photo.name))
        }
        try checkAccount(uid)
        progress("Checking downloaded backup…")
        return try await withCheckedThrowingContinuation { continuation in
            MediaStore.queue.async {
                continuation.resume(with: Result { try CrailglitunBackupArchive.prepareImport(from: local) })
            }
        }
    }

    func delete(id: String, uid: String) async throws {
        let root = try backupRoot(id: id, uid: uid)
        // Remove the commit marker first so a partially deleted backup cannot be restored.
        try await deleteIfPresent(root.child("manifest.json"))
        try await deleteContents(root, uid: uid)
    }

    func deleteAll(uid: String) async throws {
        try await deleteContents(accountRoot(uid: uid), uid: uid)
    }

    func checkAccount(_ uid: String) throws {
        try Task.checkCancellation()
        guard Auth.auth().currentUser?.uid == uid else { throw CrailglitunCloudError.accountChanged }
    }

    private func accountRoot(uid: String) throws -> StorageReference {
        try checkAccount(uid)
        guard let app = FirebaseApp.app(), let bucket = app.options.storageBucket, !bucket.isEmpty else {
            throw CrailglitunCloudError.configuration
        }
        let storage = Storage.storage(app: app)
        storage.maxOperationRetryTime = 20
        storage.maxUploadRetryTime = 60
        storage.maxDownloadRetryTime = 60
        return storage.reference().child("turnscene-backups").child(uid)
    }

    private func backupRoot(id: String, uid: String) throws -> StorageReference {
        guard UUID(uuidString: id) != nil else { throw CrailglitunBackupError.invalid }
        return try accountRoot(uid: uid).child(id)
    }

    private func uploadFile(
        _ url: URL,
        to reference: StorageReference,
        contentType: String,
        metadata: [String: String] = [:]
    ) async throws {
        try Task.checkCancellation()
        let info = StorageMetadata()
        info.contentType = contentType
        info.customMetadata = metadata
        defer { uploadTask = nil }
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            uploadTask = reference.putFile(from: url, metadata: info) { _, error in
                if let error { continuation.resume(throwing: error) }
                else { continuation.resume() }
            }
        }
    }

    private func downloadFile(_ reference: StorageReference, to url: URL) async throws {
        try Task.checkCancellation()
        defer { downloadTask = nil }
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            downloadTask = reference.write(toFile: url) { _, error in
                if let error { continuation.resume(throwing: error) }
                else { continuation.resume() }
            }
        }
    }

    private func deleteContents(_ root: StorageReference, uid: String) async throws {
        try checkAccount(uid)
        let contents = try await root.listAll()
        for file in contents.items {
            try checkAccount(uid)
            try await deleteIfPresent(file)
        }
        for folder in contents.prefixes {
            try await deleteContents(folder, uid: uid)
        }
    }

    private func deleteIfPresent(_ reference: StorageReference) async throws {
        do { try await reference.delete() }
        catch { if !isMissing(error) { throw error } }
    }

    private func isMissing(_ error: Error) -> Bool {
        let error = error as NSError
        return error.domain == StorageErrorDomain && error.code == StorageErrorCode.objectNotFound.rawValue
    }
}

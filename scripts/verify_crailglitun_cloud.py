#!/usr/bin/env python3
"""Exercise production cloud workflow with an in-memory Storage/Auth transport, no live accounts."""
from pathlib import Path
import subprocess
import tempfile

project = Path(__file__).resolve().parents[1]
source = project / "Crailglitun"

transport = r'''
import Foundation
let StorageErrorDomain = "StorageTest"
enum StorageErrorCode: Int { case objectNotFound = -1, cancelled = -2 }
enum CrailglitunCloudError: Error { case accountChanged, configuration }
final class User { let uid: String; init(_ uid: String) { self.uid = uid } }
final class Auth {
    static let instance = Auth()
    var currentUser: User? = User("user-a")
    static func auth() -> Auth { instance }
}
final class FirebaseOptions { var storageBucket: String? = "test-bucket" }
final class FirebaseApp {
    static let instance = FirebaseApp()
    let options = FirebaseOptions()
    static func app() -> FirebaseApp? { instance }
}
final class StorageMetadata {
    var contentType: String?
    var customMetadata: [String: String]?
    var timeCreated: Date? = Date()
    var size: Int64 = 0
}
final class StorageUploadTask { func cancel() {} }
final class StorageDownloadTask { func cancel() {} }
struct StorageListResult { let prefixes: [StorageReference]; let items: [StorageReference] }
final class Storage {
    static let instance = Storage()
    static var objects: [String: (Data, StorageMetadata)] = [:]
    static var writes: [String] = []
    static var failPhotoName: String?
    var maxOperationRetryTime: Double = 0
    var maxUploadRetryTime: Double = 0
    var maxDownloadRetryTime: Double = 0
    static func storage(app: FirebaseApp) -> Storage { instance }
    func reference() -> StorageReference { StorageReference("") }
}
final class StorageReference {
    let path: String
    init(_ path: String) { self.path = path }
    var name: String { path.split(separator: "/").last.map(String.init) ?? "" }
    func child(_ name: String) -> StorageReference { StorageReference(path.isEmpty ? name : path + "/" + name) }
    func listAll() async throws -> StorageListResult {
        let prefix = path + "/"
        let names = Storage.objects.keys.filter { $0.hasPrefix(prefix) }.map { String($0.dropFirst(prefix.count)) }
        let folders = Set(names.filter { $0.contains("/") }.map { String($0.split(separator: "/")[0]) })
        return StorageListResult(prefixes: folders.sorted().map(child), items: names.filter { !$0.contains("/") }.map(child))
    }
    func getMetadata() async throws -> StorageMetadata {
        guard let object = Storage.objects[path] else { throw NSError(domain: StorageErrorDomain, code: -1) }
        return object.1
    }
    func data(maxSize: Int64) async throws -> Data {
        guard let object = Storage.objects[path] else { throw NSError(domain: StorageErrorDomain, code: -1) }
        guard object.0.count <= maxSize else { throw CocoaError(.fileReadTooLarge) }
        return object.0
    }
    func putFile(from url: URL, metadata: StorageMetadata, completion: (StorageMetadata?, Error?) -> Void) -> StorageUploadTask {
        do {
            if name == Storage.failPhotoName { throw URLError(.networkConnectionLost) }
            let data = try Data(contentsOf: url)
            metadata.size = Int64(data.count)
            Storage.objects[path] = (data, metadata)
            Storage.writes.append(path)
            completion(metadata, nil)
        } catch { completion(nil, error) }
        return StorageUploadTask()
    }
    func write(toFile url: URL, completion: (URL?, Error?) -> Void) -> StorageDownloadTask {
        do {
            guard let object = Storage.objects[path] else { throw NSError(domain: StorageErrorDomain, code: -1) }
            try object.0.write(to: url)
            completion(url, nil)
        } catch { completion(nil, error) }
        return StorageDownloadTask()
    }
    func delete() async throws { Storage.objects.removeValue(forKey: path) }
}
nonisolated enum MediaStore {
    static let queue = DispatchQueue(label: "cloud-test-media")
}
'''

checks = r'''
import Foundation
@main struct Checks {
    @MainActor static func main() async throws {
        var passed = 0
        func check(_ value: Bool, _ title: String) {
            precondition(value, title)
            passed += 1
            print("PASS \(title)")
        }
        func rejects(_ title: String, _ action: () async throws -> Void) async {
            do { try await action(); fatalError(title) }
            catch { passed += 1; print("PASS \(title)") }
        }
        let base = URL(fileURLWithPath: CommandLine.arguments[1])
        let task = PhotoTask(id: "test", themeID: "test", title: "Test", summary: "", object: "Photo", method: "Photo + Caption", constraint: "", environments: ["Indoors"], minutes: 5, steps: ["Photo"], hints: [""])
        let first = "00000000-0000-0000-0000-000000000001.jpg"
        let second = "00000000-0000-0000-0000-000000000002.jpg"
        try Data("photo one".utf8).write(to: base.appendingPathComponent(first))
        try Data("photo two".utf8).write(to: base.appendingPathComponent(second))
        var work = Creation(task: task)
        work.completed = true
        work.photos = [first]
        var draft = Creation(task: task)
        draft.photos = [second]
        let backup = try CrailglitunBackupArchive.create(creations: [work, draft], mediaRoot: base, temporaryRoot: base)
        let service = CrailglitunCloudBackupService()
        try await service.upload(backup, uid: "user-a", progress: { _ in })
        check(Storage.writes.count == 3 && Storage.writes.last!.hasSuffix("manifest.json"), "manifest commits after all photos")
        check(Storage.writes.allSatisfy { $0.hasPrefix("turnscene-backups/user-a/") }, "uploads use account namespace")
        var list = try await service.list(uid: "user-a")
        check(list.count == 1 && list[0].isComplete && list[0].workCount == 1 && list[0].draftCount == 1, "cloud listing reads counts and completion")
        let firstID = list[0].id
        let downloaded = try await service.download(id: firstID, uid: "user-a", progress: { _ in })
        check(downloaded.manifest.creations.count == 2 && downloaded.manifest.photos.count == 2, "download verifies full archive")
        CrailglitunBackupArchive.remove(downloaded.url)
        Storage.failPhotoName = second
        await rejects("failed photo upload aborts commit") { try await service.upload(backup, uid: "user-a", progress: { _ in }) }
        list = try await service.list(uid: "user-a")
        check(list.count == 2 && list.filter(\.isComplete).count == 1, "interrupted upload is listed as incomplete")
        check(list.contains { $0.id == firstID && $0.isComplete }, "previous backup survives failed upload")
        let incompleteID = list.first { !$0.isComplete }!.id
        await rejects("incomplete upload cannot restore") { _ = try await service.download(id: incompleteID, uid: "user-a", progress: { _ in }) }
        try await service.delete(id: incompleteID, uid: "user-a")
        check(try await service.list(uid: "user-a").count == 1, "incomplete upload can be deleted")
        Storage.failPhotoName = nil
        let beforeCancel = Storage.objects.count
        let cancelled = Task { try await service.upload(backup, uid: "user-a", progress: { _ in }) }
        cancelled.cancel()
        await rejects("cancelled operation stops before writing") { try await cancelled.value }
        check(Storage.objects.count == beforeCancel, "cancel does not alter existing cloud objects")
        Auth.auth().currentUser = User("user-b")
        await rejects("changed account blocks stale restore") { _ = try await service.download(id: firstID, uid: "user-a", progress: { _ in }) }
        await rejects("changed account blocks stale deletion") { try await service.delete(id: firstID, uid: "user-a") }
        check(try await service.list(uid: "user-b").isEmpty, "other account lists its own namespace")
        try await service.upload(backup, uid: "user-b", progress: { _ in })
        let userBCount = Storage.objects.keys.filter { $0.hasPrefix("turnscene-backups/user-b/") }.count
        Auth.auth().currentUser = User("user-a")
        await rejects("path traversal backup identifier rejected") { try await service.delete(id: "../user-b", uid: "user-a") }
        let photoPath = "turnscene-backups/user-a/\(firstID)/Photos/\(first)"
        let original = Storage.objects[photoPath]!
        Storage.objects[photoPath] = (Data("photo bad".utf8), original.1)
        await rejects("same-sized corrupt cloud photo fails checksum") { _ = try await service.download(id: firstID, uid: "user-a", progress: { _ in }) }
        Storage.objects[photoPath] = original
        let manifestPath = "turnscene-backups/user-a/\(firstID)/manifest.json"
        let manifestObject = Storage.objects[manifestPath]!
        var json = try JSONSerialization.jsonObject(with: manifestObject.0) as! [String: Any]
        var creations = json["creations"] as! [[String: Any]]
        creations[0]["photos"] = ["../escape.jpg"]
        json["creations"] = creations
        Storage.objects[manifestPath] = (try JSONSerialization.data(withJSONObject: json), manifestObject.1)
        await rejects("remote manifest paths checked before download") { _ = try await service.download(id: firstID, uid: "user-a", progress: { _ in }) }
        Storage.objects[manifestPath] = manifestObject
        try await service.deleteAll(uid: "user-a")
        check(Storage.objects.keys.allSatisfy { !$0.hasPrefix("turnscene-backups/user-a/") }, "account deletion clears account objects")
        check(Storage.objects.keys.filter { $0.hasPrefix("turnscene-backups/user-b/") }.count == userBCount, "account deletion preserves other namespace")
        Auth.auth().currentUser = nil
        await rejects("signed-out request rejected") { _ = try await service.list(uid: "user-b") }
        print("\(passed) cloud workflow checks passed (mock transport; not live security rules)")
    }
}
'''

with tempfile.TemporaryDirectory(prefix="CrailglitunCloudChecks-") as directory:
    root = Path(directory)
    service = (source / "Services/CrailglitunCloudBackupService.swift").read_text()
    for module in ("FirebaseAuth", "FirebaseCore", "FirebaseStorage"):
        service = service.replace(f"import {module}\n", "")
    (root / "Transport.swift").write_text(transport)
    (root / "Cloud.swift").write_text(service)
    (root / "Checks.swift").write_text(checks)
    executable = root / "CloudChecks"
    subprocess.run([
        "xcrun", "swiftc", "-module-cache-path", str(root / "module-cache"),
        str(source / "Models/Content.swift"),
        str(source / "Services/CrailglitunBackupArchive.swift"),
        str(root / "Transport.swift"), str(root / "Cloud.swift"), str(root / "Checks.swift"),
        "-o", str(executable),
    ], check=True)
    subprocess.run([str(executable), str(root)], check=True, cwd=root)

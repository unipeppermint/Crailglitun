#!/usr/bin/env python3
"""Run production backup and Core Data code with isolated temporary storage on macOS."""
from pathlib import Path
import shutil
import subprocess
import tempfile

project = Path(__file__).resolve().parents[1]
source = project / "Crailglitun"

checks = r'''
var checks = 0
func check(_ condition: @autoclosure () -> Bool, _ name: String) {
    precondition(condition(), name)
    checks += 1
    print("PASS \(name)")
}
func rejects(_ name: String, _ operation: () throws -> Void) {
    do {
        try operation()
        fatalError("Accepted invalid input: \(name)")
    } catch {
        checks += 1
        print("PASS \(name)")
    }
}
let fm = FileManager.default
let base = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let media = base.appendingPathComponent("originals")
try fm.createDirectory(at: media, withIntermediateDirectories: true)
let task = try ContentLibrary.load().tasks.first { $0.photoCount == 1 }!
let firstPhoto = UUID().uuidString + ".jpg"
let secondPhoto = UUID().uuidString + ".jpg"
try Data("original photo A".utf8).write(to: media.appendingPathComponent(firstPhoto))
try Data("original photo B".utf8).write(to: media.appendingPathComponent(secondPhoto))
var work = Creation(task: task)
work.completed = true
work.photos = [firstPhoto]
work.caption = "Keep my caption"
work.layout = "Compact"
work.cropRegions = [CropRegion(x: 0.1, y: 0.2, width: 0.5, height: 0.6)]
var draft = work
draft.id = UUID()
draft.completed = false
draft.editingArtworkID = work.id
var other = Creation(task: task)
other.photos = [secondPhoto]
let emptyDraft = Creation(task: task)
let originals = [work, draft, other, emptyDraft]
let backup = try CrailglitunBackupArchive.create(creations: originals, mediaRoot: media, temporaryRoot: base)
check(backup.manifest.creations.count == 4, "all work and drafts included")
check(backup.manifest.photos.count == 2, "shared photos stored once")
check(backup.url.pathExtension == "turnscenebackup", "custom document extension")
let imported = try CrailglitunBackupArchive.prepareImport(from: backup.url, temporaryRoot: base)
check(imported.url != backup.url, "validation stages a private copy")
check(imported.manifest.creations[0].caption == work.caption, "caption round trip")
check(imported.manifest.creations[0].cropRegions == work.cropRegions, "crop round trip")
check(imported.manifest.creations[0].layout == "Compact", "layout round trip")
check(imported.manifest.creations[0].updatedAt == work.updatedAt, "timestamp round trip")
let restoredMedia = base.appendingPathComponent("restored")
let restored = try CrailglitunBackupArchive.copyForRestore(imported, mediaRoot: restoredMedia)
check(Set(restored.map(\.id)).isDisjoint(with: originals.map(\.id)), "new record identities")
check(restored[1].editingArtworkID == restored[0].id, "draft edit relationship remapped")
check(restored[0].photos == restored[1].photos, "shared photo relationship preserved")
check(restored[0].photos != work.photos, "photo names cannot overwrite existing files")
check(restored[3].photos == [nil], "unfinished draft with empty photo slot restored")
let restoredData = try Data(contentsOf: restoredMedia.appendingPathComponent(restored[0].photos[0]!))
check(restoredData == Data("original photo A".utf8), "photo bytes preserved")
let again = try CrailglitunBackupArchive.copyForRestore(imported, mediaRoot: restoredMedia)
check(Set(again.map(\.id)).isDisjoint(with: restored.map(\.id)), "repeated restore creates independent copies")

let db = AppStore(memory: true)
try db.save(emptyDraft)
try db.addRestoredCreations(restored)
try db.reload()
check(db.creations.count == 5, "Core Data restores all records in one batch")
check(db.creations.contains { $0.id == emptyDraft.id }, "existing records preserved")
rejects("duplicate IDs rejected without partial import") { try db.addRestoredCreations([again[0], restored[0]]) }
try db.reload()
check(db.creations.count == 5, "failed import leaves database unchanged")
var invalid = again[1]
invalid.photos = []
rejects("invalid record rejects entire batch") { try db.addRestoredCreations([again[0], invalid]) }
check(db.creations.count == 5, "validation happens before mutation")
_ = NSEntityDescription.insertNewObject(forEntityName: "Record", into: db.container.viewContext)
rejects("Core Data save failure rolls back the whole batch") { try db.addRestoredCreations(again) }
try db.reload()
check(db.creations.count == 5 && !db.container.viewContext.hasChanges, "save failure preserves committed data")
final class ChangeCounter { var value = 0 }
let counter = ChangeCounter()
let observer = NotificationCenter.default.addObserver(forName: .creationsChanged, object: nil, queue: nil) { _ in
    counter.value += 1
}
try db.addRestoredCreations(again)
check(counter.value == 1, "portfolio refresh notification sent once")
NotificationCenter.default.removeObserver(observer)

rejects("empty library rejected") {
    _ = try CrailglitunBackupArchive.create(creations: [], mediaRoot: media, temporaryRoot: base)
}
var unsafe = work
unsafe.photos = ["../TurnScene.sqlite"]
rejects("unsafe file paths rejected") {
    _ = try CrailglitunBackupArchive.create(creations: [unsafe], mediaRoot: media, temporaryRoot: base)
}
let manifestURL = backup.url.appendingPathComponent("manifest.json")
let originalManifest = try Data(contentsOf: manifestURL)
func mutateManifest(_ change: (inout [String: Any]) -> Void) throws {
    var json = try JSONSerialization.jsonObject(with: originalManifest) as! [String: Any]
    change(&json)
    try JSONSerialization.data(withJSONObject: json).write(to: manifestURL)
}
try mutateManifest { $0["version"] = 999 }
rejects("unsupported version rejected") {
    _ = try CrailglitunBackupArchive.prepareImport(from: backup.url, temporaryRoot: base)
}
try mutateManifest { json in
    var photos = json["photos"] as! [[String: Any]]
    photos.append(photos[0])
    json["photos"] = photos
}
rejects("duplicate photo inventory rejected") {
    _ = try CrailglitunBackupArchive.prepareImport(from: backup.url, temporaryRoot: base)
}
try originalManifest.write(to: manifestURL)
let photoURL = backup.url.appendingPathComponent("Photos").appendingPathComponent(firstPhoto)
try Data("original photo X".utf8).write(to: photoURL)
rejects("same-size photo corruption rejected by checksum") {
    _ = try CrailglitunBackupArchive.prepareImport(from: backup.url, temporaryRoot: base)
}
try fm.removeItem(at: photoURL)
rejects("missing photo rejected") {
    _ = try CrailglitunBackupArchive.prepareImport(from: backup.url, temporaryRoot: base)
}
try fm.createSymbolicLink(at: photoURL, withDestinationURL: media.appendingPathComponent(firstPhoto))
rejects("symbolic link rejected") {
    _ = try CrailglitunBackupArchive.prepareImport(from: backup.url, temporaryRoot: base)
}
try fm.removeItem(at: imported.url.appendingPathComponent("Photos").appendingPathComponent(secondPhoto))
let failedTarget = base.appendingPathComponent("failed-target")
rejects("interrupted photo copy fails") {
    _ = try CrailglitunBackupArchive.copyForRestore(imported, mediaRoot: failedTarget)
}
let leftovers = try fm.contentsOfDirectory(atPath: failedTarget.path)
check(leftovers.isEmpty, "partial restore photo copies cleaned up")
let packages = try fm.contentsOfDirectory(at: base, includingPropertiesForKeys: nil).filter { $0.pathExtension == "turnscenebackup" }
check(packages.count == 2, "failed imports do not leak staging packages")
CrailglitunBackupArchive.remove(backup.url)
CrailglitunBackupArchive.remove(imported.url)
check(!fm.fileExists(atPath: imported.url.path), "cancel cleanup removes prepared package")
print("\(checks) backup checks passed")
'''

with tempfile.TemporaryDirectory(prefix="CrailglitunBackupChecks-") as directory:
    root = Path(directory)
    store = (source / "Services/Store.swift").read_text()
    store = store[store.index("final class AppStore {"):store.index("nonisolated enum MediaStore {")]
    # Exercise production Core Data operations; only redirect media storage to test scratch space.
    support = '''
import Foundation
import CoreData
extension Notification.Name { static let creationsChanged = Notification.Name("creationsChanged") }
nonisolated enum MediaStore {
    static let queue = DispatchQueue(label: "backup.test.media")
    static var root: URL {
        URL(fileURLWithPath: CommandLine.arguments[1]).appendingPathComponent("isolated-app-data")
    }
}
'''
    (root / "Store.swift").write_text(support + store)
    (root / "main.swift").write_text("import Foundation\nimport CoreData\n" + checks)
    shutil.copy(source / "Resources/tasks.json", root / "tasks.json")
    executable = root / "BackupChecks"
    subprocess.run([
        "xcrun", "swiftc", "-module-cache-path", str(root / "module-cache"),
        str(source / "Models/Content.swift"),
        str(source / "Models/CrailglitunEnglishMigration.swift"),
        str(source / "Services/CrailglitunBackupArchive.swift"),
        str(root / "Store.swift"), str(root / "main.swift"), "-o", str(executable),
    ], check=True)
    subprocess.run([str(executable), str(root)], check=True, cwd=root)

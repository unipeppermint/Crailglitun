#if DEBUG
import UIKit
import CoreData
import ImageIO

enum SelfTests {
    static func run() {
        var results: [String] = []
        func check(_ condition: Bool,_ name: String) { results.append("\(condition ? "PASS" : "FAIL") \(name)") }
        do {
            let library = try ContentLibrary.load(); let engine = TaskEngine(tasks: library.tasks)
            check(library.tasks.count == 60 && library.themes.count == 6,"60 tasks / 6 themes load and validate")
            let contentText = String(decoding: try JSONEncoder().encode(library), as: UTF8.self)
            check(!contentText.unicodeScalars.contains { (0x3400...0x9FFF).contains($0.value) }, "bundled content is English only")
            check(Set(Bundle.main.localizations).subtracting(["Base"]) == ["en"] && Bundle.main.object(forInfoDictionaryKey: "CFBundleLocalizations") as? [String] == ["en"] && Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String == "TurnScene", "English-only app metadata")
            let legacyMethods = ["\u{4E09}\u{683C}\u{6545}\u{4E8B}", "\u{5355}\u{56FE}\u{914D}\u{6587}", "\u{53CC}\u{56FE}\u{5BF9}\u{7167}"]
            for (index, task) in library.tasks.prefix(3).enumerated() {
                var original = Creation(task: task)
                original.photos[0] = "legacy-reference.jpg"
                original.caption = "\u{6211}\u{7684}\u{7167}\u{7247}"
                original.completed = index == 1
                original.cropRegions = Array(repeating: nil, count: task.photoCount)
                original.cropRegions?[0] = CropRegion(x: 0.1,y: 0.1,width: 0.5,height: 0.5)
                var payload = try JSONSerialization.jsonObject(with: JSONEncoder().encode(original)) as! [String: Any]
                var legacyTask = payload["task"] as! [String: Any]
                legacyTask["method"] = legacyMethods[index]
                legacyTask["title"] = "\u{65E7}\u{6807}\u{9898}"
                payload["task"] = legacyTask
                payload["layout"] = index == 1 ? "\u{7D27}\u{51D1}" : "\u{7559}\u{767D}"
                let migrationStore = AppStore(memory: true)
                let record = NSEntityDescription.insertNewObject(forEntityName: "Record", into: migrationStore.container.viewContext)
                record.setValue(original.id, forKey: "id")
                record.setValue(try JSONSerialization.data(withJSONObject: payload), forKey: "payload")
                record.setValue(original.updatedAt, forKey: "updatedAt")
                record.setValue(original.completed, forKey: "completed")
                try migrationStore.container.viewContext.save()
                try migrationStore.reload()
                let migrated = migrationStore.creations[0]
                check(migrated.isValid && migrated.task == task && migrated.layout == (index == 1 ? "Compact" : "Spacious"), "legacy task and layout migrate: \(task.id)")
                check(migrated.id == original.id && migrated.photos == original.photos && migrated.cropRegions == original.cropRegions && migrated.caption == original.caption && migrated.completed == original.completed && migrated.updatedAt == original.updatedAt, "migration preserves user content: \(task.id)")
                try migrationStore.save(migrated)
                try migrationStore.reload()
                check(migrationStore.creations[0].task == task, "migrated record saves and reloads: \(task.id)")
            }
            check(library.themes.allSatisfy { UIImage(named: $0.image) != nil },"Every theme asset exists")
            let reelValues = Set(library.tasks.flatMap { $0.values })
            let artworkData = reelValues.compactMap { reelImage($0).pngData() }
            check(artworkData.count == reelValues.count && Set(artworkData).count == reelValues.count, "all reel choices render distinct artwork")
            check(Set(library.tasks.map(\.title)).count == library.tasks.count, "task titles are individually named")
            check(!CropRegion(x: 0.8,y: 0,width: 0.5,height: 1).isValid && !CropRegion(x: .nan,y: 0,width: 1,height: 1).isValid, "invalid crop regions rejected before rendering")
            for task in library.tasks {
                for mask in 0..<8 {
                    let locks = Set((0..<3).filter { mask & (1 << $0) != 0 })
                    let candidates = engine.candidates(environment: task.environments[0],minutes: task.minutes,values: task.values,locked: locks)
                    check(candidates.contains(task) && candidates.allSatisfy { item in locks.allSatisfy { item.values[$0] == task.values[$0] } },"locks \(task.id) mask \(mask)")
                }
            }
            let task = library.tasks[0]
            let indoors = engine.candidates(environment: "Indoors",minutes: 5,values: task.values,locked: [])
            check(!indoors.isEmpty && indoors.allSatisfy { $0.minutes <= 5 && $0.environments.contains("Indoors") },"environment and duration filters")
            check(engine.candidates(environment: "Outdoors",minutes: 5,values: task.values,locked: [0,1,2]).isEmpty,"incompatible fully locked combination returns no result")
            check(engine.pick(from: [],recent: [],draw: { _ in 0 }) == nil,"empty candidate set is safe")
            var weightedTotal = 0
            _ = engine.pick(from: Array(library.tasks.prefix(2)),recent: [task.id],draw: { count in weightedTotal = count; return 0 })
            check(weightedTotal == 6,"recent task receives 1/5 weight")
            let store = AppStore(memory: true)
            var draft = Creation(task: task); draft.caption = "Recovery test"; draft.photos[0] = "shared-test-photo.jpg"
            try store.save(draft); try store.reload()
            check(store.drafts.first?.caption == "Recovery test" && store.drafts.first?.task == task,"Core Data draft and immutable task snapshot round trip")
            var another = draft; another.id = UUID(); try store.save(another)
            try store.delete(draft)
            check(store.drafts.count == 1 && store.drafts[0].photos[0] == "shared-test-photo.jpg","deleting one record preserves another shared reference")
            var invalid = another; invalid.caption = "must roll back"; invalid.cropRegions = [CropRegion(x: .nan,y: 0,width: 1,height: 1),nil,nil]
            do { try store.save(invalid); check(false,"invalid metadata must fail") } catch { try store.reload(); check(store.drafts.first?.caption == another.caption,"failed metadata write rolls back to previous draft") }
            let repeatDraft = Creation(task: task)
            check(repeatDraft.id != another.id && repeatDraft.task == another.task && repeatDraft.photos.allSatisfy { $0 == nil },"same-task recreation creates independent empty draft")
            var artwork = another; artwork.completed = true; artwork.id = UUID()
            try store.save(artwork,removing: another.id)
            check(store.drafts.isEmpty && store.artworks.count == 1,"finalizing an edit removes only its draft atomically")
            let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            try FileManager.default.createDirectory(at: folder,withIntermediateDirectories: true)
            let diskURL = folder.appendingPathComponent("test.sqlite")
            let first = AppStore(storeURL: diskURL)
            try first.save(another)
            let second = AppStore(storeURL: diskURL)
            check(second.drafts.first?.caption == another.caption && second.drafts.first?.photos == another.photos,"draft recovers from a fresh persistent container")
            for container in [first.container,second.container] { for store in container.persistentStoreCoordinator.persistentStores { try container.persistentStoreCoordinator.remove(store) } }
            try FileManager.default.removeItem(at: folder)
            var malformed = artwork; malformed.photos = []
            do { try store.save(malformed); check(false,"malformed photo count rejected") } catch { check(store.artworks.count == 1,"malformed photo count preserves existing artwork") }
            var unsafeName = artwork; unsafeName.photos[0] = "../another.jpg"
            do { try store.save(unsafeName); check(false,"invalid media path rejected") } catch { check(store.artworks.count == 1,"invalid media path preserves existing artwork") }
            let decoded = try JSONDecoder().decode(Creation.self,from: JSONEncoder().encode(artwork))
            check(decoded.task == artwork.task && decoded.photos == artwork.photos,"artwork snapshot serialization")
            check(!FileManager.default.fileExists(atPath: MediaStore.root.appendingPathComponent("not-a-photo.jpg").path) && MediaStore.image("not-a-photo.jpg") == nil,"missing media fails gracefully")
        } catch { results.append("FAIL \(error)") }
        let text = results.joined(separator: "\n") + "\n\(results.filter { $0.hasPrefix("PASS") }.count) passed; \(results.filter { $0.hasPrefix("FAIL") }.count) failed\n"
        let url = MediaStore.root.appendingPathComponent("self-tests.txt")
        try? text.write(to: url,atomically: true,encoding: .utf8)
        print(text)
        if let image = UIImage(named: "theme-old"),let task = AppStore.shared.library.tasks.first { mediaTests(image: image,task: task,url: url) }
    }
    static func mediaTests(image: UIImage,task: PhotoTask,url: URL) {
        MediaStore.importImage(image) { result in
            var lines: [String] = []
            do {
                let name = try result.get()
                defer { try? FileManager.default.removeItem(at: MediaStore.root.appendingPathComponent(name)) }
                guard let normalized = MediaStore.image(name,maxSize: 2800) else { throw CocoaError(.fileReadCorruptFile) }
                lines.append("PASS imported photo has independent readable local copy")
                let crop = MediaStore.cropped(normalized,region: CropRegion(x: 0.25,y: 0.1,width: 0.4,height: 0.4))
                lines.append(crop.size.width < normalized.size.width ? "PASS normalized crop preserves source and changes dimensions" : "FAIL crop dimensions")
                var item = Creation(task: task); item.photos = Array(repeating: name,count: task.photoCount); item.caption = "QA validation · Test image"
                let exported = try MediaStore.export(item)
                defer { try? FileManager.default.removeItem(at: exported) }
                let data = try Data(contentsOf: exported)
                let rendered = UIImage(data: data)
                lines.append(rendered?.size.width == 1600 ? "PASS three-panel JPG export has 1600 pixel width" : "FAIL export dimensions")
                let imported = try MediaStore.importPreview(at: exported)
                lines.append(max(imported.size.width,imported.size.height) <= 2800 ? "PASS file import bounds decoded dimensions" : "FAIL file import dimensions")
                let concurrent = try MediaStore.export(item)
                lines.append(concurrent != exported && FileManager.default.fileExists(atPath: exported.path) ? "PASS repeated exports use independent files" : "FAIL shared export file")
                try? FileManager.default.removeItem(at: concurrent)
                let source = CGImageSourceCreateWithData(data as CFData,nil)!
                let props = CGImageSourceCopyPropertiesAtIndex(source,0,nil) as? [CFString:Any]
                lines.append(props?[kCGImagePropertyGPSDictionary] == nil ? "PASS export omits GPS metadata" : "FAIL export GPS")
                item.photos[0] = "missing-qa.jpg"
                do { _ = try MediaStore.export(item); lines.append("FAIL missing media should reject export") } catch { lines.append("PASS missing media produces export error") }
                let copy = MediaStore.root.appendingPathComponent("qa-export.jpg")
                try data.write(to: copy,options: .atomic)
            } catch { lines.append("FAIL media pipeline: \(error)") }
            DispatchQueue.main.async {
                let previous = (try? String(contentsOf: url)) ?? ""
                try? (previous + lines.joined(separator: "\n") + "\n").write(to: url,atomically: true,encoding: .utf8)
                print(lines.joined(separator: "\n"))
            }
        }
    }

}
#endif

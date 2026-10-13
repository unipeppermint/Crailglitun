import UIKit
import CoreData
import ImageIO
import AVFoundation

extension Notification.Name { static let creationsChanged = Notification.Name("creationsChanged") }

final class AppStore {
    static let shared = AppStore()
    let library: ContentLibrary
    let container: NSPersistentContainer
    var startupError: Error?
    private(set) var creations: [Creation] = []
    var drafts: [Creation] { creations.filter { !$0.completed } }
    var artworks: [Creation] { creations.filter(\.completed) }
    init(memory: Bool = false, storeURL: URL? = nil) {
        do { library = try ContentLibrary.load() }
        catch { library = ContentLibrary(schemaVersion: 1, contentVersion: 1, themes: [], tasks: []); startupError = error }
        let model = NSManagedObjectModel()
        let entity = NSEntityDescription(); entity.name = "Record"; entity.managedObjectClassName = "NSManagedObject"
        func attribute(_ name: String, _ type: NSAttributeType) -> NSAttributeDescription {
            let a = NSAttributeDescription(); a.name = name; a.attributeType = type; a.isOptional = false; return a
        }
        entity.properties = [attribute("id", .UUIDAttributeType), attribute("payload", .binaryDataAttributeType), attribute("updatedAt", .dateAttributeType), attribute("completed", .booleanAttributeType)]
        entity.uniquenessConstraints = [["id"]]; model.entities = [entity]
        container = NSPersistentContainer(name: "TurnScene", managedObjectModel: model)
        let description = NSPersistentStoreDescription()
        do {
            try FileManager.default.createDirectory(at: MediaStore.root, withIntermediateDirectories: true)
            description.url = storeURL ?? (memory ? URL(fileURLWithPath: "/dev/null") : MediaStore.root.appendingPathComponent("TurnScene.sqlite"))
        } catch { startupError = error }
        description.shouldAddStoreAsynchronously = false
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { [weak self] _, error in if let error = error { self?.startupError = error } }
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        do {
            try reload()
            if !memory && storeURL == nil && startupError == nil {
                let used = Set(creations.flatMap { $0.photos.compactMap { $0 } })
                MediaStore.queue.async {
                    let files = (try? FileManager.default.contentsOfDirectory(at: MediaStore.root,includingPropertiesForKeys: nil)) ?? []
                    for file in files where file.pathExtension == "jpg" && !used.contains(file.lastPathComponent) { try? FileManager.default.removeItem(at: file) }
                }
            }
        } catch { startupError = error }
    }
    func reload() throws {
        let request = NSFetchRequest<NSManagedObject>(entityName: "Record")
        request.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
        creations = try container.viewContext.fetch(request).map {
            guard let data = $0.value(forKey: "payload") as? Data else { throw CocoaError(.fileReadCorruptFile) }
            let item = try JSONDecoder().decode(Creation.self, from: data)
            guard item.isValid else { throw CocoaError(.fileReadCorruptFile) }
            return item
        }
    }
    func save(_ creation: Creation, removing draftID: UUID? = nil) throws {
        if let error = startupError { throw error }
        guard creation.isValid else { throw CocoaError(.fileWriteInvalidFileName) }
        let usedBefore = Set(creations.flatMap { $0.photos.compactMap { $0 } })
        let context = container.viewContext
        let request = NSFetchRequest<NSManagedObject>(entityName: "Record")
        request.predicate = NSPredicate(format: "id == %@", creation.id as CVarArg)
        do {
            let record = try context.fetch(request).first ?? NSEntityDescription.insertNewObject(forEntityName: "Record", into: context)
            record.setValue(creation.id, forKey: "id"); record.setValue(try JSONEncoder().encode(creation), forKey: "payload")
            record.setValue(creation.updatedAt, forKey: "updatedAt"); record.setValue(creation.completed, forKey: "completed")
            if let draftID = draftID {
                let old = NSFetchRequest<NSManagedObject>(entityName: "Record"); old.predicate = NSPredicate(format: "id == %@", draftID as CVarArg)
                for record in try context.fetch(old) { context.delete(record) }
            }
            try context.save(); try reload()
            let usedAfter = Set(creations.flatMap { $0.photos.compactMap { $0 } })
            let unused = usedBefore.subtracting(usedAfter)
            MediaStore.queue.async { unused.forEach { try? FileManager.default.removeItem(at: MediaStore.root.appendingPathComponent($0)) } }
            NotificationCenter.default.post(name: .creationsChanged, object: nil)
        } catch { context.rollback(); throw error }
    }
    func delete(_ creation: Creation) throws {
        let request = NSFetchRequest<NSManagedObject>(entityName: "Record")
        request.predicate = NSPredicate(format: "id == %@", creation.id as CVarArg)
        do { for record in try container.viewContext.fetch(request) { container.viewContext.delete(record) }; try container.viewContext.save(); try reload() }
        catch { container.viewContext.rollback(); throw error }
        let used = Set(creations.flatMap { $0.photos.compactMap { $0 } })
        let unused = creation.photos.compactMap { $0 }.filter { !used.contains($0) }
        MediaStore.queue.async { unused.forEach { try? FileManager.default.removeItem(at: MediaStore.root.appendingPathComponent($0)) } }
        NotificationCenter.default.post(name: .creationsChanged, object: nil)
    }
    func theme(_ task: PhotoTask) -> Theme? { library.themes.first { $0.id == task.themeID } }
}

nonisolated enum MediaStore {
    static let queue = DispatchQueue(label: "app.turnscene.media", qos: .userInitiated)
    static var root: URL { FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("TurnScene", isDirectory: true) }
    static var cache: URL { FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("TurnScene", isDirectory: true) }
    static func importPreview(at url: URL) throws -> UIImage {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, [kCGImageSourceShouldCache: false] as CFDictionary),
              let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [kCGImageSourceCreateThumbnailFromImageAlways: true, kCGImageSourceThumbnailMaxPixelSize: 2800, kCGImageSourceCreateThumbnailWithTransform: true, kCGImageSourceShouldCacheImmediately: true] as CFDictionary) else { throw CocoaError(.fileReadCorruptFile) }
        return UIImage(cgImage: image)
    }
    static func importImage(_ image: UIImage, completion: @escaping @Sendable (Result<String, Error>) -> Void) {
        queue.async {
            do {
                let size = image.size
                guard size.width > 0, size.height > 0 else { throw CocoaError(.fileReadCorruptFile) }
                let ratio = min(1, 2800 / max(size.width, size.height))
                let format = UIGraphicsImageRendererFormat(); format.scale = 1
                let normalized = UIGraphicsImageRenderer(size: CGSize(width: size.width * ratio, height: size.height * ratio), format: format).image { _ in image.draw(in: CGRect(x: 0, y: 0, width: size.width * ratio, height: size.height * ratio)) }
                guard let data = normalized.jpegData(compressionQuality: 0.92) else { throw CocoaError(.fileWriteUnknown) }
                try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
                let name = UUID().uuidString + ".jpg"
                try data.write(to: root.appendingPathComponent(name), options: .atomic)
                completion(.success(name))
            } catch { completion(.failure(error)) }
        }
    }
    static func image(_ name: String, maxSize: Int = 1200) -> UIImage? {
        guard FileManager.default.fileExists(atPath: root.appendingPathComponent(name).path) else { return nil }
        let cached = cache.appendingPathComponent("\(maxSize)-" + name)
        if maxSize <= 1200,let thumbnail = UIImage(contentsOfFile: cached.path) { return thumbnail }
        guard let source = CGImageSourceCreateWithURL(root.appendingPathComponent(name) as CFURL, nil),
              let cg = CGImageSourceCreateThumbnailAtIndex(source, 0, [kCGImageSourceCreateThumbnailFromImageAlways: true, kCGImageSourceThumbnailMaxPixelSize: maxSize, kCGImageSourceCreateThumbnailWithTransform: true] as CFDictionary) else { return nil }
        let thumbnail = UIImage(cgImage: cg)
        if maxSize <= 1200 { try? FileManager.default.createDirectory(at: cache,withIntermediateDirectories: true); if let data = thumbnail.jpegData(compressionQuality: 0.82) { try? data.write(to: cached,options: .atomic) } }
        return thumbnail
    }
    static func usage(_ url: URL) -> Int64 {
        guard let files = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) else { return 0 }
        return files.compactMap { $0 as? URL }.reduce(0) { $0 + Int64((try? $1.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0) }
    }
    static func export(_ item: Creation) throws -> URL {
        let width: CGFloat = 1600, padding: CGFloat = item.layout == "留白" ? 72 : 24
        let imageHeight: CGFloat = item.photos.count == 1 ? 1456 : 900
        let canvas = CGSize(width: width, height: imageHeight + 360)
        let format = UIGraphicsImageRendererFormat(); format.scale = 1
        let images = try item.photos.enumerated().map { i, name -> UIImage in
            guard let name = name, let image = image(name, maxSize: 2800) else { throw CocoaError(.fileReadNoSuchFile) }
            if let region = item.cropRegions?[i] { return cropped(image,region: region) }
            return item.crops[i] ? square(image) : image
        }
        let output = UIGraphicsImageRenderer(size: canvas, format: format).image { context in
            UIColor(red: 0.965, green: 0.953, blue: 0.922, alpha: 1).setFill(); context.fill(CGRect(origin: .zero, size: canvas))
            let gap: CGFloat = 18
            let cellWidth = (width - 2 * padding - gap * CGFloat(images.count - 1)) / CGFloat(images.count)
            for (i, image) in images.enumerated() {
                let rect = CGRect(x: padding + CGFloat(i) * (cellWidth + gap), y: padding, width: cellWidth, height: imageHeight - padding)
                context.cgContext.saveGState(); context.cgContext.clip(to: rect)
                let factor = max(rect.width / image.size.width, rect.height / image.size.height)
                let size = CGSize(width: image.size.width * factor, height: image.size.height * factor)
                image.draw(in: CGRect(x: rect.midX - size.width / 2, y: rect.midY - size.height / 2, width: size.width, height: size.height)); context.cgContext.restoreGState()
            }
            let textColor = UIColor(red: 0.15, green: 0.18, blue: 0.17, alpha: 1)
            (item.task.title as NSString).draw(in: CGRect(x: 72, y: imageHeight + 40, width: 1456, height: 72), withAttributes: [.font: UIFont.systemFont(ofSize: 44, weight: .semibold), .foregroundColor: textColor])
            (item.caption as NSString).draw(in: CGRect(x: 72, y: imageHeight + 120, width: 1456, height: 130), withAttributes: [.font: UIFont.systemFont(ofSize: 32), .foregroundColor: textColor])
            ("转场  /  \(item.task.values.joined(separator: " · "))" as NSString).draw(at: CGPoint(x: 72, y: canvas.height - 60), withAttributes: [.font: UIFont.systemFont(ofSize: 22), .foregroundColor: UIColor.gray])
        }
        guard let data = output.jpegData(compressionQuality: 0.94) else { throw CocoaError(.fileWriteUnknown) }
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("TurnSceneExports", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let title = String(item.task.title.filter { !$0.isNewline && !"/\\:".contains($0) }.prefix(36))
        let filename = "转场-" + (title.isEmpty ? "作品" : title) + "-" + String(UUID().uuidString.prefix(8)) + ".jpg"
        let url = folder.appendingPathComponent(filename); try data.write(to: url, options: .atomic); return url
    }
    static func cropped(_ image: UIImage,region: CropRegion) -> UIImage {
        guard region.isValid, let cg = image.cgImage else { return image }
        let rect = CGRect(x: region.x * Double(cg.width),y: region.y * Double(cg.height),width: region.width * Double(cg.width),height: region.height * Double(cg.height)).intersection(CGRect(x: 0,y: 0,width: cg.width,height: cg.height))
        guard !rect.isEmpty, let result = cg.cropping(to: rect) else { return image }
        return UIImage(cgImage: result)
    }
    static func square(_ image: UIImage) -> UIImage {
        let side = min(image.size.width, image.size.height)
        let format = UIGraphicsImageRendererFormat(); format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: format).image { _ in image.draw(at: CGPoint(x: (side-image.size.width)/2, y: (side-image.size.height)/2)) }
    }
}

final class Preferences {
    static let shared = Preferences()
    var haptics: Bool { get { UserDefaults.standard.object(forKey: "haptics") as? Bool ?? true } set { UserDefaults.standard.set(newValue, forKey: "haptics") } }
    var sound: Bool { get { UserDefaults.standard.bool(forKey: "sound") } set { UserDefaults.standard.set(newValue, forKey: "sound") } }
    var reduce: Bool { get { UserDefaults.standard.bool(forKey: "reduce") } set { UserDefaults.standard.set(newValue, forKey: "reduce") } }
    var reduceMotion: Bool { reduce || UIAccessibility.isReduceMotionEnabled }
    private var player: AVAudioPlayer?
    func tick() {
        if haptics { UISelectionFeedbackGenerator().selectionChanged() }
        if sound, let url = Bundle.main.url(forResource: "tick", withExtension: "wav") {
            try? AVAudioSession.sharedInstance().setCategory(.ambient)
            player = try? AVAudioPlayer(contentsOf: url); player?.play()
        }
    }
}

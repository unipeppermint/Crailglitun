import Foundation

nonisolated struct Theme: Codable, Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let image: String
    let environment: String
}
nonisolated struct PhotoTask: Codable, Identifiable, Equatable {
    let id: String
    let themeID: String
    let title: String
    let summary: String
    let object: String
    let method: String
    let constraint: String
    let environments: [String]
    let minutes: Int
    let steps: [String]
    let hints: [String]
    var values: [String] { [object, method, constraint] }
    var photoCount: Int { steps.count }
}
nonisolated struct ContentLibrary: Codable {
    let schemaVersion: Int
    let contentVersion: Int
    let themes: [Theme]
    let tasks: [PhotoTask]
    static func load() throws -> Self {
        guard let url = Bundle.main.url(forResource: "tasks", withExtension: "json") else { throw CocoaError(.fileNoSuchFile) }
        let library = try JSONDecoder().decode(Self.self, from: Data(contentsOf: url))
        guard library.schemaVersion == 1,
              Set(library.themes.map(\.id)).count == library.themes.count,
              Set(library.tasks.map(\.id)).count == library.tasks.count,
              library.tasks.allSatisfy({ task in
                  library.themes.contains(where: { $0.id == task.themeID }) && ["单图配文": 1,"双图对照": 2,"三格故事": 3][task.method] == task.photoCount && task.steps.count == task.hints.count && !task.title.isEmpty && !task.environments.isEmpty && task.environments.allSatisfy { ["室内","户外"].contains($0) } && [5,10,20].contains(task.minutes)
              }) else { throw CocoaError(.fileReadCorruptFile) }
        return library
    }
}
nonisolated struct Creation: Codable, Identifiable {
    var id = UUID()
    let task: PhotoTask
    var photos: [String?]
    var cropRegions: [CropRegion?]?
    var crops: [Bool]
    var caption = ""
    var layout = "留白"
    var updatedAt = Date()
    var completed = false
    var editingArtworkID: UUID?
    var isValid: Bool {
        let expected = ["单图配文": 1, "双图对照": 2, "三格故事": 3][task.method]
        return expected == task.photoCount && task.hints.count == task.photoCount && photos.count == task.photoCount && crops.count == photos.count &&
            (cropRegions == nil || (cropRegions?.count == photos.count && cropRegions?.compactMap { $0 }.allSatisfy { $0.isValid } == true)) &&
            photos.compactMap { $0 }.allSatisfy { !$0.isEmpty && !$0.contains("/") && !$0.contains("\\") && $0 != "." && $0 != ".." }
    }
    init(task: PhotoTask) {
        self.task = task
        photos = Array(repeating: nil, count: task.photoCount)
        crops = Array(repeating: false, count: task.photoCount)
    }
}
nonisolated struct TaskEngine {
    let tasks: [PhotoTask]
    func candidates(environment: String, minutes: Int, values: [String], locked: Set<Int>, theme: String? = nil) -> [PhotoTask] {
        tasks.filter { t in
            t.environments.contains(environment) && t.minutes <= minutes && (theme == nil || t.themeID == theme) && locked.allSatisfy { t.values[$0] == values[$0] }
        }
    }
    func pick(from candidates: [PhotoTask], recent: [String], draw: (Int) -> Int = { Int.random(in: 0..<$0) }) -> PhotoTask? {
        guard !candidates.isEmpty else { return nil }
        let weighted = candidates.flatMap { t in Array(repeating: t, count: recent.contains(t.id) ? 1 : 5) }
        return weighted[draw(weighted.count) % weighted.count]
    }
}

nonisolated struct CropRegion: Codable, Equatable {
    let x: Double
    let y: Double
    let width: Double
    let height: Double
    var isValid: Bool { [x,y,width,height].allSatisfy { $0.isFinite } && x >= 0 && y >= 0 && width > 0 && height > 0 && x + width <= 1.000001 && y + height <= 1.000001 }
}

import Foundation

extension Creation {
    /// Translate bundled task snapshots from earlier versions without changing user content.
    nonisolated func usingEnglishContent(from library: ContentLibrary) throws -> Creation {
        var result = self
        let legacyMethods = ["\u{5355}\u{56FE}\u{914D}\u{6587}": 1,
                             "\u{53CC}\u{56FE}\u{5BF9}\u{7167}": 2,
                             "\u{4E09}\u{683C}\u{6545}\u{4E8B}": 3]
        if let expected = legacyMethods[task.method] {
            guard let translated = library.tasks.first(where: { $0.id == task.id }),
                  translated.photoCount == expected, task.photoCount == expected,
                  task.hints.count == expected else { throw CocoaError(.fileReadCorruptFile) }
            result.task = translated
        }
        if layout == "\u{7559}\u{767D}" { result.layout = "Spacious" }
        if layout == "\u{7D27}\u{51D1}" { result.layout = "Compact" }
        return result
    }
}

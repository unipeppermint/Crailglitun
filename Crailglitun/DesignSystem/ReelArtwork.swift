import UIKit

/// Shared, square artwork keeps the reel and compact condition chips consistent.
/// Compositions use real theme photos; each method has its own visible photo count.
enum ReelArtwork {
    private static let canvas = CGSize(width: 96, height: 96)
    private static var cache: [String: UIImage] = [:]

    static func image(for value: String) -> UIImage {
        if let image = cache[value] { return image }
        let image = UIGraphicsImageRenderer(size: canvas).image { context in
            switch value {
            case "Photo + Caption": singlePhoto(in: context.cgContext)
            case "Photo Pair": comparison(in: context.cgContext)
            case "Three Frames": film(in: context.cgContext)
            case "Keepsake":
                fit(UIImage(named: "reel-old-radio"), in: CGRect(x: 3, y: 3, width: 90, height: 90))
            case "Cup":
                fit(UIImage(named: "reel-cup"), in: CGRect(x: 4, y: 7, width: 88, height: 82))
            case "Window":
                paper(CGRect(x: 15, y: 9, width: 66, height: 78), context: context.cgContext)
                photo("theme-window", in: CGRect(x: 20, y: 14, width: 56, height: 68), context: context.cgContext)
            case "One Spot":
                drawSymbol("viewfinder", in: CGRect(x: 14, y: 12, width: 68, height: 72))
                drawSymbol("mappin.and.ellipse", in: CGRect(x: 34, y: 29, width: 28, height: 38), color: Palette.orange)
            case "Color":
                for (i,color) in [UIColor(hex: 0xCE9866), Palette.teal, Palette.orange].enumerated() {
                    color.setFill()
                    UIBezierPath(roundedRect: CGRect(x: 13 + i * 24, y: 26, width: 22, height: 44), cornerRadius: 6).fill()
                }
            case "One Color":
                drawSymbol("drop.fill", in: CGRect(x: 28, y: 17, width: 40, height: 62), color: Palette.orange)
            case "Doorway":
                fit(UIImage(named: "reel-window"), in: CGRect(x: 10, y: 5, width: 76, height: 86))
            default:
                drawSymbol(symbolName(for: value), in: CGRect(x: 20, y: 20, width: 56, height: 56))
            }
        }
        cache[value] = image
        return image
    }

    private static func drawSymbol(_ name: String, in rect: CGRect, color: UIColor = UIColor(hex: 0x7F8C80)) {
        let configuration = UIImage.SymbolConfiguration(pointSize: 46, weight: .light)
        let image = UIImage(systemName: name, withConfiguration: configuration)?.withTintColor(color, renderingMode: .alwaysOriginal)
        fit(image, in: rect)
    }

    private static func paper(_ rect: CGRect, context: CGContext) {
        context.saveGState()
        context.setShadow(offset: CGSize(width: 0, height: 2), blur: 3, color: UIColor.black.withAlphaComponent(0.16).cgColor)
        UIColor(hex: 0xFFFCF4).setFill()
        UIBezierPath(roundedRect: rect, cornerRadius: 2).fill()
        context.restoreGState()
        UIColor(hex: 0xCFC6B5).setStroke()
        let border = UIBezierPath(roundedRect: rect, cornerRadius: 2); border.lineWidth = 0.7; border.stroke()
    }

    private static func singlePhoto(in context: CGContext) {
        context.saveGState(); context.translateBy(x: 48, y: 48); context.rotate(by: -0.08)
        paper(CGRect(x: -34, y: -39, width: 68, height: 78), context: context)
        photo("theme-old", in: CGRect(x: -29, y: -34, width: 58, height: 50), context: context)
        UIColor(hex: 0x88877B).setFill()
        UIBezierPath(roundedRect: CGRect(x: -24, y: 23, width: 43, height: 2), cornerRadius: 1).fill()
        UIBezierPath(roundedRect: CGRect(x: -24, y: 29, width: 29, height: 2), cornerRadius: 1).fill()
        context.restoreGState()
    }

    private static func comparison(in context: CGContext) {
        // Separate, equally prominent frames read as a pair even at thumbnail size.
        for (x, name) in [(CGFloat(4), "theme-window"), (CGFloat(50), "theme-old")] {
            paper(CGRect(x: x, y: 19, width: 42, height: 59), context: context)
            photo(name, in: CGRect(x: x + 3, y: 22, width: 36, height: 47), context: context)
        }
    }

    private static func film(in context: CGContext) {
        context.saveGState(); context.translateBy(x: 48, y: 48); context.rotate(by: 0.14)
        UIColor(hex: 0x292B29).setFill()
        UIBezierPath(roundedRect: CGRect(x: -23, y: -43, width: 46, height: 86), cornerRadius: 2).fill()
        UIColor(hex: 0xEAE5D9).setFill()
        for y in stride(from: -39, through: 37, by: 8) {
            for x in [-20, 17] { UIBezierPath(roundedRect: CGRect(x: x, y: y, width: 3, height: 4), cornerRadius: 0.6).fill() }
        }
        for (i, name) in ["theme-old", "theme-window", "theme-shadow"].enumerated() {
            photo(name, in: CGRect(x: -14, y: -38 + i * 26, width: 28, height: 23), context: context)
        }
        context.restoreGState()
    }

    /// Crop within the photographic frame without stretching the source image.
    private static func photo(_ name: String, in rect: CGRect, context: CGContext) {
        guard let image = UIImage(named: name) else { return }
        let scale = max(rect.width / image.size.width, rect.height / image.size.height)
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        context.saveGState(); context.clip(to: rect)
        image.draw(in: CGRect(x: rect.midX - size.width / 2, y: rect.midY - size.height / 2, width: size.width, height: size.height))
        context.restoreGState()
    }

    private static func fit(_ image: UIImage?, in rect: CGRect) {
        guard let image = image else { return }
        let scale = min(rect.width / image.size.width, rect.height / image.size.height)
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        image.draw(in: CGRect(x: rect.midX - size.width / 2, y: rect.midY - size.height / 2, width: size.width, height: size.height))
    }

    private static func symbolName(for value: String) -> String {
        switch value {
        case "Book": return "book.closed"
        case "Plant": return "leaf.circle"
        case "Leaf": return "leaf"
        case "Tree Shade": return "leaf.fill"
        case "Light": return "sun.max"
        case "Shadow": return "circle.lefthalf.fill"
        case "Details Only": return "magnifyingglass"
        case "Texture": return "square.grid.3x3"
        case "Fabric": return "square.grid.4x3.fill"
        case "Empty Space": return "rectangle.dashed"
        case "Circle": return "circle"
        case "Building": return "building.2"
        case "Lines": return "line.3.horizontal"
        case "Street": return "signpost.right"
        default: return "photo"
        }
    }
}

func reelImage(_ value: String) -> UIImage { ReelArtwork.image(for: value) }

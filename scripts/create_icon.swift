import AppKit

// Package the icon source as an opaque 1024 px App Store asset.
let projectRoot = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()
    .deletingLastPathComponent()
let sourceURL = projectRoot.appendingPathComponent("output/imagegen/crailglitun-icon-source.png")
let outputURL = CommandLine.arguments.count > 1
    ? URL(fileURLWithPath: CommandLine.arguments[1])
    : projectRoot.appendingPathComponent("Crailglitun/Assets.xcassets/AppIcon.appiconset/icon.png")

guard let source = NSImage(contentsOf: sourceURL),
      let image = source.cgImage(forProposedRect: nil, context: nil, hints: nil),
      let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
      let context = CGContext(
        data: nil,
        width: 1024,
        height: 1024,
        bitsPerComponent: 8,
        bytesPerRow: 4096,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
      ) else {
    throw CocoaError(.fileReadCorruptFile)
}

let bounds = CGRect(x: 0, y: 0, width: 1024, height: 1024)
context.setFillColor(CGColor(red: 0.141, green: 0.349, blue: 0.333, alpha: 1))
context.fill(bounds)
context.interpolationQuality = .high
context.draw(image, in: bounds)

guard let rendered = context.makeImage(),
      let data = NSBitmapImageRep(cgImage: rendered).representation(using: .png, properties: [:]) else {
    throw CocoaError(.fileWriteUnknown)
}

try data.write(to: outputURL, options: .atomic)
print("Saved icon: \(outputURL.path)")

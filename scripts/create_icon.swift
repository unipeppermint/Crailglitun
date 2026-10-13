import AppKit
let context = CGContext(data: nil,width: 1024,height: 1024,bitsPerComponent: 8,bytesPerRow: 4096,space: CGColorSpaceCreateDeviceRGB(),bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
func color(_ r: CGFloat,_ g: CGFloat,_ b: CGFloat)->CGColor { CGColor(red: r,green: g,blue: b,alpha: 1) }
context.setFillColor(color(0.965,0.953,0.922)); context.fill(CGRect(x: 0,y: 0,width: 1024,height: 1024))
for i in 0..<3 {
 let rect = CGRect(x: 184+i*224,y: 274,width: 208,height: 476)
 context.setFillColor(color(1,1,1)); context.addPath(CGPath(roundedRect: rect,cornerWidth: 74,cornerHeight: 74,transform: nil)); context.fillPath()
 let bar = CGRect(x: rect.minX+20,y: 395,width: rect.width-40,height: 234)
 context.setFillColor(i == 1 ? color(0.85,0.34,0.18) : color(0.32,0.49,0.45)); context.addPath(CGPath(roundedRect: bar,cornerWidth: 57,cornerHeight: 57,transform: nil)); context.fillPath()
}
context.setStrokeColor(color(1,1,1));context.setLineWidth(17);context.setLineCap(.round);context.setLineJoin(.round)
context.move(to: CGPoint(x: 474,y: 480));context.addLine(to: CGPoint(x: 550,y: 546));context.move(to: CGPoint(x: 494,y: 546));context.addLine(to: CGPoint(x: 550,y: 546));context.addLine(to: CGPoint(x: 550,y: 490));context.strokePath()
let rep = NSBitmapImageRep(cgImage: context.makeImage()!)
try rep.representation(using: .png,properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))

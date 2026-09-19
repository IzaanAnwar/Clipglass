import AppKit

let size = 1024
let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
                             bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                             colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
let shell = NSBezierPath(roundedRect: NSRect(x: 70, y: 70, width: 884, height: 884), xRadius: 200, yRadius: 200)
NSGradient(starting: NSColor(red: 0.31, green: 0.72, blue: 0.98, alpha: 1),
           ending: NSColor(red: 0.13, green: 0.30, blue: 0.83, alpha: 1))!.draw(in: shell, angle: -70)
let rear = NSBezierPath(roundedRect: NSRect(x: 250, y: 278, width: 418, height: 490), xRadius: 54, yRadius: 54)
NSColor.white.withAlphaComponent(0.28).setFill(); rear.fill()
let front = NSBezierPath(roundedRect: NSRect(x: 352, y: 216, width: 420, height: 494), xRadius: 54, yRadius: 54)
NSGradient(starting: NSColor.white.withAlphaComponent(0.98), ending: NSColor.white.withAlphaComponent(0.70))!.draw(in: front, angle: -90)
NSColor.white.withAlphaComponent(0.8).setStroke(); front.lineWidth = 3; front.stroke()
for (offset, width) in [(0, 238), (74, 238), (148, 162)] {
    let line = NSBezierPath(roundedRect: NSRect(x: 436, y: 574 - offset, width: width, height: 22), xRadius: 11, yRadius: 11)
    NSColor(red: 0.16, green: 0.37, blue: 0.73, alpha: 0.7).setFill(); line.fill()
}
NSGraphicsContext.restoreGraphicsState()
try bitmap.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))

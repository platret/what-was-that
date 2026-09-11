import AppKit
let size = 1024
let context = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: size * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
NSColor(calibratedRed: 0.90, green: 0.29, blue: 0.19, alpha: 1).setFill()
NSBezierPath(rect: NSRect(x: 0, y: 0, width: size, height: size)).fill()
let back = NSBezierPath(roundedRect: NSRect(x: 208, y: 240, width: 540, height: 570), xRadius: 115, yRadius: 115)
NSColor(calibratedRed: 0.96, green: 0.72, blue: 0.57, alpha: 1).setFill()
var transform = AffineTransform(); transform.translate(x: 480, y: 520); transform.rotate(byDegrees: 13); transform.translate(x: -480, y: -520); back.transform(using: transform); back.fill()
let front = NSBezierPath(roundedRect: NSRect(x: 244, y: 210, width: 550, height: 570), xRadius: 115, yRadius: 115)
NSColor(calibratedRed: 1, green: 0.97, blue: 0.89, alpha: 1).setFill(); front.fill()
let text: NSString = "?"
text.draw(in: NSRect(x: 366, y: 232, width: 320, height: 515), withAttributes: [.font: NSFont(name: "Georgia-Bold", size: 435)!, .foregroundColor: NSColor(calibratedRed: 0.22, green: 0.29, blue: 0.23, alpha: 1)])
NSGraphicsContext.restoreGraphicsState()
let bitmap = NSBitmapImageRep(cgImage: context.makeImage()!)
precondition(!bitmap.hasAlpha, "The App Store icon must be opaque")
let background = bitmap.colorAt(x: 0, y: 0)!.usingColorSpace(.sRGB)!
precondition(background.redComponent > 0.8, "The icon background did not render")
let paper = bitmap.colorAt(x: 300, y: 500)!.usingColorSpace(.sRGB)!
precondition(paper.greenComponent > 0.8, "The icon artwork did not render")
let symbol = bitmap.colorAt(x: 480, y: 500)!.usingColorSpace(.sRGB)!
precondition(symbol.greenComponent < 0.5, "The question mark did not render")
try bitmap.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "WhatWasThat/Resources/Assets.xcassets/AppIcon.appiconset/icon.png"))

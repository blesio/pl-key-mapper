import AppKit

private func color(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1.0) -> NSColor {
    NSColor(calibratedRed: r / 255.0, green: g / 255.0, blue: b / 255.0, alpha: a)
}

private func drawBackground(in rect: NSRect) {
    let rounded = NSBezierPath(roundedRect: rect, xRadius: 220, yRadius: 220)
    rounded.addClip()

    color(8, 28, 58).setFill()
    rounded.fill()

    let gradient = NSGradient(colors: [
        color(13, 77, 210, 0.95),
        color(0, 169, 255, 0.95)
    ])
    gradient?.draw(in: rounded, angle: -38)

    let glow = NSBezierPath(ovalIn: NSRect(x: -120, y: 560, width: 860, height: 500))
    color(255, 255, 255, 0.14).setFill()
    glow.fill()
}

private func drawKeyboardGlyph() {
    let bodyRect = NSRect(x: 190, y: 250, width: 644, height: 430)
    let body = NSBezierPath(roundedRect: bodyRect, xRadius: 86, yRadius: 86)
    color(246, 251, 255, 0.98).setFill()
    body.fill()

    let screenRect = NSRect(x: 262, y: 338, width: 500, height: 250)
    let screen = NSBezierPath(roundedRect: screenRect, xRadius: 42, yRadius: 42)
    color(14, 44, 88, 0.72).setFill()
    screen.fill()

    let rows = 3
    let cols = 8
    let dotSize: CGFloat = 23
    let xStart: CGFloat = 300
    let yStart: CGFloat = 375
    let xStep: CGFloat = 56
    let yStep: CGFloat = 57

    color(225, 242, 255, 0.95).setFill()
    for row in 0..<rows {
        for col in 0..<cols {
            let x = xStart + CGFloat(col) * xStep
            let y = yStart + CGFloat(row) * yStep
            let dot = NSBezierPath(ovalIn: NSRect(x: x, y: y, width: dotSize, height: dotSize))
            dot.fill()
        }
    }
}

private func drawPLBadge() {
    let badgeRect = NSRect(x: 628, y: 96, width: 290, height: 290)
    let badge = NSBezierPath(ovalIn: badgeRect)
    color(255, 255, 255, 0.97).setFill()
    badge.fill()

    let shadow = NSShadow()
    shadow.shadowBlurRadius = 14
    shadow.shadowOffset = NSSize(width: 0, height: -2)
    shadow.shadowColor = color(6, 27, 55, 0.25)
    shadow.set()

    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = .center

    let attrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 124, weight: .black),
        .foregroundColor: color(17, 66, 178, 1.0),
        .paragraphStyle: paragraph
    ]

    let text = NSAttributedString(string: "PL", attributes: attrs)
    let textRect = NSRect(x: badgeRect.minX, y: badgeRect.minY + 78, width: badgeRect.width, height: 136)
    text.draw(in: textRect)
}

private func generateIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    defer { image.unlockFocus() }

    NSGraphicsContext.current?.imageInterpolation = .high
    let fullRect = NSRect(x: 0, y: 0, width: size, height: size)
    drawBackground(in: fullRect)
    drawKeyboardGlyph()
    drawPLBadge()

    return image
}

guard CommandLine.arguments.count >= 2 else {
    fputs("Usage: generate-icon.swift <output-png-path>\n", stderr)
    exit(1)
}

let outputPath = CommandLine.arguments[1]
let iconImage = generateIcon(size: 1024)

guard
    let tiffData = iconImage.tiffRepresentation,
    let rep = NSBitmapImageRep(data: tiffData),
    let pngData = rep.representation(using: .png, properties: [:])
else {
    fputs("Failed to generate PNG data.\n", stderr)
    exit(2)
}

do {
    try pngData.write(to: URL(fileURLWithPath: outputPath))
} catch {
    fputs("Failed to write icon file: \(error.localizedDescription)\n", stderr)
    exit(3)
}

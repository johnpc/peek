import CoreGraphics
import UIKit

/// Paints a stand-in desktop (gradient wallpaper, a menu bar and two windows)
/// for the mock desktop, so the session view has real pixels to show.
enum MockFrame {
    static func render(size: CGSize) -> CGImage? {
        guard size.width > 0, size.height > 0 else { return nil }
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let image = renderer.image { context in
            let cg = context.cgContext
            drawWallpaper(in: cg, size: size)
            drawMenuBar(in: cg, size: size)
            drawWindow(in: cg, rect: CGRect(x: size.width * 0.08, y: size.height * 0.14,
                                           width: size.width * 0.5, height: size.height * 0.55))
            drawWindow(in: cg, rect: CGRect(x: size.width * 0.45, y: size.height * 0.35,
                                           width: size.width * 0.45, height: size.height * 0.5))
        }
        return image.cgImage
    }

    private static func drawWallpaper(in cg: CGContext, size: CGSize) {
        let colors = [UIColor(red: 0.10, green: 0.16, blue: 0.36, alpha: 1).cgColor,
                      UIColor(red: 0.55, green: 0.22, blue: 0.48, alpha: 1).cgColor]
        guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                        colors: colors as CFArray, locations: [0, 1]) else { return }
        cg.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: size.width, y: size.height), options: [])
    }

    private static func drawMenuBar(in cg: CGContext, size: CGSize) {
        cg.setFillColor(UIColor(white: 1, alpha: 0.85).cgColor)
        cg.fill(CGRect(x: 0, y: 0, width: size.width, height: max(24, size.height * 0.03)))
    }

    private static func drawWindow(in cg: CGContext, rect: CGRect) {
        let path = UIBezierPath(roundedRect: rect, cornerRadius: 12)
        cg.setFillColor(UIColor(white: 0.97, alpha: 1).cgColor)
        cg.addPath(path.cgPath)
        cg.fillPath()
        cg.setFillColor(UIColor(white: 0.88, alpha: 1).cgColor)
        cg.fill(CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: 28))
        let lights: [UIColor] = [.systemRed, .systemYellow, .systemGreen]
        for (index, color) in lights.enumerated() {
            cg.setFillColor(color.cgColor)
            cg.fillEllipse(in: CGRect(x: rect.minX + 10 + CGFloat(index) * 18, y: rect.minY + 8, width: 12, height: 12))
        }
    }
}

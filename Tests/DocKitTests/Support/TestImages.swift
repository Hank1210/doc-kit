import CoreGraphics
import ImageIO
import CoreText
import Foundation

/// Erzeugt Testbilder mit Text, damit keine echten Dokumente nötig sind.
enum TestImages {
    /// Weiße A4-Seite (150 dpi) mit großer Überschrift oben und einer kleineren Zeile darunter.
    static func page(heading: String, line: String) -> CGImage {
        let width = 1240, height = 1754
        let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                                space: CGColorSpaceCreateDeviceRGB(),
                                bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
        context.setFillColor(CGColor(gray: 1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        draw(heading, size: 72, at: CGPoint(x: 120, y: 1500), in: context)
        draw(line, size: 40, at: CGPoint(x: 120, y: 1380), in: context)
        return context.makeImage()!
    }

    private static func draw(_ text: String, size: CGFloat, at point: CGPoint, in context: CGContext) {
        let font = CTFontCreateWithName("Helvetica" as CFString, size, nil)
        let attributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key(kCTFontAttributeName as String): font,
            NSAttributedString.Key(kCTForegroundColorAttributeName as String): CGColor(gray: 0, alpha: 1),
        ]
        let line = CTLineCreateWithAttributedString(NSAttributedString(string: text, attributes: attributes))
        context.textPosition = point
        CTLineDraw(line, context)
    }

    /// Schreibt das Bild als JPEG in eine temporäre Datei.
    static func jpegFile(_ image: CGImage) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".jpg")
        let destination = CGImageDestinationCreateWithURL(url as CFURL, "public.jpeg" as CFString, 1, nil)!
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else { throw CocoaError(.fileWriteUnknown) }
        return url
    }
}

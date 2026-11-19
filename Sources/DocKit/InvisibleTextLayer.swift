// Übernommen aus Scan to me (ScanCore/PDFBuilder.swift, `drawInvisibleText`, Stand scan-to-me@18c4191).
// Der Aufbau der Scan-PDFs bleibt in Scan to me; hier liegt nur die Textebene, die beide Apps brauchen.
import CoreGraphics
import CoreText
import Foundation

/// Unsichtbare Textebene über einem gescannten Bild: macht eine Bildseite durchsuchbar und markierbar,
/// ohne ihr Aussehen zu ändern.
public enum InvisibleTextLayer {
    /// Setzt jede erkannte Zeile unsichtbar (Text-Render-Modus 3) in ihren Kasten im Bild: links bündig, so breit
    /// wie der Kasten; ist sie dafür zu breit, mit kleinerer Schrift.
    /// `imageRect` ist das Rechteck, in das das Bild auf der PDF-Seite gezeichnet wurde. Aufzurufen zwischen
    /// `beginPDFPage` und `endPDFPage`.
    public static func draw(_ page: RecognizedPage, over imageRect: CGRect, in context: CGContext) {
        context.saveGState()
        context.setTextDrawingMode(.invisible)
        for line in page.lines {
            let rect = CGRect(x: imageRect.minX + line.box.minX * imageRect.width,
                              y: imageRect.minY + line.box.minY * imageRect.height,
                              width: line.box.width * imageRect.width,
                              height: line.box.height * imageRect.height)
            guard rect.width > 1, rect.height > 1 else { continue }
            var fontSize = rect.height * 0.85
            var (ctLine, width, descent) = Self.line(line.text, fontSize: fontSize)
            guard width > 0 else { continue }
            // Zu breit: kleinere Schrift statt waagerecht stauchen. PDFKit (Vorschau, Spotlight) rechnet bei
            // gestauchtem Text mit der ungestauchten Breite und lässt beim Auslesen weg, was dann rechnerisch über
            // den Seitenrand hinausragt. Zu schmal: waagerecht strecken, das liest PDFKit vollständig.
            if width > rect.width {
                fontSize *= rect.width / width
                (ctLine, width, descent) = Self.line(line.text, fontSize: fontSize)
                guard width > 0 else { continue }
            }
            context.textMatrix = CGAffineTransform(scaleX: max(1, rect.width / width), y: 1)
            context.textPosition = CGPoint(x: rect.minX, y: rect.minY + descent * 0.5)
            CTLineDraw(ctLine, context)
        }
        context.restoreGState()
    }

    /// Die Zeile in Helvetica der Größe `fontSize`, mit Breite und Unterlänge.
    private static func line(_ text: String, fontSize: CGFloat) -> (CTLine, CGFloat, CGFloat) {
        let font = CTFontCreateWithName("Helvetica" as CFString, fontSize, nil)
        let attributed = NSAttributedString(string: text, attributes: [
            NSAttributedString.Key(kCTFontAttributeName as String): font])
        let ctLine = CTLineCreateWithAttributedString(attributed)
        var descent: CGFloat = 0
        let width = CGFloat(CTLineGetTypographicBounds(ctLine, nil, &descent, nil))
        return (ctLine, width, descent)
    }
}

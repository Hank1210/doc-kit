// Übernommen aus Scan to me (ScanCore/PDFBuilder.swift, `drawInvisibleText`, Stand scan-to-me@18c4191).
// Der Aufbau der Scan-PDFs bleibt in Scan to me; hier liegt nur die Textebene, die beide Apps brauchen.
import CoreGraphics
import CoreText
import Foundation

/// Unsichtbare Textebene über einem gescannten Bild: macht eine Bildseite durchsuchbar und markierbar,
/// ohne ihr Aussehen zu ändern.
public enum InvisibleTextLayer {
    /// Setzt jede erkannte Zeile unsichtbar (Text-Render-Modus 3) so, dass sie ihren Kasten im Bild genau füllt.
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
            let font = CTFontCreateWithName("Helvetica" as CFString, rect.height * 0.85, nil)
            let attributed = NSAttributedString(string: line.text, attributes: [
                NSAttributedString.Key(kCTFontAttributeName as String): font])
            let ctLine = CTLineCreateWithAttributedString(attributed)
            var descent: CGFloat = 0
            let width = CGFloat(CTLineGetTypographicBounds(ctLine, nil, &descent, nil))
            guard width > 0 else { continue }
            context.textMatrix = CGAffineTransform(scaleX: rect.width / width, y: 1)
            context.textPosition = CGPoint(x: rect.minX, y: rect.minY + descent * 0.5)
            CTLineDraw(ctLine, context)
        }
        context.restoreGState()
    }
}

import CoreGraphics
import DocKit
import PDFKit
import XCTest

final class InvisibleTextLayerTests: XCTestCase {
    private let pageRect = CGRect(x: 0, y: 0, width: 595.28, height: 841.89)
    private let lines = [
        RecognizedLine(text: "Stromrechnung Mai", box: CGRect(x: 0.1, y: 0.85, width: 0.5, height: 0.03)),
        RecognizedLine(text: "Kundennummer 4711", box: CGRect(x: 0.1, y: 0.78, width: 0.4, height: 0.02)),
    ]

    /// Eine Bildseite als PDF, wahlweise mit Textebene.
    private func pdf(withText: Bool) throws -> Data {
        let image = TestImages.page(heading: "Stromrechnung Mai", line: "Kundennummer 4711")
        let output = NSMutableData()
        var mediaBox = pageRect
        let consumer = try XCTUnwrap(CGDataConsumer(data: output))
        let context = try XCTUnwrap(CGContext(consumer: consumer, mediaBox: &mediaBox, nil))
        context.beginPDFPage(nil)
        context.draw(image, in: pageRect)
        if withText { InvisibleTextLayer.draw(RecognizedPage(lines: lines), over: pageRect, in: context) }
        context.endPDFPage()
        context.closePDF()
        return output as Data
    }

    func testTextBecomesSearchable() throws {
        let document = try XCTUnwrap(PDFDocument(data: try pdf(withText: true)))
        let text = try XCTUnwrap(document.page(at: 0)?.string)
        XCTAssertTrue(text.contains("Stromrechnung Mai"), text)
        XCTAssertTrue(text.contains("Kundennummer 4711"), text)
        XCTAssertEqual(document.findString("4711", withOptions: []).count, 1)
    }

    /// Jede Zeile liegt dort, wo sie im Bild steht.
    func testTextSitsOverItsBox() throws {
        // Das Dokument festhalten: Eine Seite verweist nur schwach darauf.
        let document = try XCTUnwrap(PDFDocument(data: try pdf(withText: true)))
        let page = try XCTUnwrap(document.page(at: 0))
        let selection = try XCTUnwrap(document.findString("Kundennummer", withOptions: []).first)
        let bounds = selection.bounds(for: page)
        let box = lines[1].box
        let expected = CGRect(x: box.minX * pageRect.width, y: box.minY * pageRect.height,
                              width: box.width * pageRect.width, height: box.height * pageRect.height)
        XCTAssertTrue(expected.insetBy(dx: -10, dy: -10).contains(CGPoint(x: bounds.midX, y: bounds.midY)),
                      "\(bounds) liegt nicht in \(expected)")
    }

    /// Die Textebene ändert das Aussehen der Seite nicht.
    func testLayerIsInvisible() throws {
        func pixels(_ data: Data) throws -> [UInt8] {
            let page = try XCTUnwrap(PDFDocument(data: data)?.page(at: 0))
            let image = page.thumbnail(of: CGSize(width: 300, height: 424), for: .mediaBox)
            let cg = try XCTUnwrap(image.cgImage(forProposedRect: nil, context: nil, hints: nil))
            let bitmap = NSBitmapImageRep(cgImage: cg)
            return Array(UnsafeBufferPointer(start: bitmap.bitmapData, count: bitmap.bytesPerRow * bitmap.pixelsHigh))
        }
        XCTAssertEqual(try pixels(pdf(withText: true)), try pixels(pdf(withText: false)))
    }

    /// Lange Zeile in hohem Kasten: Der ganze Text muss auslesbar bleiben. Früher wurde die Zeile waagerecht
    /// gestaucht, und PDFKit ließ das Ende weg.
    func testLongLineInTallBoxStaysComplete() throws {
        let text = "Betrag: 1.234,56 € (inkl. 19 % MwSt.) zahlbar bis 30.11.2026"
        for height in [0.02, 0.04, 0.06, 0.1] {
            let output = NSMutableData()
            var mediaBox = pageRect
            let context = try XCTUnwrap(CGContext(consumer: XCTUnwrap(CGDataConsumer(data: output)), mediaBox: &mediaBox, nil))
            context.beginPDFPage(nil)
            InvisibleTextLayer.draw(RecognizedPage(lines: [
                RecognizedLine(text: text, box: CGRect(x: 0.05, y: 0.7, width: 0.93, height: height)),
            ]), over: pageRect, in: context)
            context.endPDFPage()
            context.closePDF()
            let document = try XCTUnwrap(PDFDocument(data: output as Data))
            let extracted = (document.page(at: 0)?.string ?? "").filter { !$0.isWhitespace }
            XCTAssertEqual(extracted, text.filter { !$0.isWhitespace }, "Höhe \(height)")
            // Der Text bleibt in seinem Kasten.
            let page = try XCTUnwrap(document.page(at: 0))
            let bounds = try XCTUnwrap(document.findString("2026", withOptions: []).first).bounds(for: page)
            XCTAssertLessThanOrEqual(bounds.maxX, pageRect.width * 0.98 + 2, "Höhe \(height)")
        }
    }

    /// Zu kleine oder leere Kästen werden übersprungen, statt einen Fehler zu verursachen.
    func testSkipsDegenerateLines() throws {
        let output = NSMutableData()
        var mediaBox = pageRect
        let context = try XCTUnwrap(CGContext(consumer: XCTUnwrap(CGDataConsumer(data: output)), mediaBox: &mediaBox, nil))
        context.beginPDFPage(nil)
        InvisibleTextLayer.draw(RecognizedPage(lines: [
            RecognizedLine(text: "winzig", box: CGRect(x: 0.1, y: 0.1, width: 0.0001, height: 0.0001)),
            RecognizedLine(text: "", box: CGRect(x: 0.1, y: 0.5, width: 0.3, height: 0.03)),
        ]), over: pageRect, in: context)
        context.endPDFPage()
        context.closePDF()
        let text = PDFDocument(data: output as Data)?.page(at: 0)?.string ?? ""
        XCTAssertFalse(text.contains("winzig"))
    }
}

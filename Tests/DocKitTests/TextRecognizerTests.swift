import CoreGraphics
import DocKit
import XCTest

final class TextRecognizerTests: XCTestCase {
    override func tearDown() {
        Localization.current = .de
        super.tearDown()
    }

    func testRecognizesGermanTestPage() throws {
        let page = try TextRecognizer.recognize(TestImages.page(heading: "Stromrechnung Mai", line: "Test-Scanner Seite 1"))
        XCTAssertTrue(page.text.contains("Stromrechnung"), page.text)
        XCTAssertTrue(page.text.contains("Test-Scanner"), page.text)
        // Überschrift oben steht vor der kleineren Zeile darunter.
        XCTAssertTrue(page.lines.first?.text.contains("Stromrechnung") ?? false)
        // Kästen sind normalisiert, Ursprung unten links: die Überschrift liegt in der oberen Hälfte.
        let box = try XCTUnwrap(page.lines.first?.box)
        XCTAssertTrue(CGRect(x: 0, y: 0, width: 1, height: 1).contains(box))
        XCTAssertGreaterThan(box.midY, 0.5)
    }

    func testRecognizesJPEGFileWithTimeout() async throws {
        let url = try TestImages.jpegFile(TestImages.page(heading: "Kontoauszug", line: "Seite 2"))
        defer { try? FileManager.default.removeItem(at: url) }
        let page = try await TextRecognizer.recognize(jpegURL: url, timeout: TextRecognizer.pageTimeout)
        XCTAssertTrue(page.text.contains("Kontoauszug"), page.text)
    }

    func testUnreadableImage() {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("missing-\(UUID().uuidString).jpg")
        XCTAssertThrowsError(try TextRecognizer.recognize(jpegURL: url)) {
            XCTAssertEqual($0 as? TextRecognizerError, .unreadableImage(url.lastPathComponent))
        }
    }

    func testReadingOrder() {
        let lines = [RecognizedLine(text: "unten", box: CGRect(x: 0.1, y: 0.1, width: 0.2, height: 0.02)),
                     RecognizedLine(text: "oben rechts", box: CGRect(x: 0.6, y: 0.9, width: 0.2, height: 0.02)),
                     RecognizedLine(text: "oben links", box: CGRect(x: 0.1, y: 0.905, width: 0.2, height: 0.02))]
        XCTAssertEqual(TextRecognizer.sortedInReadingOrder(lines).map(\.text), ["oben links", "oben rechts", "unten"])
    }

    func testPageTextJoinsLines() {
        let page = RecognizedPage(lines: [RecognizedLine(text: "a", box: .zero), RecognizedLine(text: "b", box: .zero)])
        XCTAssertEqual(page.text, "a\nb")
    }

    /// Die Meldungen nennen keine Bedienelemente einer bestimmten App.
    func testMessagesAreAppNeutral() {
        Localization.current = .de
        XCTAssertEqual(TextRecognizerError.timedOut.errorDescription, "Die Texterkennung von macOS hat nicht reagiert.")
        XCTAssertEqual(TextRecognizerError.unreadableImage("3.jpg").errorDescription, "Seite 3.jpg ist nicht lesbar.")
        Localization.current = .en
        XCTAssertEqual(TextRecognizerError.timedOut.errorDescription, "The macOS text recognition did not respond.")
        XCTAssertEqual(TextRecognizerError.unreadableImage("3.jpg").errorDescription, "Page 3.jpg cannot be read.")
    }
}

final class TimeoutTests: XCTestCase {
    func testHangingWorkGivesUpInTime() async {
        let start = Date()
        do {
            _ = try await runWithTimeout(seconds: 0.3, timeoutError: TextRecognizerError.timedOut) { () -> Int in
                Thread.sleep(forTimeInterval: 3); return 1
            }
            XCTFail("hätte aufgeben müssen")
        } catch {
            XCTAssertEqual(error as? TextRecognizerError, .timedOut)
        }
        XCTAssertLessThan(Date().timeIntervalSince(start), 2)
    }

    func testResultAndErrorsPassThrough() async throws {
        let value = try await runWithTimeout(seconds: 5, timeoutError: TextRecognizerError.timedOut) { 42 }
        XCTAssertEqual(value, 42)
        do {
            _ = try await runWithTimeout(seconds: 5, timeoutError: TextRecognizerError.timedOut) { () -> Int in
                throw TextRecognizerError.unreadableImage("x")
            }
            XCTFail("Fehler hätte durchgereicht werden müssen")
        } catch {
            XCTAssertEqual(error as? TextRecognizerError, .unreadableImage("x"))
        }
    }
}

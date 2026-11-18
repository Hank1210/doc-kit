import DocKit
import XCTest

final class LocalizationTests: XCTestCase {
    override func tearDown() {
        Localization.current = .de
        super.tearDown()
    }

    func testLocPicksCurrentLanguage() {
        Localization.current = .de
        XCTAssertEqual(loc("Seite", "Page"), "Seite")
        Localization.current = .en
        XCTAssertEqual(loc("Seite", "Page"), "Page")
    }

    func testSystemDefault() {
        XCTAssertEqual(AppLanguage.systemDefault(preferred: ["de-DE", "en-US"]), .de)
        XCTAssertEqual(AppLanguage.systemDefault(preferred: ["de-AT"]), .de)
        XCTAssertEqual(AppLanguage.systemDefault(preferred: ["en-GB", "de-DE"]), .en)
        XCTAssertEqual(AppLanguage.systemDefault(preferred: ["fr-FR"]), .en)
        XCTAssertEqual(AppLanguage.systemDefault(preferred: []), .en)
    }

    func testDisplayNames() {
        XCTAssertEqual(AppLanguage.allCases.map(\.displayName), ["Deutsch", "English"])
    }

    /// Die Wahl wird z. B. in den Einstellungen gesichert; der Rohwert darf sich nicht ändern.
    func testCodableRawValues() throws {
        XCTAssertEqual(String(decoding: try JSONEncoder().encode([AppLanguage.de, .en]), as: UTF8.self), #"["de","en"]"#)
    }

    func testConcurrentAccessIsSafe() {
        DispatchQueue.concurrentPerform(iterations: 1_000) { index in
            Localization.current = index.isMultiple(of: 2) ? .de : .en
            _ = loc("a", "b")
        }
    }
}

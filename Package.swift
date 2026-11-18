// swift-tools-version:5.10
import PackageDescription

// Gemeinsamer, app-neutraler Code von Scan to me und PDF to me.
// Keine `unsafeFlags`: Sonst ließe sich DocKit nicht als Abhängigkeit einbinden.
let package = Package(
    name: "DocKit",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "DocKit", targets: ["DocKit"]),
    ],
    targets: [
        .target(name: "DocKit"),
        .testTarget(name: "DocKitTests", dependencies: ["DocKit"]),
    ]
)

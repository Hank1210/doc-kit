# DocKit

Shared, app-neutral building blocks for [Scan to me](https://github.com/Hank1210/scan-to-me) and
[PDF to me](https://github.com/Hank1210/pdf-to-me), two native macOS apps for documents.

DocKit is a Swift package. It contains no user interface and nothing specific to one app: no file paths, no
Keychain entries, no settings. Each app supplies its own values.

## Contents

| Part | What it does |
| --- | --- |
| `Localization` | German and English texts as pairs in code: `loc("Seite", "Page")`. `AppLanguage` picks German or English from the system languages. |
| `TextRecognizer` | Local text recognition with Apple Vision (German and English). Lines come in reading order with their position on the page. `runWithTimeout` gives up on work that hangs. |
| `InvisibleTextLayer` | Draws recognized text invisibly over a scanned image in a PDF, so the page becomes searchable without changing how it looks. |

Everything runs on the Mac. DocKit makes no network connections.

## Requirements

- macOS 14 or later
- Swift 5.10 or later

## Usage

Add DocKit to `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/Hank1210/doc-kit.git", from: "1.0.0"),
],
targets: [
    .target(name: "MyCore", dependencies: [.product(name: "DocKit", package: "doc-kit")]),
]
```

```swift
import DocKit

Localization.current = AppLanguage.systemDefault()
let page = try TextRecognizer.recognize(image)
print(page.text)
```

## Versions

DocKit uses [semantic versioning](https://semver.org/). Bug fixes raise the last number, new functions the middle
one, incompatible changes the first one. The apps depend on DocKit with `from: "X.Y.Z"`, so Dependabot proposes
new major versions separately.

## Development

```sh
swift test
```

To work on DocKit and one of the apps at the same time, point the app at your local copy (the package identity
is `doc-kit`, taken from the repository URL):

```sh
swift package edit doc-kit --path ../doc-kit
```

Rules for contributions:

- Only code that both apps use belongs here. App-specific code stays in the app.
- Every function comes with tests in `Tests/DocKitTests`. Test data is generated, never taken from real
  documents.
- No third-party dependencies.

## License

[MIT](LICENSE)

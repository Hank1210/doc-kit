# Changelog

All notable changes to DocKit are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and version numbers follow
[Semantic Versioning](https://semver.org/).

## [Unreleased]

## [1.0.0] - 2026-11-18

First version, extracted from Scan to me.

### Added

- `Localization`, `AppLanguage` and `loc(_:_:)` for German and English texts in code.
- `TextRecognizer` for local text recognition with Apple Vision, with `RecognizedPage`, `RecognizedLine` and
  `runWithTimeout`.
- `InvisibleTextLayer` to make scanned PDF pages searchable.

[Unreleased]: https://github.com/Hank1210/doc-kit/compare/1.0.0...HEAD
[1.0.0]: https://github.com/Hank1210/doc-kit/releases/tag/1.0.0

# Changelog

changelog should follow [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) conventions.

`MoonBit Language Changes`  no need for such detailed classification.

## [Unreleased]

### `moonbitlang/core` Changes 

#### Added

- Export `FromJson` trait from `@json` package in prelude for easier JSON deserialization

#### Changed

- **BREAKING**: `String::at` and `StringView::at` now return `UInt16` instead of `Int` and are the primary methods for accessing UTF-16 code units
- **BREAKING**: `String::code_unit_at` and `StringView::code_unit_at` are now aliases for `at` instead of being separate methods
- `String::trim`, `String::trim_start`, `String::trim_end` and their `StringView` counterparts now accept optional `chars` parameter with default whitespace characters

#### Deprecated

- `String::charcode_at` (previously named `at`) is now deprecated, use `String::at` which returns `UInt16`
- `String::trim_space` and `StringView::trim_space` are now deprecated, use `trim()` with default whitespace characters instead

#### Removed

#### Fixed

### MoonBit Language Changes




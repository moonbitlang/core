# Changelog

changelog should follow [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) conventions.

`MoonBit Language Changes`  no need for such detailed classification.

## [Unreleased]

### `moonbitlang/core` Changes 

#### Added

#### Changed

- **BREAKING**: `String::at` and `StringView::at` now return `UInt16` instead of `Int` and are the primary methods for accessing UTF-16 code units
- **BREAKING**: `String::code_unit_at` and `StringView::code_unit_at` are now aliases for `at` instead of being separate methods

#### Deprecated

- `String::charcode_at` (previously named `at`) is now deprecated, use `String::at` which returns `UInt16`

#### Removed

#### Fixed

### MoonBit Language Changes




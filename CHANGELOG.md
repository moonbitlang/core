# Changelog

changelog should follow [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) conventions.

`MoonBit Language Changes`  no need for such detailed classification.

## [0.6.36]

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

#### Added

- Introduced the `#declaration_only` attribute for function, method, and type declarations. These declarations can be called or tested immediately but require a concrete implementation to function at runtime. Accessing a declaration without an implementation will result in a runtime crash.

- The compiler can now report unused warning on async annotations when the function is actually synchronous

- `moonfmt` will automatically migrate `mbt test`/`mbt test(async)` code blocks in Markdown to `mbt check`.

#### Changed

- The default value of optional arguments can now raise error or perform async operations, as long as the function itself allow these effects

- Refactored the representation of JS backend trait objects. Each trait object now consists of two fields: the underlying data and a method table. This allows trait objects of the same type to share a single method table.

#### Deprecated

## [0.6.35]

### `moonbitlang/core` Changes

#### Added

- `String::fold` `String::rev_fold` `StringView::fold` `StringView::rev_fold`
  now supports error polymorphism (#3034)

- `ArrayView::get` is added (#3025)

#### Changed

- The output format of `SourceLoc` has been changed (#3035)

#### Deprecated

- `Result::or` `Result::or_else` are deprecated in favor of `Result::unwrap_or`
  `Result::unwrap_or_else` (#3031)
- Passing `max_nesting_depth` to `@json.parse` is deprecated. (#3028)

### MoonBit Language Changes

#### Added

- `#module` attribute now supports importing JS modules in CJS format

- Docstrings now support `mbt check` to mark MoonBit code blocks that
  participate in compilation. Currently, `mbt check` blocks in docstrings have
  the following restrictions:
  1. Only test code is allowed in `mbt check` blocks
  2. `mbt check` blocks must not contain parse errors

#### Changed

- An array literal without a type annotation that is bound to a local variable
  is now inferred as `Array`; if the variable is only read, or only read and
  written, the user is prompted to annotate it as `ReadOnlyArray` or
  `FixedArray`

#### Deprecated

- We will remove the previously added `mbt test` and `mbt test(async)` support
  in the future, keeping only `mbt check`

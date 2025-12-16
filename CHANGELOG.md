# Changelog

## [Unreleased]

### `moonbitlang/core` Changes

#### Added

- `String::fold` `String::rev_fold` `StringView::fold` `StringView::rev_fold`
  now supports error polymorphism (#3034)

- `ArrayView::get` is added (#3025)

#### Deprecated

- `Result::or` `Result::or_else` are deprecated in favor of `Result::unwrap_or`
  `Result::unwrap_or_else` (#3031)
- Passing `max_nesting_depth` to `@json.parse` is deprecated. (#3028)

### MoonBit Language Changes

- Enhancement: `#module` attribute now supports importing JS modules in CJS format

- Enhancement: Docstrings now support `mbt check` to mark MoonBit code blocks that participate in compilation. Currently, `mbt check` blocks in docstrings have the following restrictions:
  1. Only test code is allowed in `mbt check` blocks
  2. `mbt check` blocks must not contain parse errors

- Enhancement: An array literal without a type annotation that is bound to a local variable is now inferred as `Array`; if the variable is only read, or only read and written, the user is prompted to annotate it as `ReadOnlyArray` or `FixedArray`

- Deprecated: We will remove the previously added `mbt test` and `mbt test(async)` support in the future, keeping only `mbt check`


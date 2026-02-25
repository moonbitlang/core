# Changelog

changelog should follow [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) conventions.

`MoonBit Language Changes`  no need for such detailed classification.

## [0.8.1]

### `moonbitlang/core` Changes

#### Added

- Core commit: `bd827dc85`
- Added `Debug` trait with `derive(Debug)` support, including `ignore=[..]` configuration for non-debuggable nested types
- Added new `moonbitlang/async` APIs including `@process.spawn`, advisory file locking, `@fs.tmpdir`, `@async.all`, and `@async.any`

#### Changed

- `@json.inspect` has been migrated to `json_inspect`
- `String::sub` and `StringView::sub` now panic on invalid indices instead of raising `CreatingViewError`. The `CreatingViewError` type has been removed.

### MoonBit Language Changes

#### Added

- Added `declare` keyword (replacing `#declaration_only`) for staged declarations, including declared impl relationships
- Added reversed-range syntax `x>..y` / `x>=..y` for `for .. in`
- Added user-defined `struct` constructors (`fn new` + `S::new`)
- Added panic backtrace support on wasm-gc/native/LLVM backends in debug mode
- Added `moon fetch`, `moon ide hover`, and `moon ide rename` subcommands
- Added `moon test -j`, `moon test --outline`, and range form of `moon test --index`

#### Changed

- `for`/`while`/`for .. in` loop `else` blocks are now written with `nobreak`
- `x..f()` semantics are standardized as `{ x.f(); x }`, and ignored-return misuse now warns
- `moon -C <path>` now changes working directory semantics; `--manifest-path` was added
- `moon run` and `moon build` now default to `--debug`
- `.mbt.md` dependency front matter supports package-level imports and aliasing

#### Deprecated

- Deprecated `suberror Err PayloadType` in favor of enum-like `suberror` syntax
- Deprecated `x..=y` in favor of `x..<=y` for closed forward ranges
- Deprecated effect inference for local `fn` that performs `raise`/`async` without explicit annotation
- Deprecated `moon.pkg.json` in favor of `moon.pkg`
- Deprecated old `moon install` behavior (installing project dependencies)

## [0.7.1]

### `moonbitlang/core` Changes

#### Added

- Core commit: `c0b22a8b0`
- `moonbitlang/async` now supports Windows (MSVC), plus updates to `@fs.mkdir` (`recursive`) and process APIs
- Experimental `lexmatch` now supports POSIX character classes like `[:digit:]`

### MoonBit Language Changes

#### Added

- Added warning for unused `async`
- Optional argument default expressions can now `raise` (when function signature allows it)
- Added `#declaration_only` for staged/spec-driven declarations
- Added pipeline shorthand `e1 |> x => e2`
- Added loop invariants/reasoning annotations for `for` loops
- Added experimental `moon.pkg` support (migration via `NEW_MOON_PKG=1 moon fmt`)
- Added `moon ide` subcommands (`peek-def`, `outline`, `doc`) and doc-test `mbt check` support

#### Changed

- `SourceLoc` output now uses relative paths
- `moon add` now runs `moon update` automatically
- New `moon` backend is enabled by default (`NEW_MOON=0` to switch back)
- Build artifacts moved from `target` to `_build` (with a `target` symlink for compatibility)
- `Iter` in `moonbitlang/core` migrated to external iterator semantics (single-pass traversal)

#### Deprecated

- Inferring `Ref` through struct literal `{ val: ... }` is deprecated
- `Iterator` alias and `.iterator()` methods are deprecated in favor of `Iter` and `.iter()`

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

## [0.6.33]

### `moonbitlang/core` Changes

#### Added

- Core commit: `b989ba000`
- Added `MutArrayView` as the unified mutable slice type
- Added `#module("...")` support for importing third-party JS modules

#### Changed

- `ArrayView` is now the unified immutable slice for `Array`/`FixedArray`/`ReadOnlyArray`
- `string[x]` now returns `UInt16` (migrate to `code_unit_at`)

#### Deprecated

- Deprecated `Container::of` in favor of `Type::from_array(ArrayView[_])`
- Renamed `@test.T` to `@test.Test` and `@priority_queue.T` to `@priorityqueue.PriorityQueue`

### MoonBit Language Changes

#### Added

- `ReadOnlyArray` now supports pattern matching, slicing, and spread
- Bitstring patterns now support signed extraction
- Added `#label_migration` for parameter-label alias/deprecation migration
- Added warning mnemonics and `#warnings` local configuration
- Added `test_unqualified_package` warning (disabled by default)
- Added `mbt test` and `mbt test(async)` markdown/doc code blocks

#### Changed

- Cascade calls now allow non-`Unit` intermediate returns with `invalid_cascade` warning
- `mbt`/`moonbit` code blocks no longer type-check by default; use `mbt check`
- Default behavior changed for `#deprecated`: now warns in current package unless `skip_current_package=true`
- Experimental `lexmatch` now supports `first` mode with search/non-greedy behavior
- Alerts are merged into warning configuration

## [0.6.30]

### `moonbitlang/core` Changes

#### Added

- Core commit: `07d9d2445`
- Added external iterator type support (`Iterator`) with `for .. in` integration via `.iterator()`/`.iterator2()`

### MoonBit Language Changes

#### Added

- Added `using @pkg { ... }` as unified alias syntax for values, types, and traits
- Added `#alias` support for types and traits
- Added duplicate test-name warnings
- Added experimental `lexmatch?` and case-insensitive regex modifier `(?i:...)`
- Added `ReadOnlyArray` built-in type for immutable fixed-length lookup tables
- Added anti-pattern lint warnings for selected patterns
- Added `#deprecated(skip_current_package=...)` parameter

#### Changed

- Bitstring patterns now require explicit endianness suffixes such as `u1be` and `u32le`

#### Deprecated

- `traitalias`, `fnalias`, and `typealias` are being migrated toward `using`, `type Alias = ...`, and `#alias`
- Deprecated `moon info --no-alias`

## [0.6.29]

### `moonbitlang/core` Changes

#### Added

- Core commit: `9037370fc`
- Added per-process randomized hashing to mitigate HashDoS risks

#### Changed

- `ArrayView` became immutable

### MoonBit Language Changes

#### Added

- Added `async test` and `async fn main` (native backend on Linux/macOS)
- Added experimental `lexmatch` expression for `StringView`/`BytesView`
- Added unified `using` imports with `pub using` support for re-export
- Added optional parameters on trait methods
- Added `#alias` operator-overloading aliases for methods like get/set/view
- Released wasm toolchain packages for x86 Darwin and ARM Linux
- Added `.mbt.md` formatting support in `moon fmt`

#### Removed

- Removed long-deprecated behavior where `fn meth(self : T, ..)` could also be called as a plain function
- Removed `direct_use` from `moon.pkg.json` (replaced by `using`)

# Changelog

## [Unreleased]

### `moonbitlang/core` Changes

#### Added

- Added `eprintln` for writing a line to standard error (#4222).
- Added the `encoding/percent` package for RFC 3986 URI-component encoding, strict decoding, and lossy decoding (#4214).

#### Fixed

- Compiling very long regex literals (for example `Regex::string` of 100k characters) no longer overflows the stack on the JS and Wasm backends (#4266).
- `Float` and `Double` now hash positive and negative zero identically, keeping hashing consistent with equality (#4224).
- `@math.pow` now returns `1` for `pow(1, NaN)` and `pow(±1, ±Infinity)` (#4219).
- QuickCheck's `Float` shrinker no longer yields candidates equal to the input after conversion to `Float` (#4227).
- `argparse` now skips both the Node executable and script path when using the default command-line arguments (#4229).
- `@env.rand` now returns `None` when WASI's entropy request fails (#4230).

## [0.10.13] - 2026-09-15

Compiler version: `v0.10.13+cbb11c36f`.

### `moonbitlang/core` Changes

#### Added

- Added `clamped_view` for `Array`, `ArrayView`, `Bytes`, `BytesView`, `FixedArray`, and `ReadOnlyArray` (#4210), plus `MutArrayView` and `UninitializedArray` (#4216).

#### Changed

- **BREAKING**: Built-in bracket slicing now clamps out-of-range bounds and returns an empty view for inverted ranges. Negative bounds clamp to zero. String slices trim boundaries inward when they split UTF-16 surrogate pairs; use `split_at` for a lossless partition (#4215).
- Strict slicing is now named `exact_view`; the previous `view` and `sub` names remain deprecated aliases where applicable. `get_view` continues to return `None` for invalid bounds (#4217).
- **BREAKING**: `Logger` implementations must provide at least one of `write_view` or `write_substring`, preventing the two default implementations from recursively calling each other (#4220).
- QuickCheck builds collection shrink candidates lazily, reducing intermediate allocations (#4208).
- QuickCheck runs zipped generators directly, reducing intermediate allocations (#4147).

#### Fixed

- QuickCheck shrinking no longer recurses once per candidate block, avoiding stack overflow on large inputs (#4211).
- Fixed overflow and unbalanced-division edge cases in the new wide-limb `BigInt` implementation (#4201).

### MoonBit Language Changes

#### Changed

- The `value |> x => { ... }` pipeline form now supports async operations in its body.
- Wildcard imports in `.mbtx` scripts also introduce the package's default alias, allowing explicit `@pkg.name` access alongside imported names.

#### Deprecated

- Deprecated `value |> fn(x) { ... }` and type-annotated anonymous functions after `|>`. Use `value |> x => { ... }` instead.

#### Removed

- **BREAKING**: Removed the deprecated `f!()` call syntax, including method and pipeline calls. Use ordinary calls; error propagation needs no call-site marker.

#### Fixed

- Fixed short-circuit evaluation of `&&` and `||` containing async operations.
- Fixed incorrect handling of cancellable and `nocancel` async functions in generic code.

## [0.10.12] - 2026-09-08

Compiler version: `v0.10.12+1634b282e`.

### `moonbitlang/core` Changes

#### Added

- Added `Array()` as the constructor form of `Array::new` (#4168).
- Added `Array::release_unused(placeholder~)` (#4190) and `Deque::release_unused(placeholder~)` (#4189) to release references retained in unused buffer capacity.

#### Changed

- `Array` (#4190) and `Deque` (#4189) shrinking operations no longer clear vacated slots to uninitialized values. Views retained across a mutation remain invalid to use, but on native and Wasm they now observe unspecified valid values rather than uninitialized memory. Removed elements remain reachable until their slots are overwritten, the buffer is replaced, or the container is dropped. This includes `clear`; use `release_unused` or `shrink_to_fit` to release retained references explicitly. JavaScript `ArrayView` access past the array's current length still observes `undefined`.
- `Deque` traversal and mapping callbacks, and `Queue` traversal and fold callbacks, now support error polymorphism (#4161).
- `BigInt` uses 64-bit limbs on native and Wasm (#4164).
- Improved `BigInt` division and decimal conversion (#4201), including caching division reciprocals used for decimal conversion (#4188).
- Improved JSON string escaping (#4144).
- Improved indented JSON formatting by caching indentation (#4145) and growing that cache incrementally (#4183).
- Improved integer-valued double formatting (#4184).
- Reduced redundant initialization when copying arrays (#4169).
- Improved UTF-8 decoding performance (#4163).

#### Deprecated

- Deprecated `Array::new` in favor of `Array()` (#4168), and `StringBuilder::new` in favor of `StringBuilder()` (#4113).

#### Removed

- Removed the deprecated `strconv` APIs; use the parsing functions in `string` (#4193). The empty `strconv` package remains for import compatibility (#4207).
- Removed deprecated `Show` implementations for `HashMap` and `Set`; use `Debug` for diagnostic output (#4199).
- Removed deprecated `BigInt::from_hex` and `BigInt::to_hex`; use `from_string` and `to_string` with `radix=16` (#4167).

#### Fixed

- Hash seeds now use platform entropy on native, LLVM, and JavaScript rather than relying on a clock-derived seed (#4160).
- Fixed immutable-vector size overflow near the maximum `Int` value (#4136).
- Fixed QuickCheck shrinking of minimum signed integers (#4151).

### MoonBit Language Changes

#### Added

- Added irrefutable patterns in `for ... in` headers and comprehensions, including tuple/record destructuring and destructuring both values from `Iter2`.
- Added `T::_` to match any constructor of a suberror type, including abstract suberrors. `T::_ as err` also binds the error with its refined type.
- Added `derive(Shrink)` for structs and ordinary enums. It shrinks fields or the current constructor's payload; it does not switch constructors or perform subterm shrinking.
- Added wildcard package imports using the `*` alias in `.mbtx` scripts.

#### Changed

- `nocancel` now has checked semantics: a `nocancel` async function may call synchronous or `nocancel` functions, but not cancellable async functions.
- The compiler's cancellation signal bypasses `catch`, including catch-all handlers, while still running `defer` and `errdefer`. Libraries using their own error type for cancellation retain their existing behavior until they adopt this signal.

#### Removed

- **BREAKING**: Removed `for { ... }`; use `for ;; { ... }` for an infinite loop.
- **BREAKING**: Removed `fn name[T](...)`; put type parameters before the function name, as in `fn[T] name(...)`.
- **BREAKING**: Removed `typealias`, `traitalias`, and `fnalias`. Use `type A = B` for type aliases or `using` for imported aliases.
- **BREAKING**: Removed `type!` and single-constructor `suberror E(Int)` declarations. Use `suberror E { E(Int) }`.

#### Fixed

- Fixed incorrect array reads and writes when evaluating the index or assigned value also mutates the array.

## [0.10.11] - 2026-08-31

Compiler version: `v0.10.11+6ff76a5f9`.

### `moonbitlang/core` Changes

#### Added

- Added optional `limit` arguments to `@splitmix.RandomState::next_uint` and `next_uint64`, using unbiased bounded integer sampling (#4124).

#### Changed

- Improved hexadecimal encoding/decoding performance (#4122).
- Reduced output allocation during lossy UTF-8 decoding (#4143).

#### Fixed

- Fixed `HashSet::copy` sharing mutable storage with its source (#4130).

### MoonBit Language Changes

#### Added

- Value structs and enums can contain nested value types on the C and Wasm linear-memory backends. Recursive value types remain invalid.

#### Changed

- Removed the six-field limit on value structs.

#### Fixed

- Blackbox tests' implicit imports now include constructor aliases and correctly handle aliases declared with attributes.
- Fixed overflow when computing large native array allocation sizes.

## [0.10.10] - 2026-08-24

Compiler version: `v0.10.10+f8a486b6f`.

### `moonbitlang/core` Changes

#### Added

- Added `encoding/hex` with `encode(BytesView)` and `decode(StringView)` (#3625).
- Added `FromJson` for `HashMap[String, V]` (#3584).
- Re-exported the `Shrink` trait from the root `quickcheck` package (#4104).

#### Changed

- String substring searches now have a guaranteed-linear fallback for inputs with many partial matches (#4119).
- Improved ASCII decoding (#3838).
- Improved JSON escaping (#3782).
- Improved decimal parsing (#3957).
- Improved sorted-set difference, intersection, and symmetric difference (#3315), including difference/intersection between sets of very different sizes (#4108).
- Improved sorted-set union performance (#3829).

#### Deprecated

- Renamed `List::is_prefix` and `List::is_suffix` to `has_prefix` and `has_suffix`, retaining deprecated aliases (#4109).

#### Removed

- Removed the deprecated `Show` implementation for `Iter2` (#4105).
- Removed deprecated byte-order conversion methods on `BytesView` (#4101).

#### Fixed

- Base64 decoding now reads UTF-16 code units correctly instead of reinterpreting them as bytes (#4096).
- Fixed `BigInt::from_octets` for empty inputs (#4115) and inputs with leading zero limbs (#3835).

### MoonBit Language Changes

#### Added

- Accepted `nocancel` annotations in preparation for cancellation support. In this release they have no semantic effect; enforcement arrives in 0.10.12.

#### Deprecated

- Accepted `var x = value` and `var x : T = value` as compatibility syntax, with a deprecation warning directing users to `let mut`.
- Passing `Array` across JavaScript FFI boundaries now warns; use `FixedArray` instead.

#### Removed

- **BREAKING**: Removed deprecated loop `else` blocks. Use `nobreak`.

#### Fixed

- Fixed a compiler crash while checking unreachable `lexscan` branches.
- Regex literals reject invalid repeated anchors such as `re"^+"`.

## [0.10.9] - 2026-08-19

Compiler version: `v0.10.9+6e6c44045`.

### `moonbitlang/core` Changes

#### Added

- Added `immut/vector_map`, a persistent insertion-ordered map (#4081).
- Expanded QuickCheck `Arbitrary` and `Shrink` support for integer types, arrays, maps, sets, deques, priority queues, and references (#4090).

#### Changed

- **BREAKING**: `@json.parse` rejects unpaired `\uXXXX` surrogate escapes instead of constructing malformed Unicode strings. A leading surrogate must be followed immediately by an escaped trailing surrogate; invalid pairs raise `ParseError::InvalidChar` at the offending escape. `@json.valid` rejects the same documents. This can reject inputs emitted by JavaScript's `JSON.stringify` (#4064).

#### Fixed

- JSON number parsing preserves the sign of `-0` (#4061).
- Fixed immutable-vector concatenation and rebalancing invariants (#4082).
- Made nested `LazyList::concat` traversal stack-safe (#4071).
- Corrected unsigned conversion of large negative `BigInt` values (#4054).
- Fixed length validation in JavaScript `BigInt::to_octets` (#4063).
- Fixed regex sequence continuations being applied twice (#4075).
- Fixed zero-length equal edits from `Diff::group(context=0)` (#4057).

### MoonBit Language Changes

#### Changed

- `defer` and `errdefer` bodies can raise errors and perform async operations. A cleanup error replaces the pending error, and remaining cleanup blocks still execute.
- `#warnings` also controls syntax warnings.
- Reserved `nocancel` as a keyword.

#### Added

- Added `fragile_catch_all` warnings for catch-all handlers that perform cleanup and re-raise the same error; use `defer` or `errdefer` for cleanup.

## [0.10.8] - 2026-08-18

Compiler version: `v0.10.8+8606a5800`.

### `moonbitlang/core` Changes

#### Added

- Added `@lexbuf.StringScanner` for scanning an existing string (#4019).
- Added an optional callback to describe QuickCheck counterexamples (#3993), named `counterexample_context` in `check` and `report` (#4004).
- Added `min` and `max` arguments to `Rand::float` and `Rand::double` for uniform range sampling (#4000).

#### Deprecated

- Deprecated `Lexbuf::from_string` in favor of `StringScanner` (#4023).

#### Removed

- Removed the deprecated bytes-regex APIs (#4002) and the `BytesRegex` type (#4013).

#### Fixed

- Canonicalized immutable hash-map (#4001) and hash-set (#4017) trees so equality depends on contents rather than insertion/removal history.
- Normalized `BigInt::from_octets` results to avoid noncanonical representations (#4020).

### MoonBit Language Changes

#### Added

- Added `errdefer` to run cleanup when its scope exits through an error or async cancellation, but not on normal return, `break`, or `continue`.
- Streaming `lexscan` accepts `@lexbuf.StringScanner` in addition to synchronous and asynchronous stream buffers.

#### Removed

- Removed `lexscan` directly on `String`/`StringView`; use `lexmatch` for direct string matching or a scanner for streaming-style matching.

## [0.10.7] - 2026-08-11

Compiler version: `v0.10.7+bc794d341`.

### `moonbitlang/core` Changes

#### Added

- Added QuickCheck `check` and `report`, composable `Generator`s, reproducible seeds, input filtering, and the `quickcheck/shrink` package for reducing counterexamples (#3955).
- Added QuickCheck generator combinators for character ranges and zipping generators (#3977), plus `Generator::spawn` for drawing from an `Arbitrary` implementation (#3994).
- Added QuickCheck observations for labeling, classifying, and collecting statistics about generated inputs (#3980).
- QuickCheck character generation now covers Unicode scalar values beyond ASCII (#3979).

#### Changed

- **BREAKING**: `String::get` and `StringView::get` now return `UInt16?` rather than `Int?`, matching code-unit access through `at` (#3965).

#### Removed

- **BREAKING**: Removed the fully deprecated `immut/array` package. Use `immut/vector` instead (#3998).

#### Fixed

- `String::find_by` and `StringView::find_by` now return UTF-16 code-unit offsets, including after supplementary characters (#3985).
- JSON parses large integer literals to correctly rounded doubles (#3996).
- Fixed bounded random-integer sampling bias (#3961).
- Corrected `round` at signed zero, half-integer boundaries, and large integer values (#3939).
- Preserved the sign of `tanh` for tiny negative inputs (#3936).
- Corrected `cbrt` for negative normal values (#3938).
- Improved `log2` accuracy near powers of two (#3940).

### MoonBit Language Changes

#### Changed

- `lexscan` checks unreachable branches and permits omission of a catch-all branch when the regex cases are exhaustive.

#### Deprecated

- Deprecated direct `lexscan` on `String`/`StringView` in favor of `lexmatch`.
- Deprecated the special method names `op_get`, `op_set`, and `op_as_view` for operator overloading. Give the method a normal name and an operator `#alias` instead.

#### Removed

- **BREAKING**: Removed local type definitions inside functions. Move the type declaration to the top level.

## [0.10.6] - 2026-08-04

Compiler version: `v0.10.6+80dc50f24`.

### `moonbitlang/core` Changes

#### Added

- Added `diff`, with Myers and Patience sequence diffs, grouped hunks, and rendering callbacks (#3247).
- Added edit scripts and bounded or unbounded edit-distance functions to `diff` (#3952).

#### Changed

- Moved standard-library `Arbitrary` implementations into `quickcheck` so container packages no longer depend on the testing package (#3956).

#### Fixed

- Fixed buffer growth overflow (#3944).
- Fixed decimal parsing when the coefficient exceeds 800 digits (#3847).
- `@math.hypot` returns infinity when one input is infinite and the other is NaN (#3935).

### MoonBit Language Changes

#### Changed

- Non-exhaustive `guard` patterns without an `else` now produce `guard_inexhaustive` warnings. Add an `else` handler or use `guard!` when failure should panic.

## [0.10.5] - 2026-07-28

Compiler version: `v0.10.5+5e7afb0c0`.

### `moonbitlang/core` Changes

#### Added

- Added `lexbuf`, with synchronous and asynchronous streaming inputs for `lexscan` (#3811).
- Added surrogate-safe `String`/`StringView::clamped_view` and `split_at` (#3831).
- Added `@string.parse_bigint` (#3679).
- Added `Json(x)` (#3924) and `@json.to_json` (#3850) for JSON conversion.
- Added `@debug.Repr(x)` for debugging (#3925).
- Added the prelude functions `hash` (#3908) and `compare` (#3917).
- Added identity constructors for numeric types (#3848).
- Added `@env.rand` for obtaining platform entropy (#3689).

#### Changed

- Made trait-method promotions explicit with `extend` for built-in types (#3896) and tuples (#3898). Operators and the primary `compare`, `equal`, and `hash` methods remain available as methods; diagnostic and serialization helpers direct users to their traits or constructors (#3919).
- Unseeded `Rand` construction now uses platform entropy (#3689).

#### Deprecated

- Deprecated `@debug.to_repr` (#3925) and its prelude re-export (#3926) in favor of `Repr(x)`.
- Deprecated most concrete `default` methods in favor of literals or `Default::default()` through a trait bound (#3919).

#### Removed

- Removed deprecated tuple free functions; use tuple access or pattern matching (#3927).
- Removed `BigInt::asr` and `lsl`; use `BigInt::shr` and `shl` respectively (#3928).

### MoonBit Language Changes

#### Added

- Added streaming `lexscan` over synchronous and asynchronous lexical buffers.
- Added `guard!` for intentional panic-on-mismatch and labelled blocks that can return a value through `break label~ value`.
- Bitstring patterns support `v128le` for extracting 16 bytes as a `V128` value.

#### Changed

- **BREAKING**: Branches using `with` in or-patterns require parentheses, as in `Some(x) | (None with x = fallback)`. Default bindings can now use general expressions.

#### Deprecated

- Calling a trait method through a type parameter's dot syntax is deprecated unless it comes from the parameter's sole direct trait bound. Use the trait-qualified form to disambiguate.

## [0.10.4] - 2026-07-16

Compiler version: `v0.10.4+2cc641edf`.

### `moonbitlang/core` Changes

#### Added

- Added `Json::empty_object()` (#3798).
- Added `argparse` default-subcommand dispatch (#3780).
- `argparse` errors suggest similarly spelled subcommands (#3771).

#### Changed

- **BREAKING**: Prelude `assert_eq` and `assert_not_eq` now require `Debug` rather than `Show` for failure output (#3792).
- **BREAKING**: View operators no longer interpret negative indices as offsets from the end (#3789).

#### Removed

- Removed deprecated collection `T` aliases (#3795).
- Removed deprecated `IterResult`-based iterator APIs (#3801).

#### Fixed

- Environment variables, command-line arguments, and directory APIs handle Unicode correctly on Windows (#3741).

### MoonBit Language Changes

#### Added

- Added explicit trait-method promotion with `extend`, including public promotions and attributes controlling the promoted methods.
- Added `with` bindings in or-patterns to supply values missing from one branch.

#### Deprecated

- Deprecated calling a supertrait's method through a trait-object type's dot syntax; use the defining trait explicitly.

## [0.10.3] - 2026-07-06

Compiler version: `v0.10.3+16975d007`.

### `moonbitlang/core` Changes

#### Added

- Added the `List` constructor, retaining the deprecated `from_array` alias (#3756).
- Added type-named constructors for immutable `HashMap` (#3759), `HashSet` (#3760), `SortedMap` (#3761), and `SortedSet` (#3757), retaining deprecated `from_array` aliases.
- Added `Int16::lnot` and `UInt16::lnot` (#3740).

#### Changed

- Improved byte searching (#3710) and comparison (#3790).
- Improved immutable priority-queue construction (#3745).

#### Fixed

- Fixed immutable-vector concatenation producing invalid node sizes (#3751) or partially filled radix nodes (#3732).

### MoonBit Language Changes

#### Added

- Added `#export_name` for choosing a function's external symbol name in foreign-library packages.

#### Fixed

- Fixed generated type-parameter names when deriving implementations of traits with polymorphic methods.

## [0.10.2] - 2026-06-29

Compiler version: `v0.10.2+1bb3e16cf`.

### `moonbitlang/core` Changes

#### Added

- Added the experimental `v128` SIMD package, with backend intrinsics and portable fallback implementations (#3698).

#### Fixed

- JSON parsing rejects backticks in hexadecimal Unicode escapes (#3704).

### MoonBit Language Changes

#### Added

- Added explicit iterator literals and comprehensions using `[| ... |]`.
- Custom constructors can be defined for arbitrary types, extending support beyond structs.
- Array spreads accept conditional `if` expressions without an `else`, contributing no elements when the condition is false.

#### Deprecated

- Deprecated implicitly treating ordinary array literals as iterator literals based on the expected type; write `[| ... |]` explicitly.

## [0.10.1] - 2026-06-22

Compiler version: `v0.10.1+a46be2066`.

### `moonbitlang/core` Changes

#### Added

- Added `all` and `any` (#3684), plus `contains_code_unit` (#3685), to `String` and `StringView`.
- Added array/view `count` and `count_if`, plus `Iter::count_if` (#3686).
- Added `FixedArray::make_and_blit` and `UninitializedArray::make_and_blit` (#3564).
- Added `Bench()` (#3654) and `Test(...)` (#3655) constructors.

#### Changed

- Added template/interpolation writes to `StringBuilder` (#3683), `Buffer` (#3688), and `Logger` (#3694).

#### Fixed

- Corrected `cosh` for large arguments (#3690) and values near overflow (#3691).
- Corrected `sinh` at the overflow boundary (#3692).

### MoonBit Language Changes

#### Added

- Added interpolation in byte literals and byte-template writes, including `b"...\{value}"`.

#### Fixed

- Corrected `Int64`/`UInt64` constant-expression evaluation, including division of the minimum signed value by `-1`.

## [0.10.0] - 2026-06-09

Compiler version: `v0.10.0+e66899a54`.

### `moonbitlang/core` Changes

#### Added

- Added `String::code_units` and `StringView::code_units` (#3650).
- Added `@test.assert_raise` and `@test.expect_error` (#3653).

#### Changed

- Improved JSON number parsing (#3641).
- Improved hash-collection growth (#3621).

### MoonBit Language Changes

#### Added

- Trait methods can have their own type parameters and bounds; implementations can explicitly annotate those method-level type parameters.
- Extended template writes with conditional `<?` writes and added builder callbacks inside string interpolation.
- Added the experimental `V128` type.

#### Changed

- Comprehensions producing non-iterator values can perform `raise` and `async` effects.

#### Deprecated

- Deprecated `try?`; use an explicit `try ... catch` when converting errors to a result.

#### Removed

- **BREAKING**: Removed the old `fn new` constructor syntax; use `fn Type::Type(...)`.

## [0.9.3] - 2026-06-02

Compiler version: `v0.9.3+08f337e2c`.

### `moonbitlang/core` Changes

#### Added

- Added `lazy_list`, a memoized, re-traversable lazy sequence (#3553).
- Added `Lazy::peek` to inspect an already-computed value without forcing evaluation (#3579).
- Added `Buffer()` and its prelude export, plus explicit `Buffer::write_utf8` (#3614).
- Added `HashMap::update` (#3583).
- Added hash-map lookup by `BytesView`/`StringView` without allocating owned keys (#3586).
- Added `ReadOnlyArray::search_by` (#3604) and `rev_iter` (#3607).
- Added `ReadOnlyArray::filter` and `filter_map` (#3608).
- Added `ReadOnlyArray::chunks` and `windows` (#3609), plus `chunk_by` and `suffixes` (#3610).
- Added `ReadOnlyArray::strip_prefix` and `strip_suffix` (#3606).
- Added the `Hasher()` constructor; `Hasher::new` remains a deprecated alias (#3636).

#### Changed

- **BREAKING**: `repr` now uses `Debug` through the prelude export of `@debug.to_string` (#3580); removed the `Show`-based `@builtin.repr` (#3581).
- **BREAKING**: Mutable `SortedMap::keys` and `values` return iterators (#3591).
- **BREAKING**: Immutable `SortedMap::map`, `filter`, and `fold` now pass keys to their callbacks; the previous key-aware names remain deprecated aliases (#3592).
- Added error-polymorphic callbacks to `Array::rev_each` (#3596), `search_by` (#3597), `extract_if` (#3601), and `retain_map` (#3602).
- `join` accepts elements implementing `ToStringView` on `ReadOnlyArray` (#3598), `FixedArray` (#3600), and `Iter` (#3603).

#### Deprecated

- Deprecated implicit `Buffer` text writes through `Logger` and `write_object`, which use UTF-16LE. Use `write_utf8` or explicit encoders (#3615).

### MoonBit Language Changes

#### Added

- Trait method declarations accept the explicit `fn` keyword.

#### Removed

- **BREAKING**: Removed implicit implementation of method-less traits. Types now need an explicit `impl` even when the trait has no methods.

## [0.9.2] - 2026-05-12

Compiler version: `v0.9.2+bbe2b338f`.

### `moonbitlang/core` Changes

#### Added

- Added `lazy` for memoized computations (#3568).
- Added `range` for generic stepped iteration (#3492).
- Added iterator size hints (#3552).
- Added `update_or_default` for `Map` (#3515), `HashMap` (#3514), and mutable `SortedMap` (#3513).
- Added type-named constructors for `Map` and `Set` (#3501), `HashMap` (#3503), and `HashSet` (#3502).
- Added type-named constructors for deques, queues, sorted collections, immutable vectors, and mutable/immutable priority queues (#3504).
- Added the `StringBuilder()` constructor (#3573).

#### Changed

- **BREAKING**: `Show` outputs strings and characters without adding quotes or escapes. Use `Debug`, `debug_inspect`, or explicit escaping for diagnostic representations (#3575).

#### Deprecated

- Deprecated collection `Show` implementations in favor of `Debug` (#3574).
- Deprecated `new` constructors for `Map` and `Set` (#3511) and other collections (#3512) in favor of type-named constructors.
- Deprecated bytes-regex APIs (#3493).

### MoonBit Language Changes

#### Added

- Comprehensions can produce `Iter` values lazily.
- Added template writes with `<+`.

#### Deprecated

- Deprecated local type definitions inside functions in favor of top-level declarations.

## [0.9.1] - 2026-04-29

Compiler version: `v0.9.1+cd5b07232`.

### `moonbitlang/core` Changes

#### Added

- Added `ArrayView::strip_prefix` and `strip_suffix` (#3430).
- Added type-named constructors for `argparse` types, `Ref`, `Regex`, and JSON replacers (#3402).

#### Changed

- `BigInt::from_octets` accepts `BytesView` (#3461).
- Buffer byte-writing APIs accept `BytesView` (#3462).
- Prefix/suffix APIs accept views on `Array` (#3470), `FixedArray`, and `ReadOnlyArray` (#3471).
- **BREAKING**: `Array::strip_prefix` and `strip_suffix` return views rather than copied arrays (#3430).
- Assertion messages accept `StringView` (#3463).
- Iterator join separators accept `StringView` (#3459).

#### Deprecated

- Renamed view-to-owned conversions to `to_owned`, retaining deprecated aliases such as `ArrayView::to_array` and `BytesView::to_bytes` (#3454).

### MoonBit Language Changes

#### Added

- Added extensible enums with `extenum` and constructors that can be defined in other packages.
- Added the simpler custom-constructor form `fn Type::Type(...)`, replacing the previous `fn new` syntax.

#### Deprecated

- Deprecated the previous custom-constructor syntax in favor of type-named constructors.

## [0.9.0] - 2026-04-20

Compiler version: `v0.9.0+69d374a17`.

### `moonbitlang/core` Changes

#### Added

- Added `immut/vector`, a persistent vector replacing `immut/array` (#3380).
- Added `ArrayView::chunks`, `chunk_by`, and `windows` (#3432).
- Added `ArrayView::rev` (#3427), `rev_each`, and `rev_eachi` (#3431).
- Added `ArrayView::filter_map` (#3428) and `search_by` (#3429).
- Added case-insensitive ASCII string comparisons (#3418).
- Added optional `get_view` for strings and bytes (#3437).
- Added `Debug`-based assertions in `test` (#3424).
- Added vector `singleton` (#3422), plus `contains`, `filter`, and `rev` (#3423).

#### Changed

- `SourceLoc` filenames are relative to the module rather than the package (#3343).

#### Deprecated

- Deprecated `immut/array` in favor of `immut/vector` (#3380).

#### Fixed

- Corrected negative `BigInt` bit lengths (#3419) and right shifts (#3420).
- Corrected `BigInt` modular exponentiation for negative bases and modulus one (#3421).

### MoonBit Language Changes

#### Added

- Added the regex match expression `value =~ re"..."`, with regex literals stabilized in the [April release notes](https://www.moonbitlang.com/updates/2026/04/07/index).
- Added constructor aliases through `#alias` on structs, tuple structs, and single-constructor error types.
- Added `ReadOnlyArray` and array comprehensions, including functional `for` loops in comprehensions.

#### Changed

- **BREAKING**: JavaScript `Int64` and `UInt64` use JavaScript `BigInt` values instead of the previous representation.
- Derived trait implementations no longer allow overriding their default methods.

#### Deprecated

- Deprecated `derive(Show)` in favor of `derive(Debug)`, and `loop` syntax in favor of functional `for` loops.
- Deprecated overloading byte and bytes literals.

#### Removed

- **BREAKING**: Removed legacy newtype declarations; use tuple-struct syntax such as `struct Wrapper(Int)`.

## [0.8.4] - 2026-03-30

Compiler version: `v0.8.4+4d98d95d4`.

### `moonbitlang/core` Changes

#### Added

- Added environment-variable get/set/unset APIs (#3227).
- Added `debug_assert` (#3261).
- Added `Iter::zip` (#3283).
- Added `Char::escape` and optional quote control for string escaping (#3267).
- Added `StringView::escape` (#3294).
- Added reverse string splitting helpers (#3326).
- Added `HashSet::retain` (#3318).
- Added `SortedMap::get_or_init` and `get_or_default` (#3316).
- Added comparisons between `BigInt` and unsigned integers (#3265).
- Added Boolean and numeric parsing functions in `string` (#3309).

#### Deprecated

- Deprecated `strconv` parsing APIs in favor of `string` (#3309).

#### Fixed

- Corrected immutable sorted-set subset checks (#3323).
- Prevented `List::scan_left` from evaluating callbacks twice (#3335).
- Made priority-queue copying stack-safe (#3332).

### MoonBit Language Changes

#### Added

- Added reverse pipelines with `<|` and the `value |> _ => { ... }` pipeline form.
- Regex constants support concatenation with `+`, alternation with `|`, and references from regex patterns.
- Added `#must_implement_one` to require an implementation to provide at least one method from a specified group, even when defaults exist.
- Added `#deprecated` on trait implementations.

#### Changed

- **BREAKING**: Native/Wasm FFI functions returning `Unit` now use a void-return ABI.
- Missing FFI lifetime annotations are errors by default.

## [0.8.3] - 2026-03-10

Compiler version: `v0.8.3+cd28f524e`.

### `moonbitlang/core` Changes

#### Added

- Added `argparse` with flags, options, positionals, subcommands, groups, help/version output, and environment-backed values (#3213).
- Added the public `Regex` API and its prelude export (#3222).
- Added numeric `min`, `max`, and `clamp` helpers (#3243).
- Added floating-point `clamp` and `lerp` (#3241).
- Added string `split_once`, `before`, and `after` helpers (#3211).

#### Changed

- **BREAKING**: `String::sub` and `StringView::sub` panic on invalid indices instead of raising `CreatingViewError`; that error type has been removed (#3229).

### MoonBit Language Changes

#### Added

- Added regex literal expressions with `re"..."`.
- Added extra state variables and `where` clauses to `for ... in` loops.
- String constants support concatenation and interpolation.
- `fn main raise { ... }` permits error-raising operations in the entry point.
- Added the `missing_doc` warning for undocumented public definitions.

#### Changed

- `#alias` and `#as_free_fn` aliases no longer inherit deprecation automatically; their attributes can be controlled independently.

#### Deprecated

- Deprecated implicit implementations of method-less traits and `for { ... }` infinite loops.

See the [March release notes](https://www.moonbitlang.com/updates/2026/03/10/index) for language examples.

## [0.8.2] - 2026-02-25

Compiler version: `v0.8.2+8cca5f22a`.

### `moonbitlang/core` Changes

The bundled MoonBit sources and package interfaces are unchanged from 0.8.1.

### MoonBit Language Changes

#### Fixed

- Fixed local-type export handling and inconsistent Wasm-GC FFI stub type checking.

## [0.8.1] - 2026-02-10

Compiler version: `v0.8.1+bd827dc85`.

### `moonbitlang/core` Changes

#### Added

- Added `Debug` trait with `derive(Debug)` support, including `ignore=[..]` configuration for non-debuggable nested types (#3111)
- Added new `moonbitlang/async` APIs including `@process.spawn`, advisory file locking, `@fs.tmpdir`, `@async.all`, and `@async.any`

#### Changed

- `@json.inspect` has been migrated to `json_inspect` (#3143)

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

Compiler version: `v0.7.1+c0b22a8b0`.

### `moonbitlang/core` Changes

#### Added

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

- Export `FromJson` trait from `@json` package in prelude for easier JSON deserialization (#3042)

#### Changed

- **BREAKING**: `String::at` and `StringView::at` now return `UInt16` instead of `Int` and are the primary methods for accessing UTF-16 code units (#3040)
- **BREAKING**: `String::code_unit_at` and `StringView::code_unit_at` are now aliases for `at` instead of being separate methods (#3040)
- `String::trim`, `String::trim_start`, `String::trim_end` and their `StringView` counterparts now accept optional `chars` parameter with default whitespace characters (#3044)

#### Deprecated

- `String::charcode_at` (previously named `at`) is now deprecated, use `String::at` which returns `UInt16` (#3040)
- `String::trim_space` and `StringView::trim_space` are now deprecated, use `trim()` with default whitespace characters instead (#3044)

#### Removed

#### Fixed

### MoonBit Language Changes

#### Added

- Introduced the `#declaration_only` attribute for function, method, and type declarations. These declarations can be called or tested immediately but require a concrete implementation to function at runtime. Accessing a declaration without an implementation will result in a runtime crash.

- The compiler can now report unused warning on async annotations when the function is actually synchronous

- `moonfmt` will automatically migrate `mbt test`/`mbt test(async)` code blocks in Markdown to `mbt check`.

#### Changed

- The default value of optional arguments can now raise error or perform async operations, as long as the function itself allow these effects

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

Compiler version: `v0.6.33+b989ba000`.

### `moonbitlang/core` Changes

#### Added

- Added `MutArrayView` as the unified mutable slice type (#2880), with a prelude export (#3016)
- Added `#module("...")` support for importing third-party JS modules

#### Changed

- `ArrayView` became immutable (#2754), with mutation moved to `MutArrayView` (#2880); moved `ArrayView` into `builtin` for shared use across array types (#3015)
- `string[x]` now returns `UInt16` (migrate to `code_unit_at`) (#2972)

#### Deprecated

- Deprecated `Container::of` in favor of `Type::from_array` (#2849), whose input now accepts `ArrayView[_]` (#2847)
- Renamed `@test.T` to `@test.Test` (#2815)
- Renamed `@priority_queue.T` to `@priorityqueue.PriorityQueue` (#3002)

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

Compiler version: `v0.6.30+07d9d2445`.

### `moonbitlang/core` Changes

#### Added

- Added external iterator type support (`Iterator`) with `for .. in` integration via `.iterator()`/`.iterator2()` (#2851)

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

Compiler version: `v0.6.29+9037370fc`.

### `moonbitlang/core` Changes

#### Added

- Added per-process randomized hashing on JavaScript to mitigate HashDoS risks (#2783)

#### Changed

- `ArrayView` became immutable (#2754)

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

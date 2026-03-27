# Prelude

The prelude package re-exports commonly used types, traits, and functions from the standard library so they are available without explicit imports.

## Re-exported Types

Core types available in every MoonBit program:

- `Array`, `ArrayView`, `MutArrayView`, `UninitializedArray` — array types
- `Map` — ordered map
- `Set` — ordered set
- `BigInt` — arbitrary-precision integers
- `Iter`, `Iter2` — iterators
- `Json` — JSON values
- `StringBuilder` — efficient string building
- `Hasher` — hash computation
- `Ref` — mutable reference cell
- `Regex` — regular expressions
- `Repr` — debug representation
- `Failure`, `InspectError`, `SnapshotError` — error types
- `SourceLoc`, `ArgsLoc` — source location info

## Re-exported Traits

- `Eq`, `Compare`, `Hash` — equality, ordering, hashing
- `Show`, `Debug` — display and debug output
- `Default` — default values
- `ToJson`, `FromJson` — JSON serialization
- `Logger` — logging interface
- `Add`, `Sub`, `Mul`, `Div`, `Mod`, `Neg` — arithmetic
- `Shl`, `Shr`, `BitAnd`, `BitOr`, `BitXOr` — bitwise operations

## Re-exported Functions

- `println`, `abort`, `panic`, `fail` — output and error handling
- `inspect`, `debug_inspect`, `debug`, `to_repr` — debugging
- `assert_eq`, `assert_not_eq`, `assert_true`, `assert_false`, `debug_assert` — assertions
- `ignore`, `physical_equal` — utilities
- `json_inspect` — JSON-based snapshot testing

## Re-exported Constants

- `null` — JSON null value

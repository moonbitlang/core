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
- `BytesRegex` — regular expressions over bytes
- `Lexbuf`, `AsyncLexbuf` — streaming text input for `lexscan`
- `BytesLexbuf`, `AsyncBytesLexbuf` — streaming byte buffers
- `Repr` — debug representation
- `Failure`, `InspectError`, `SnapshotError` — error types
- `SourceLoc`, `ArgsLoc` — source location info

```mbt check
///|
test "Set constructor from prelude" {
  let set = Set([1, 2, 3, 4])
  inspect(set.length(), content="4")
  inspect(set.contains(3), content="true")
}
```

## Streaming input for `lexscan`

Construct a lexbuf with a callback that returns the next chunk, or `None` at
EOF. Empty chunks are ignored, and tokens may span chunk boundaries.
The existing `from_fn` spelling remains available as an alias.

```mbt check
///|
test "Lexbuf constructor from prelude" {
  let chunks = ["hel", "lo world"].iter()
  let input = Lexbuf(() => chunks.next())
  let words = []
  for ;; {
    lexscan input {
      re"^[a-z]+" as word => words.push(word.to_owned())
      re"^ +" => ()
      re"^$" => break
      _ => fail("unexpected character")
    }
  }
  debug_inspect(words, content="[\"hello\", \"world\"]")
}
```

For an asynchronous text reader, use `AsyncLexbuf(() => reader.read())`.
For a binary reader, use `AsyncBytesLexbuf(() => reader.read())`.
The buffer takes over the remaining stream, so do not read directly from the
reader after scanning begins. Source errors propagate; do not reuse an async
lexbuf after a scan fails or is cancelled during a refill.

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
- `inspect`, `debug_inspect`, `debug` — debugging
- `@test.assert_eq`, `@test.assert_not_eq`, `assert_true`, `assert_false`, `debug_assert` — assertions
- `ignore`, `physical_equal` — utilities
- `json_inspect` — JSON-based snapshot testing

## Re-exported Constants

- `null` — JSON null value

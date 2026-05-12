# Debug

Structural debugging and pretty-printing for MoonBit values. Provides the `Debug` trait, a structural representation type (`Repr`), and utilities for inspecting values in tests.

## Migrate from Show

We are migrating from `Show` to `Debug` for most composed values, such as arrays,
maps, and tuples. `Debug` is designed to provide a better debugging experience:
it produces structural, indented, human-readable information for data
structures. The `Show` trait will focus on producing specialized strings, such
as JSON and XML.

**Breaking change: The implementations of `Show::output` for `String` and `Char` now produce raw
text instead of quoted, escaped text.**

To migrate, use `Debug` for test snapshots, diagnostics, and logging-style
output. Some common cases:

- Use `derive(Debug)` for custom types. Implement `Show` manually only for non-debug
  textual formats such as JSON, XML, or domain-specific display text.
- Use `debug_inspect(value, content=...)` instead of `inspect(value, content=...)`.
- Use `@debug.assert_eq(a, b)` instead of `assert_eq(a, b)`.
- Use `\{to_repr(value)}` in string interpolation instead of `\{value}` for composed values.
- Use `@debug.to_string(value)` instead of `value.to_string()` for composed values,
  when the string is only used for debugging.

## The Debug Trait

The `Debug` trait converts values to a structural `Repr` for pretty-printing. It is implemented for all primitive types, tuples (up to 22 elements), and standard collection types.

```mbt check
///|
test "debug" {
  @debug.debug_inspect(42, content="42")
  @debug.debug_inspect("hello", content="\"hello\"")
  @debug.debug_inspect((1, true), content="(1, true)")
  @debug.debug_inspect([1, 2, 3], content="[1, 2, 3]")
  @debug.debug_inspect(Some(42), content="Some(42)")
}
```

## Converting to String

Use `to_string` to get the debug string representation of any value implementing `Debug`:

```mbt check
///|
test "to_string" {
  let s = @debug.to_string([1, 2, 3])
  inspect(s, content="[1, 2, 3]")
}
```

Use `to_repr` in string interpolation:

```mbt check
///|
test "string interpolation" {
  let arr = [1, 2, 3]
  inspect(
    "arr: \{to_repr(arr)}",
    content=(
      #|arr: [1, 2, 3]
    ),
  )
}
```

## Printing

Use `debug` to print a value's debug representation to standard output:

```mbt check
///|
test "print" {
  if false {
    @debug.debug(42) // prints: 42
  }
}
```

## Inspecting in Tests

`debug_inspect` compares a value's pretty-printed `Repr` against expected content. It raises `InspectError` on mismatch, making it useful for snapshot testing:

```mbt check
///|
test "debug_inspect" {
  @debug.debug_inspect(
    { "key": 42 },
    content=(
      #|{ "key": 42 }
    ),
  )
}
```

## Collection Support

`Debug` is implemented for all standard collections:

```mbt check
///|
test "collections" {
  let q = @queue.from_array([1, 2, 3])
  @debug.debug_inspect(q, content="<Queue: [1, 2, 3]>")
  let dq = @deque.from_array([1, 2])
  @debug.debug_inspect(dq, content="<Deque: [1, 2]>")
}
```

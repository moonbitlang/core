# Debug

Structural debugging and pretty-printing for MoonBit values. Provides the `Debug` trait, a structural representation type (`Repr`), and utilities for inspecting values in tests.

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

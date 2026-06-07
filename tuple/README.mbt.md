# Tuple

Tuples are fixed-size collections of elements of different types. This package provides `Default` and `Arbitrary` trait implementations for tuples of up to 16 elements.

## Create

Create tuples using literal syntax:

```mbt check
///|
test {
  let pair = (1, "hello")
  let triple = (1, 2.0, true)
  debug_inspect(pair, content="(1, \"hello\")")
  debug_inspect(triple, content="(1, 2, true)")
}
```

## Access

Access elements using dot notation or pattern matching:

```mbt check
///|
test {
  let tuple = (1, "hello", true)
  // Dot access
  @test.assert_eq(tuple.0, 1)
  @test.assert_eq(tuple.1, "hello")
  // Pattern matching
  let (a, b, c) = tuple
  @test.assert_eq(a, 1)
  @test.assert_eq(b, "hello")
  @test.assert_eq(c, true)
}
```

## Default Values

Tuples implement `Default` when all element types do (up to 16 elements):

```mbt check
///|
test {
  let pair : (Int, String) = Default::default()
  debug_inspect(pair, content="(0, \"\")")
  let triple : (Int, Bool, Double) = Default::default()
  debug_inspect(triple, content="(0, false, 0)")
}
```

## Transformation

Transform tuples using the pipe operator and closures:

```mbt check
///|
test {
  let tuple = (1, 2)
  let swapped = tuple |> pair => { (pair.1, pair.0) }
  debug_inspect(swapped, content="(2, 1)")
  let mapped = tuple |> pair => { (pair.0 * 2, pair.1 + 10) }
  debug_inspect(mapped, content="(2, 12)")
}
```

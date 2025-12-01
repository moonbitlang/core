# `cmp`

This package provides utility functions for comparing values and the `Reverse` newtype wrapper for reversing comparison order.

## Generic Comparison Functions

The library provides generic comparison functions that work with any type implementing the `Compare` trait:

```mbt check
///|
test "generic comparison" {
  // Works with numbers
  inspect(@cmp.maximum(3, 4), content="4")
  inspect(@cmp.minimum(3, 4), content="3")
  inspect(@cmp.minmax(3, 4), content="(3, 4)")
}
```

## Reverse Comparison Order

The `@cmp.Reverse[T]` newtype wrapper reverses the comparison order of any type implementing `Compare`. This is particularly useful for:

- Creating min-heaps from max-heap data structures
- Sorting in descending order
- Reversing the priority in priority queues

```mbt check
///|
test "reverse comparison" {
  let a = @cmp.Reverse(1)
  let b = @cmp.Reverse(2)

  // Normal comparison: 1 < 2, but reversed: 1 > 2
  inspect(a.compare(b), content="1")
  inspect(b.compare(a), content="-1")

  // Can be used with generic comparison functions
  inspect(@cmp.maximum(a, b), content="Reverse(1)")
  inspect(@cmp.minimum(a, b), content="Reverse(2)")
}
```

### Using Reverse with Collections

`@cmp.Reverse` can be used with sorted collections to change their ordering:

```mbt check
///|
test "reverse with arrays" {
  // Create an array with reversed integers for descending sort
  let arr = [@cmp.Reverse(3), @cmp.Reverse(1), @cmp.Reverse(4), @cmp.Reverse(2)]
  // When sorted, the array will be in descending order of the wrapped values
  inspect(arr[0], content="Reverse(3)") // Access first element
}
```

## Comparison by Key

With `@cmp.maximum_by_key()` and `@cmp.minimum_by_key()`, it is possible to compare values based on arbitrary keys derived from the them. This is particularly useful when you need to compare complex objects based on some specific aspect or field.

```mbt check
///|
test "cmp_by_key" {
  struct Person {
    name : String
    age : Int
  } derive(Show)

  // Compare strings by their length
  let s1 = "hello"
  let s2 = "hi"
  let longer = @cmp.maximum_by_key(s1, s2, String::length)
  inspect(longer, content="hello")

  // Compare structs by a specific field
  let alice = { name: "Alice", age: 25 }
  let bob = { name: "Bob", age: 30 }
  let younger = @cmp.minimum_by_key(alice, bob, p => p.age)
  inspect(younger, content="{name: \"Alice\", age: 25}")

  // When keys are equal, the first argument is considered the minimum
  let p1 = ("first", 1)
  let p2 = ("second", 1)
  let snd = (p : (_, _)) => p.1
  assert_eq(@cmp.minimum_by_key(p1, p2, snd), p1)
  assert_eq(@cmp.maximum_by_key(p1, p2, snd), p2)
}
```

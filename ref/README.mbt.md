# `ref`

This package provides functionality for working with mutable references, allowing you to create sharable mutable values that can be modified safely.

## Creating and Accessing References

References can be created using `@ref.new()`. The reference value can be accessed through the `val` field:

```moonbit
///|
test "creating and accessing refs" {
  let r1 = @ref.new(42)
  inspect(r1.val, content="42")
}
```

## Updating Reference Values

The `update` function allows modifying the contained value using a transformation function:

```moonbit
///|
test "updating refs" {
  let counter = @ref.new(0)
  counter.update(x => x + 1)
  inspect(counter.val, content="1")
  counter.update(x => x * 2)
  inspect(counter.val, content="2")
}
```

## Mapping References

The `map` function transforms a reference while preserving the reference wrapper:

```moonbit
///|
test "mapping refs" {
  let num = @ref.new(10)
  let doubled = num.map(x => x * 2)
  inspect(doubled.val, content="20")
  let squared = num.map(x => x * x)
  inspect(squared.val, content="100")
}
```

## Swapping Reference Values

You can exchange the values of two references using the `swap` function:

```moonbit
///|
test "swapping refs" {
  let r1 = @ref.new("first")
  let r2 = @ref.new("second")
  @ref.swap(r1, r2)
  inspect(r1.val, content="second")
  inspect(r2.val, content="first")
}
```

## Temporary Value Protection

The `protect` function temporarily sets a reference to a value and restores it after executing a block:

```moonbit
///|
test "protected updates" {
  let state = @ref.new(100)
  let mut middle = 0
  let result = state.protect(50, () => {
    middle = state.val
    42
  })
  inspect(middle, content="50")
  inspect(result, content="42")
  inspect(state.val, content="100")
}
```

This is useful for temporarily modifying state that needs to be restored afterwards.

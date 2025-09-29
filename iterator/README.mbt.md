# Iterator

External iterator implementation for MoonBit.

## Overview

The `iterator` package provides an external iterator type `Iterator[A]` that allows pull-based iteration. Unlike internal iterators (like `Iter[T]`), external iterators give you control over when to get the next element by calling `next()`.

## Features

- **Pull-based iteration**: Call `next()` to get elements when you need them
- **Lazy evaluation**: Combinators like `map()` and `filter()` create new iterators without processing elements until consumed
- **Method chaining**: Chain operations like `iter.filter(...).map(...)`
- **Memory efficient**: Uses closures to maintain state without allocating intermediate collections

## Basic Usage

```moonbit
///|
test {
  // Create an iterator from a range
  let iter = Iterator::unfold(1, fn(n) {
    if n <= 5 {
      Some((n, n + 1))
    } else {
      None
    }
  })

  // Use the iterator
  assert_eq(iter.next(), Some(1))
  assert_eq(iter.next(), Some(2))
  assert_eq(iter.next(), Some(3))
}
```

## Iterator Creation

- `Iterator::empty()` - Create an empty iterator
- `Iterator::singleton(value)` - Create an iterator with a single element
- `Iterator::unfold(init, f)` - Create an iterator from a function and initial state

## Iterator Operations

- `iter.next()` - Get the next element
- `iter.map(f)` - Transform each element
- `iter.filter(predicate)` - Filter elements
- `iter.fold(init, f)` - Fold into a single value
- `iter.each(f)` - Apply a function to each element
- `iter.count()` - Count elements
- `iter.find(predicate)` - Find first matching element
- `iter.any(predicate)` - Check if any element matches
- `iter.all(predicate)` - Check if all elements match

## Integration with List

The `list` package provides integration with iterators:

```moonbit
///|
test {
  // Convert List to Iterator
  let ls = @list.List::of([1, 2, 3, 4, 5])
  let iter = ls.into_iterator()

  // Process with iterator methods
  let result = iter.filter(fn(x) { x % 2 == 0 }).map(fn(x) { x * 2 })

  // Collect back to List
  let final_list = @list.collect_from_iterator(result)
  // final_list = @list.List::of([4, 8])
}
```

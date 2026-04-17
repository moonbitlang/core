# List

The `List` package provides an immutable linked list data structure with a variety of utility functions for functional programming.

## Table of Contents

1. Overview  
2. Performance  
3. Usage  
   - Create  
   - Basic Operations  
   - Access Elements  
   - Iteration  
   - Advanced Operations  
   - Conversion  
   - Equality  
4. Error Handling Best Practices  
5. Implementation Notes  
6. Comparison with Other Collections  

---

## Overview

`List` is a functional, immutable data structure that supports efficient traversal, transformation, and manipulation. It is particularly useful for recursive algorithms and scenarios where immutability is required.

---

## Performance

- **prepend**: O(1)  
- **length**: O(n)  
- **map/filter**: O(n)  
- **concatenate**: O(n)  
- **reverse**: O(n)  
- **nth**: O(n)  
- **sort**: O(n log n)  
- **flatten**: O(n * m), where `m` is the average inner list length  
- **space complexity**: O(n)  

---

## Usage

### Create

You can create an empty list or a list from an array.

```mbt check
///|
test {
  let empty_list : @list.List[Int] = @list.new()
  assert_true(empty_list.is_empty())
  let list = @list.from_array([1, 2, 3, 4, 5])
  assert_eq(list, @list.from_array([1, 2, 3, 4, 5]))
}
```

---

### Basic Operations

#### Prepend

Add an element to the beginning of the list.

```mbt check
///|
test {
  let list = @list.from_array([2, 3, 4, 5]).prepend(1)
  assert_eq(list, @list.from_array([1, 2, 3, 4, 5]))
}
```

#### Length

Get the number of elements in the list.

```mbt check
///|
test {
  let list = @list.from_array([1, 2, 3, 4, 5])
  assert_eq(list.length(), 5)
}
```

#### Check if Empty

Determine if the list is empty.

```mbt check
///|
test {
  let empty_list : @list.List[Int] = @list.new()
  assert_eq(empty_list.is_empty(), true)
}
```

---

### Access Elements

#### Head

Get the first element of the list as an `Option`.

```mbt check
///|
test {
  let list = @list.from_array([1, 2, 3, 4, 5])
  debug_inspect(list.head(), content="Some(1)")
}
```

#### Tail

Get the list without its first element.

```mbt check
///|
test {
  let list = @list.from_array([1, 2, 3, 4, 5])
  assert_eq(list.unsafe_tail(), @list.from_array([2, 3, 4, 5]))
}
```

#### Nth Element

Get the nth element of the list as an `Option`.

```mbt check
///|
test {
  let list = @list.from_array([1, 2, 3, 4, 5])
  debug_inspect(list.nth(2), content="Some(3)")
}
```

---

### Iteration

#### Each

Iterate over the elements of the list.

```mbt check
///|
test {
  let arr = []
  @list.from_array([1, 2, 3, 4, 5]).each(x => arr.push(x))
  assert_eq(arr, [1, 2, 3, 4, 5])
}
```

#### Map

Transform each element of the list.

```mbt check
///|
test {
  let list = @list.from_array([1, 2, 3, 4, 5]).map(x => x * 2)
  assert_eq(list, @list.from_array([2, 4, 6, 8, 10]))
}
```

#### Filter & Filter Map

`filter` keeps elements matching a predicate. `filter_map` transforms and filters in one pass.

```mbt check
///|
test {
  let list = @list.from_array([1, 2, 3, 4, 5])
  assert_eq(list.filter(fn(x) { x % 2 == 0 }), @list.from_array([2, 4]))
  let fm = list.filter_map(fn(x) { if x > 3 { Some(x * 10) } else { None } })
  assert_eq(fm, @list.from_array([40, 50]))
}
```

#### Fold

`fold` reduces from left to right. `foldi` includes the index.

```mbt check
///|
test {
  let list = @list.from_array([1, 2, 3])
  assert_eq(list.fold(init=0, fn(acc, x) { acc + x }), 6)
  let indexed = list.foldi(init="", fn(i, acc, x) {
    acc + i.to_string() + ":" + x.to_string() + " "
  })
  inspect(indexed, content="0:1 1:2 2:3 ")
}
```

#### Find, Any, All, Contains

```mbt check
///|
test {
  let list = @list.from_array([1, 2, 3, 4, 5])
  debug_inspect(list.find(fn(x) { x > 3 }), content="Some(4)")
  debug_inspect(list.find_index(fn(x) { x == 3 }), content="Some(2)")
  assert_eq(list.any(fn(x) { x > 4 }), true)
  assert_eq(list.all(fn(x) { x > 0 }), true)
  assert_eq(list.contains(3), true)
  assert_eq(list.contains(9), false)
}
```

#### Flat Map

```mbt check
///|
test {
  let list = @list.from_array([1, 2, 3])
  let result = list.flat_map(fn(x) { @list.from_array([x, x * 10]) })
  assert_eq(result, @list.from_array([1, 10, 2, 20, 3, 30]))
}
```

---

### Advanced Operations

#### Take & Drop

`take(n)` keeps the first `n` elements. `drop(n)` skips them. `take_while` and `drop_while` use a predicate.

```mbt check
///|
test {
  let list = @list.from_array([1, 2, 3, 4, 5])
  assert_eq(list.take(3), @list.from_array([1, 2, 3]))
  assert_eq(list.drop(3), @list.from_array([4, 5]))
  assert_eq(list.take_while(fn(x) { x < 4 }), @list.from_array([1, 2, 3]))
  assert_eq(list.drop_while(fn(x) { x < 4 }), @list.from_array([4, 5]))
}
```

#### Remove

`remove(x)` removes the first occurrence. `remove_at(i)` removes by index.

```mbt check
///|
test {
  let list = @list.from_array([1, 2, 3, 2, 1])
  assert_eq(list.remove(2), @list.from_array([1, 3, 2, 1]))
  assert_eq(list.remove_at(0), @list.from_array([2, 3, 2, 1]))
}
```

#### Last, Minimum, Maximum

```mbt check
///|
test {
  let list = @list.from_array([3, 1, 4, 1, 5])
  debug_inspect(list.last(), content="Some(5)")
  debug_inspect(list.minimum(), content="Some(1)")
  debug_inspect(list.maximum(), content="Some(5)")
}
```

#### Reverse

Reverse the list.

```mbt check
///|
test {
  let list = @list.from_array([1, 2, 3, 4, 5]).rev()
  assert_eq(list, @list.from_array([5, 4, 3, 2, 1]))
}
```

#### Concatenate

Concatenate two lists.

```mbt check
///|
test {
  let list = @list.from_array([1, 2, 3]).concat(@list.from_array([4, 5]))
  assert_eq(list, @list.from_array([1, 2, 3, 4, 5]))
}
```

#### Flatten

Flatten a list of lists.

```mbt check
///|
test {
  let list = @list.from_array([
    @list.from_array([1, 2]),
    @list.from_array([3, 4]),
  ]).flatten()
  assert_eq(list, @list.from_array([1, 2, 3, 4]))
}
```

#### Sort

Sort the list in ascending order.

```mbt check
///|
test {
  let list = @list.from_array([3, 1, 4, 1, 5, 9]).sort()
  assert_eq(list, @list.from_array([1, 1, 3, 4, 5, 9]))
}
```

#### Intersperse & Intercalate

`intersperse` inserts a separator between every pair of elements. `intercalate` joins a list of lists with a separator list.

```mbt check
///|
test {
  let list = @list.from_array([1, 2, 3])
  assert_eq(list.intersperse(0), @list.from_array([1, 0, 2, 0, 3]))
  let nested = @list.from_array([
    @list.from_array([1, 2]),
    @list.from_array([3, 4]),
    @list.from_array([5]),
  ])
  let sep = @list.from_array([0])
  assert_eq(nested.intercalate(sep), @list.from_array([1, 2, 0, 3, 4, 0, 5]))
}
```

#### Zip & Unzip

```mbt check
///|
test {
  let a = @list.from_array([1, 2, 3])
  let b = @list.from_array(["a", "b", "c"])
  let zipped = @list.zip(a, b)
  assert_eq(zipped, @list.from_array([(1, "a"), (2, "b"), (3, "c")]))
  let (xs, ys) = zipped.unzip()
  assert_eq(xs, @list.from_array([1, 2, 3]))
  assert_eq(ys, @list.from_array(["a", "b", "c"]))
}
```

#### Scan

`scan_left` produces a list of successive fold results. `scan_right` does the same from right to left.

```mbt check
///|
test {
  let list = @list.from_array([1, 2, 3])
  assert_eq(
    list.scan_left(fn(acc, x) { acc + x }, init=0),
    @list.from_array([0, 1, 3, 6]),
  )
}
```

#### Prefix & Suffix

```mbt check
///|
test {
  let list = @list.from_array([1, 2, 3, 4, 5])
  assert_eq(list.is_prefix(@list.from_array([1, 2, 3])), true)
  assert_eq(list.is_suffix(@list.from_array([4, 5])), true)
}
```

#### Lookup

Look up a value in an association list (list of key-value pairs):

```mbt check
///|
test {
  let assoc = @list.from_array([("a", 1), ("b", 2), ("c", 3)])
  debug_inspect(assoc.lookup("b"), content="Some(2)")
  debug_inspect(assoc.lookup("z"), content="None")
}
```

#### Unfold

Build a list from a seed value. `unfold` produces elements in order; `rev_unfold` in reverse.

```mbt check
///|
test {
  let list = @list.unfold(init=1, fn(n) {
    if n > 5 {
      None
    } else {
      Some((n, n + 1))
    }
  })
  assert_eq(list, @list.from_array([1, 2, 3, 4, 5]))
}
```

---

### Iterators

`iter()` returns an `Iter`. `from_iter()` constructs a list from an iterator.

```mbt check
///|
test {
  let list = @list.from_array([1, 2, 3])
  inspect(list.iter(), content="[1, 2, 3]")
  let list2 = @list.from_iter([4, 5, 6].iter())
  assert_eq(list2, @list.from_array([4, 5, 6]))
}
```

---

### Conversion

#### To Array

Convert a list to an array.

```mbt check
///|
test {
  let list = @list.from_array([1, 2, 3, 4, 5])
  assert_eq(list.to_array(), [1, 2, 3, 4, 5])
}
```

#### From Array

Create a list from an array.

```mbt check
///|
test {
  let list = @list.from_array([1, 2, 3, 4, 5])
  assert_eq(list, @list.from_array([1, 2, 3, 4, 5]))
}
```

---

### Equality

Lists with the same elements in the same order are considered equal.

```mbt check
///|
test {
  let list1 = @list.from_array([1, 2, 3])
  let list2 = @list.from_array([1, 2, 3])
  assert_eq(list1 == list2, true)
}
```

---

## Error Handling Best Practices

When accessing elements that might not exist, use pattern matching for safety:

```mbt check
///|
fn safe_head(list : @list.List[Int]) -> Int {
  match list.head() {
    Some(value) => value
    None => 0 // Default value
  }
}

///|
test {
  let list = @list.from_array([1, 2, 3])
  assert_eq(safe_head(list), 1)
  let empty_list : @list.List[Int] = @list.new()
  assert_eq(safe_head(empty_list), 0)
}
```

### Additional Error Cases

- **`nth()` on an empty list or out-of-bounds index**: Returns `None`.  
- **`tail()` on an empty list**: Returns `Empty`.  
- **`sort()` with non-comparable elements**: Throws a runtime error.  

---

## Implementation Notes

The `List` is implemented as a singly linked list. Operations like `prepend` and `head` are O(1), while operations like `length` and `map` are O(n).

Key properties of the implementation:
- Immutable by design
- Recursive-friendly
- Optimized for functional programming patterns

---

## Comparison with Other Collections

- **@array.T**: Provides O(1) random access but is mutable; use when random access is required.  
- **@list.T**: Immutable and optimized for recursive operations; use when immutability and functional patterns are required.  

Choose `List` when you need:
- Immutable data structures  
- Efficient prepend operations  
- Functional programming patterns  

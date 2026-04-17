# Immutable Vector

An immutable (persistent) vector providing efficient random access, update, and append operations. Similar to Clojure's persistent vector, it uses a wide branching tree (branching factor 32) with a tail buffer to achieve near-constant-time operations on the right end.

This package replaces the deprecated `immut/array` package with a more efficient tail-backed layout.

## Overview

`Vector[A]` is a persistent data structure -- all "modification" operations return a new vector, leaving the original unchanged. Internally it stores elements in a 32-way trie with a separate tail buffer for the rightmost chunk, which makes `push` and `pop` effectively O(1) amortized.

## Performance

- **push / pop**: Effectively O(1) amortized (O(log32 n) worst case)
- **get / set**: O(log32 n) -- at most 7 levels for billions of elements
- **concat**: O(log n)
- **split / slice / take / drop**: O(log n)
- **iter / each / fold / map**: O(n)
- **Space complexity**: O(n), with structural sharing between versions

## Usage

### Create

Create an empty vector with `new()`, or construct one from an array or iterator.

```mbt check
///|
test {
  let v1 : @vector.Vector[Int] = @vector.new()
  assert_eq(v1.length(), 0)
  let v2 = @vector.from_array([1, 2, 3, 4, 5])
  assert_eq(v2.length(), 5)
  let v3 = @vector.from_iter((1).until(5))
  assert_eq(v3.to_array(), [1, 2, 3, 4])
}
```

Use `make()` to create a vector filled with a value, or `makei()` to generate values from a function.

```mbt check
///|
test {
  let v1 = @vector.make(5, 0)
  assert_eq(v1.to_array(), [0, 0, 0, 0, 0])
  let v2 = @vector.makei(5, fn(i) { i * i })
  assert_eq(v2.to_array(), [0, 1, 4, 9, 16])
}
```

### Get & Set

Use index syntax `v[i]` or `at()` for direct access. Use `get()` for a safe lookup that returns `Option`.

```mbt check
///|
test {
  let v = @vector.from_array([10, 20, 30, 40, 50])
  assert_eq(v[2], 30)
  debug_inspect(v.get(2), content="Some(30)")
  debug_inspect(v.get(99), content="None")
  debug_inspect(v.peek(), content="Some(50)") // last element
}
```

`set()` returns a new vector with the element at the given index replaced.

```mbt check
///|
test {
  let v1 = @vector.from_array([1, 2, 3])
  let v2 = v1.set(1, 20)
  assert_eq(v1.to_array(), [1, 2, 3]) // original unchanged
  assert_eq(v2.to_array(), [1, 20, 3])
}
```

### Push & Pop

`push()` appends an element; `pop()` removes the last element. Both return a new vector.

```mbt check
///|
test {
  let v1 = @vector.from_array([1, 2, 3])
  let v2 = v1.push(4)
  assert_eq(v2.to_array(), [1, 2, 3, 4])
  let v3 = v2.pop().unwrap()
  assert_eq(v3.to_array(), [1, 2, 3])
  // pop on empty vector returns None
  let empty : @vector.Vector[Int] = @vector.new()
  debug_inspect(empty.pop(), content="None")
}
```

### Concatenation

Use `concat()` or the `+` operator to join two vectors.

```mbt check
///|
test {
  let a = @vector.from_array([1, 2, 3])
  let b = @vector.from_array([4, 5, 6])
  assert_eq(a.concat(b).to_array(), [1, 2, 3, 4, 5, 6])
  assert_eq((a + b).to_array(), [1, 2, 3, 4, 5, 6])
}
```

### Range Operations

`split()`, `take()`, `drop()`, and `slice()` work on subranges without flattening the tree.

```mbt check
///|
test {
  let v = @vector.from_iter((0).until(10))
  // split at index: [0, index) and [index, len)
  let (left, right) = v.split(4)
  assert_eq(left.to_array(), [0, 1, 2, 3])
  assert_eq(right.to_array(), [4, 5, 6, 7, 8, 9])
  // take first n elements
  assert_eq(v.take(3).to_array(), [0, 1, 2])
  // drop first n elements
  assert_eq(v.drop(7).to_array(), [7, 8, 9])
  // slice [start, end)
  assert_eq(v.slice(2, 6).to_array(), [2, 3, 4, 5])
}
```

### Iteration

Use `iter()` to get an iterator, or `each()` / `eachi()` for direct traversal.

```mbt check
///|
test {
  let v = @vector.from_array([1, 2, 3, 4, 5])
  // iterator
  inspect(v.iter(), content="[1, 2, 3, 4, 5]")
  // each
  let buf = []
  v.each(fn(x) { buf.push(x) })
  assert_eq(buf, [1, 2, 3, 4, 5])
  // eachi (with index)
  let pairs = []
  v.eachi(fn(i, x) { pairs.push((i, x)) })
  assert_eq(pairs, [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5)])
}
```

### Fold & Map

`fold()` reduces the vector from left to right; `rev_fold()` goes right to left. `map()` transforms each element.

```mbt check
///|
test {
  let v = @vector.from_array([1, 2, 3, 4, 5])
  // sum via fold
  assert_eq(v.fold(fn(acc, x) { acc + x }, init=0), 15)
  // reverse fold
  let result = v.rev_fold(fn(acc, x) { acc + x.to_string() }, init="")
  assert_eq(result, "54321")
  // map
  assert_eq(v.map(fn(x) { x * 2 }).to_array(), [2, 4, 6, 8, 10])
}
```

### Query

```mbt check
///|
test {
  let v = @vector.from_array([1, 2, 3])
  assert_eq(v.length(), 3)
  assert_eq(v.is_empty(), false)
  let empty : @vector.Vector[Int] = @vector.new()
  assert_eq(empty.is_empty(), true)
}
```

### Comparison & Equality

Vectors support `==` (element-wise equality) and `compare()` (shortlex order: shorter vectors are smaller; equal-length vectors compare element-by-element).

```mbt check
///|
test {
  let a = @vector.from_array([1, 2, 3])
  let b = @vector.from_array([1, 2, 3])
  let c = @vector.from_array([1, 2, 4])
  assert_eq(a == b, true)
  assert_eq(a == c, false)
  assert_eq(a.compare(c) < 0, true)
}
```

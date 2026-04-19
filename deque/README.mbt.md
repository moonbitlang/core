# Deque

A double-ended queue backed by a growable ring buffer. Supports O(1) amortized push/pop at both ends and O(1) random access, similar to C++ `std::deque` and Rust `VecDeque`.

# Usage

## Create

Create an empty deque with `new()`, or construct one from an array or iterator.

```mbt check
///|
test {
  let dv : @deque.Deque[Int] = @deque.new()
  assert_eq(dv.is_empty(), true)
  let dv2 = @deque.from_array([1, 2, 3, 4, 5])
  assert_eq(dv2.length(), 5)
  let dv3 = @deque.from_iter([1, 2, 3].iter())
  assert_eq(dv3.length(), 3)
}
```

Pre-allocate capacity to avoid resizing:

```mbt check
///|
test {
  let dv : @deque.Deque[Int] = @deque.new(capacity=1024)
  assert_eq(dv.capacity(), 1024)
}
```

## Length & Capacity

```mbt check
///|
test {
  let dv = @deque.from_array([1, 2, 3])
  assert_eq(dv.length(), 3)
  assert_eq(dv.is_empty(), false)
  // reserve additional capacity
  dv.reserve_capacity(100)
  inspect(dv.capacity() >= 100, content="true")
  // shrink to fit actual contents
  dv.shrink_to_fit()
  assert_eq(dv.capacity(), 3)
}
```

## Access

Use index syntax `dv[i]` or `at()` for direct access. Use `get()` for a safe lookup. `front()` and `back()` return the first and last element.

```mbt check
///|
test {
  let dv = @deque.from_array([10, 20, 30, 40, 50])
  assert_eq(dv[0], 10)
  assert_eq(dv[4], 50)
  assert_eq(dv.get(2), Some(30))
  assert_eq(dv.get(99), None)
  assert_eq(dv.front(), Some(10))
  assert_eq(dv.back(), Some(50))
}
```

## Push & Pop

Push and pop at both ends in O(1) amortized time:

```mbt check
///|
test {
  let dv = @deque.from_array([2, 3])
  dv.push_front(1)
  dv.push_back(4)
  inspect(dv, content="@deque.from_array([1, 2, 3, 4])")
  assert_eq(dv.pop_front(), Some(1))
  assert_eq(dv.pop_back(), Some(4))
  inspect(dv, content="@deque.from_array([2, 3])")
}
```

`unsafe_pop_front()` and `unsafe_pop_back()` discard the return value and panic on an empty deque.

## Set

Mutate elements by index:

```mbt check
///|
test {
  let dv = @deque.from_array([1, 2, 3])
  dv[1] = 20
  assert_eq(dv[1], 20)
}
```

## Insert & Remove

Insert or remove elements at arbitrary positions (O(n)):

```mbt check
///|
test {
  let dv = @deque.from_array([1, 2, 4])
  dv.insert(2, 3) // insert 3 at index 2
  inspect(dv, content="@deque.from_array([1, 2, 3, 4])")
  let removed = dv.remove(0)
  assert_eq(removed, 1)
  inspect(dv, content="@deque.from_array([2, 3, 4])")
}
```

## Concatenation & Append

Use `+` or `append()` to combine deques. `append` mutates the receiver in place.

```mbt check
///|
test {
  let a = @deque.from_array([1, 2])
  let b = @deque.from_array([3, 4])
  inspect(a + b, content="@deque.from_array([1, 2, 3, 4])")
  a.append(b)
  inspect(a, content="@deque.from_array([1, 2, 3, 4])")
}
```

## Search

Linear search with `contains()` and `search()`. Binary search on sorted deques with `binary_search()` and `binary_search_by()`.

```mbt check
///|
test {
  let dv = @deque.from_array([1, 2, 3, 4, 5])
  assert_eq(dv.contains(3), true)
  assert_eq(dv.search(3), Some(2))
  // binary_search returns Ok(index) if found, Err(insertion_point) if not
  assert_eq(dv.binary_search(3), Ok(2))
  assert_eq(dv.binary_search(6), Err(5))
  // binary_search_by takes a comparison function
  assert_eq(dv.binary_search_by(fn(x) { x.compare(3) }), Ok(2))
}
```

## Iteration

Forward and reverse iteration via `each`, `eachi`, `iter`, and their `rev_*` counterparts:

```mbt check
///|
test {
  let dv = @deque.from_array([1, 2, 3])
  // each / eachi
  let buf = []
  dv.each(fn(x) { buf.push(x) })
  assert_eq(buf, [1, 2, 3])
  let pairs = []
  dv.eachi(fn(i, x) { pairs.push((i, x)) })
  assert_eq(pairs, [(0, 1), (1, 2), (2, 3)])
  // reverse iteration
  let rev = []
  dv.rev_each(fn(x) { rev.push(x) })
  assert_eq(rev, [3, 2, 1])
  // iterators
  inspect(dv.iter(), content="[1, 2, 3]")
  inspect(dv.rev_iter(), content="[3, 2, 1]")
}
```

## Map & Filter

`map()` and `mapi()` produce a new deque. `filter()` keeps elements matching a predicate. `retain()` filters in place. `retain_map()` filters and transforms in place.

```mbt check
///|
test {
  let dv = @deque.from_array([1, 2, 3, 4, 5])
  inspect(
    dv.map(fn(x) { x * 2 }),
    content="@deque.from_array([2, 4, 6, 8, 10])",
  )
  inspect(
    dv.mapi(fn(i, x) { i + x }),
    content="@deque.from_array([1, 3, 5, 7, 9])",
  )
  inspect(dv.filter(fn(x) { x % 2 == 0 }), content="@deque.from_array([2, 4])")
  // retain modifies in place
  let dv2 = @deque.from_array([1, 2, 3, 4, 5])
  dv2.retain(fn(x) { x > 3 })
  inspect(dv2, content="@deque.from_array([4, 5])")
  // retain_map: keep Some values, drop None
  let dv3 = @deque.from_array([1, 2, 3, 4])
  dv3.retain_map(fn(x) { if x % 2 == 0 { Some(x * 10) } else { None } })
  inspect(dv3, content="@deque.from_array([20, 40])")
}
```

## Extract & Drain

`extract_if()` removes and returns elements matching a predicate. `drain()` removes a range of elements.

```mbt check
///|
test {
  let dv = @deque.from_array([1, 2, 3, 4, 5])
  let extracted = dv.extract_if(fn(x) { x % 2 == 0 })
  inspect(extracted, content="@deque.from_array([2, 4])")
  inspect(dv, content="@deque.from_array([1, 3, 5])")
  let dv2 = @deque.from_array([1, 2, 3, 4, 5])
  let drained = dv2.drain(start=1, len=2)
  inspect(drained, content="@deque.from_array([2, 3])")
  inspect(dv2, content="@deque.from_array([1, 4, 5])")
}
```

## Chunks

`chunks(n)` splits the deque into groups of `n` elements. `chunk_by(f)` groups consecutive elements where `f(a, b)` returns true.

```mbt check
///|
test {
  let dv = @deque.from_array([1, 2, 3, 4, 5])
  let cs = dv.chunks(2)
  inspect(
    cs,
    content="@deque.from_array([@deque.from_array([1, 2]), @deque.from_array([3, 4]), @deque.from_array([5])])",
  )
  // chunk_by groups consecutive elements that satisfy a predicate
  let dv2 = @deque.from_array([1, 1, 2, 2, 3])
  let grouped = dv2.chunk_by(fn(a, b) { a == b })
  inspect(
    grouped,
    content="@deque.from_array([@deque.from_array([1, 1]), @deque.from_array([2, 2]), @deque.from_array([3])])",
  )
}
```

## Reverse & Shuffle

```mbt check
///|
test {
  let dv = @deque.from_array([1, 2, 3])
  // rev returns a new reversed deque
  inspect(dv.rev(), content="@deque.from_array([3, 2, 1])")
  // rev_in_place reverses in place
  dv.rev_in_place()
  inspect(dv, content="@deque.from_array([3, 2, 1])")
}
```

`shuffle()` returns a new shuffled deque; `shuffle_in_place()` mutates in place. Both take a `rand` function that returns a random int in `[0, n)`.

```mbt check
///|
test {
  let dv = @deque.from_array([1, 2, 3, 4, 5])
  let shuffled = dv.shuffle(rand=fn(_n) { 0 }) // deterministic for test
  assert_eq(shuffled.length(), 5)
}
```

## Truncate & Clear

`truncate(n)` keeps only the first `n` elements. `clear()` removes all elements but retains allocated memory.

```mbt check
///|
test {
  let dv = @deque.from_array([1, 2, 3, 4, 5])
  dv.truncate(3)
  inspect(dv, content="@deque.from_array([1, 2, 3])")
  dv.clear()
  assert_eq(dv.is_empty(), true)
}
```

## Copy & Blit

`copy()` creates a shallow clone. `blit_to()` copies a range of elements from one deque to another.

```mbt check
///|
test {
  let src = @deque.from_array([1, 2, 3, 4, 5])
  let dst = @deque.from_array([0, 0, 0, 0, 0])
  src.blit_to(dst, len=3, src_offset=1, dst_offset=2)
  inspect(dst, content="@deque.from_array([0, 0, 2, 3, 4])")
}
```

## Flatten & Join

`flatten()` merges a deque of deques into a single deque. `join()` concatenates a deque of strings with a separator.

```mbt check
///|
test {
  let nested : @deque.Deque[@deque.Deque[Int]] = @deque.from_array([
    @deque.from_array([1, 2]),
    @deque.from_array([3, 4]),
  ])
  inspect(nested.flatten(), content="@deque.from_array([1, 2, 3, 4])")
  let words = @deque.from_array(["hello", "world"])
  inspect(words.join(", "), content="hello, world")
}
```

## Views

`as_views()` exposes the underlying ring buffer as two contiguous `ArrayView` slices.

```mbt check
///|
test {
  let dv = @deque.from_array([1, 2, 3])
  let (v1, v2) = dv.as_views()
  // for a non-wrapped deque, all elements are in the first view
  assert_eq(v1.length() + v2.length(), 3)
}
```

## Conversion

```mbt check
///|
test {
  let dv = @deque.from_array([1, 2, 3])
  assert_eq(dv.to_array(), [1, 2, 3])
}
```

## Comparison & Equality

Deques support `==` (element-wise equality) and `compare()` (shortlex order).

```mbt check
///|
test {
  let a = @deque.from_array([1, 2, 3])
  let b = @deque.from_array([1, 2, 3])
  assert_eq(a == b, true)
  assert_eq(a.compare(@deque.from_array([1, 2, 4])) < 0, true)
}
```

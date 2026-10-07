# Sorted Map

A mutable map backed by an AVL tree that maintains keys in sorted order.

## Overview

SortedMap is an ordered map implementation that keeps entries sorted by keys. It provides efficient lookup, insertion, and deletion operations, with stable traversal order based on key comparison.

## Performance

- **add/set**: O(log n)
- **remove**: O(log n)
- **get/contains**: O(log n)
- **iterate**: O(n)
- **range**: O(log n + k) where k is number of elements in range
- **space complexity**: O(n)

## Usage

### Create

You can create an empty SortedMap or a SortedMap from other containers.

```mbt check
///|
test {
  let _map1 : @sorted_map.SortedMap[Int, String] = SortedMap([])
  let _map2 = @sorted_map.from_array([(1, "one"), (2, "two"), (3, "three")])
}
```

### Container Operations

Add a key-value pair to the SortedMap in place.

```mbt check
///|
test {
  let map = @sorted_map.from_array([(1, "one"), (2, "two")])
  map.set(3, "three")
  @test.assert_eq(map.length(), 3)
}
```

You can also use the convenient subscript syntax to add or update values:

```mbt check
///|
test {
  let map = @sorted_map.SortedMap([])
  map[1] = "one"
  map[2] = "two"
  @test.assert_eq(map.length(), 2)
}
```

Remove a key-value pair from the SortedMap in place.

```mbt check
///|
test {
  let map = @sorted_map.from_array([(1, "one"), (2, "two"), (3, "three")])
  map.remove(2)
  @test.assert_eq(map.length(), 2)
  @test.assert_eq(map.contains(2), false)
}
```

Get a value by its key. The return type is `Option[V]`.

```mbt check
///|
test {
  let map = @sorted_map.from_array([(1, "one"), (2, "two"), (3, "three")])
  assert_true(map.get(2) == Some("two"))
  assert_true(map.get(4) == None)
}
```

Safe access with error handling:

```mbt check
///|
test {
  let map = @sorted_map.from_array([(1, "one"), (2, "two")])
  let key = 3
  debug_inspect(map.get(key), content="None")
}
```

Check if a key exists in the map.

```mbt check
///|
test {
  let map = @sorted_map.from_array([(1, "one"), (2, "two"), (3, "three")])
  @test.assert_eq(map.contains(2), true)
  @test.assert_eq(map.contains(4), false)
}
```

Iterate over all key-value pairs in the map in sorted key order.

```mbt check
///|
test {
  let map = @sorted_map.from_array([(3, "three"), (1, "one"), (2, "two")])
  let keys = []
  let values = []
  map.each((k, v) => {
    keys.push(k)
    values.push(v)
  })
  @debug.assert_eq(keys, [1, 2, 3])
  @debug.assert_eq(values, ["one", "two", "three"])
}
```

Iterate with index:

```mbt check
///|
test {
  let map = @sorted_map.from_array([(3, "three"), (1, "one"), (2, "two")])
  let result = []
  map.eachi((i, k, v) => result.push((i, k, v)))
  @debug.assert_eq(result, [(0, 1, "one"), (1, 2, "two"), (2, 3, "three")])
}
```

Get the size of the map.

```mbt check
///|
test {
  let map = @sorted_map.from_array([(1, "one"), (2, "two"), (3, "three")])
  @test.assert_eq(map.length(), 3)
}
```

Check if the map is empty.

```mbt check
///|
test {
  let map : @sorted_map.SortedMap[Int, String] = SortedMap([])
  @test.assert_eq(map.is_empty(), true)
}
```

Clear the map.

```mbt check
///|
test {
  let map = @sorted_map.from_array([(1, "one"), (2, "two"), (3, "three")])
  map.clear()
  @test.assert_eq(map.is_empty(), true)
}
```

### Smallest, Largest and Nearest Keys

`first` and `last` return the entries with the smallest and largest keys;
`pop_first` and `pop_last` also remove them. `first_ge`, `first_gt`, `last_le`
and `last_lt` find the nearest entry on either side of a key. All of these run
in O(log n).

“First”, “last”, and the nearest-key comparisons follow the keys' `Compare`
ordering. For keys wrapped in `@cmp.Reverse`, the first entry has the largest
underlying key and the last entry has the smallest.

```mbt check
///|
test {
  let map = @sorted_map.from_array([(10, "a"), (20, "b"), (30, "c")])
  @debug.assert_eq(map.first(), Some((10, "a")))
  @debug.assert_eq(map.last(), Some((30, "c")))
  @debug.assert_eq(map.first_ge(15), Some((20, "b")))
  @debug.assert_eq(map.first_gt(20), Some((30, "c")))
  @debug.assert_eq(map.last_le(25), Some((20, "b")))
  @debug.assert_eq(map.last_lt(10), None)
  @debug.assert_eq(map.pop_first(), Some((10, "a")))
  @debug.assert_eq(map.pop_last(), Some((30, "c")))
  @debug.assert_eq(map.to_array(), [(20, "b")])
}
```

### Reverse Iteration

`rev_iter`, `rev_iter2`, `rev_keys` and `rev_values` mirror `iter`, `iter2`,
`keys` and `values` in descending key order, according to the keys' `Compare`
ordering. `rev_iter2` supports `for key, value in map.rev_iter2()`.

```mbt check
///|
test {
  let map = @sorted_map.from_array([(1, "a"), (2, "b"), (3, "c")])
  @debug.assert_eq(map.rev_keys().to_array(), [3, 2, 1])
  @debug.assert_eq(map.rev_iter().take(1).to_array(), [(3, "c")])
}
```

### Custom Ordering

A `SortedMap` orders keys by their `Compare` implementation. To use a different
order, wrap the key in a type whose `Compare` implements it. `@cmp.Reverse`
gives descending order. When the order is only known at runtime, such as a
per-column ascending or descending flag, let each key carry a reference to that
configuration; all keys of one map share the same configuration array, so the
extra cost is one field per key.

In this example, every key must have the same number of columns, matching the
configuration length. Stored keys and lookup keys must use the same ordering
configuration. Do not mutate a stored key's columns or the shared ordering
configuration while keys remain in the map; doing so invalidates the tree's
ordering. To change the ordering, rebuild the map with new keys.

```mbt check
///|
priv struct IndexKey {
  cols : Array[Int]
  descending : Array[Bool] // shared by every key in the map
}

///|
impl Eq for IndexKey with fn equal(a, b) {
  a.cols == b.cols
}

///|
impl Compare for IndexKey with fn compare(a, b) {
  for i in 0..<a.cols.length() {
    let c = a.cols[i].compare(b.cols[i])
    if c != 0 {
      return if a.descending[i] { -c } else { c }
    }
  }
  0
}

///|
test {
  // Descending order with @cmp.Reverse
  let desc = @sorted_map.from_array([(@cmp.Reverse(1), "a"), (Reverse(3), "c")])
  @debug.assert_eq(desc.keys().map(k => k.0).to_array(), [3, 1])
  // Order chosen at runtime: first column ascending, second descending
  let descending = [false, true]
  let index : @sorted_map.SortedMap[IndexKey, String] = @sorted_map.from_array([])
  index.set({ cols: [1, 5], descending, }, "x")
  index.set({ cols: [1, 9], descending, }, "y")
  index.set({ cols: [0, 7], descending, }, "z")
  @debug.assert_eq(index.values().to_array(), ["z", "y", "x"])
}
```

### Data Extraction

Get all keys or values from the map.

```mbt check
///|
test {
  let map = @sorted_map.from_array([(3, "three"), (1, "one"), (2, "two")])
  @debug.assert_eq(map.keys().collect(), [1, 2, 3])
  @debug.assert_eq(map.values().collect(), ["one", "two", "three"])
}
```

Convert the map to an array of key-value pairs.

```mbt check
///|
test {
  let map = @sorted_map.from_array([(3, "three"), (1, "one"), (2, "two")])
  @debug.assert_eq(map.to_array(), [(1, "one"), (2, "two"), (3, "three")])
}
```

### Range Operations

Get a subset of the map within a specified range of keys. The range is inclusive for both bounds `[low, high]`.

```mbt check
///|
test {
  let map = @sorted_map.from_array([
    (1, "one"),
    (2, "two"),
    (3, "three"),
    (4, "four"),
    (5, "five"),
  ])
  let range_items = []
  map.range(2, 4).each((k, v) => range_items.push((k, v)))
  @debug.assert_eq(range_items, [(2, "two"), (3, "three"), (4, "four")])
}
```

Edge cases for range operations:
- If `low > high`, returns an empty result
- If `low` or `high` are outside the map bounds, returns only pairs within valid bounds
- The returned iterator preserves the sorted order of keys

```mbt check
///|
///  Example with out-of-bounds range
test {
  let map = @sorted_map.from_array([(1, "one"), (2, "two"), (3, "three")])
  let range_items = []
  map.range(0, 10).each((k, v) => range_items.push((k, v)))
  @debug.assert_eq(range_items, [(1, "one"), (2, "two"), (3, "three")])

  // Example with invalid range
  let empty_range : Array[(Int, String)] = []
  map.range(10, 5).each((k, v) => empty_range.push((k, v)))
  @debug.assert_eq(empty_range, [])
}
```

### Iterators

The SortedMap supports several iterator patterns. Create a map from an iterator:

```mbt check
///|
test {
  let pairs = [|(1, "one"), (2, "two"), (3, "three")|]
  let map = @sorted_map.from_iter(pairs)
  @test.assert_eq(map.length(), 3)
}
```

Use the `iter` method to get an iterator over key-value pairs:

```mbt check
///|
test {
  let map = @sorted_map.from_array([(3, "three"), (1, "one"), (2, "two")])
  let pairs = map.iter().to_array()
  @debug.assert_eq(pairs, [(1, "one"), (2, "two"), (3, "three")])
}
```

Use the `iter2` method for a more convenient key-value iteration:

```mbt check
///|
test {
  let map = @sorted_map.from_array([(3, "three"), (1, "one"), (2, "two")])
  let transformed = []
  map.iter2().each((k, v) => transformed.push(k.to_string() + ": " + v))
  @debug.assert_eq(transformed, ["1: one", "2: two", "3: three"])
}
```

### Equality

Maps with the same key-value pairs are considered equal, regardless of the order in which elements were added.

```mbt check
///|
test {
  let map1 = @sorted_map.from_array([(1, "one"), (2, "two")])
  let map2 = @sorted_map.from_array([(2, "two"), (1, "one")])
  @test.assert_eq(map1 == map2, true)
}
```

### Index Access

Use subscript syntax `map[key]` (the `at` operator) for direct access. Panics if the key is not found.

```mbt check
///|
test {
  let map = @sorted_map.from_array([(1, "one"), (2, "two")])
  @test.assert_eq(map[1], "one")
  @test.assert_eq(map[2], "two")
}
```

### Get with Default

`get_or_default()` returns a fallback value when the key is missing. `get_or_init()` lazily initializes and inserts the value if absent.

```mbt check
///|
test {
  let map = @sorted_map.from_array([(1, "one")])
  @test.assert_eq(map.get_or_default(1, "???"), "one")
  @test.assert_eq(map.get_or_default(2, "???"), "???")
  // get_or_init inserts the value if missing
  let val = map.get_or_init(3, fn() { "three" })
  @test.assert_eq(val, "three")
  @test.assert_eq(map.contains(3), true) // now in the map
}
```

### Copy

`copy()` creates a shallow clone of the map.

```mbt check
///|
test {
  let map = @sorted_map.from_array([(1, "a"), (2, "b")])
  let cloned = map.copy()
  cloned.set(3, "c")
  @test.assert_eq(map.contains(3), false) // original unchanged
  @test.assert_eq(cloned.contains(3), true)
}
```

### Merging

`merge()` returns a new map combining both. `merge_in_place()` mutates the receiver. On key conflicts, the right map wins.

```mbt check
///|
test {
  let m1 = @sorted_map.from_array([(1, "a"), (2, "b")])
  let m2 = @sorted_map.from_array([(2, "B"), (3, "c")])
  let merged = m1.merge(m2)
  assert_true(merged.get(2) == Some("B")) // right wins
  assert_true(merged.get(3) == Some("c"))
  // merge_in_place
  let m3 = @sorted_map.from_array([(1, "x")])
  let m4 = @sorted_map.from_array([(2, "y")])
  m3.merge_in_place(m4)
  @test.assert_eq(m3.contains(2), true)
}
```

### Error Handling Best Practices

When working with keys that might not exist, prefer using pattern matching for safety:

```mbt check
///|
fn get_score(scores : @sorted_map.SortedMap[Int, Int], student_id : Int) -> Int {
  match scores.get(student_id) {
    Some(score) => score
    None =>
      // println(
      //   "Student ID " +
      //   student_id.to_string() +
      //   " does not exist, returning default score",
      // )
      0 // Default score
  }
}

///|
test "safe_key_access" {
  // Create a mapping storing student IDs and their scores
  let scores = @sorted_map.from_array([(1001, 85), (1002, 92), (1003, 78)])

  // Access an existing key
  @test.assert_eq(get_score(scores, 1001), 85)

  // Access a non-existent key, returning the default value
  @test.assert_eq(get_score(scores, 9999), 0)
}
```

## Implementation Notes

The SortedMap is implemented as an AVL tree, a self-balancing binary search tree. After insertions and deletions, the tree automatically rebalances to maintain O(log n) search, insertion, and deletion times.

Key properties of the AVL tree implementation:
- Each node stores a height field indicating the height of that subtree
- The balance factor (height difference between left and right subtrees) is maintained between -1 and 1 for all nodes
- Rebalancing is done through tree rotations (single and double rotations)

## Comparison with Other Collections

- **@hashmap.HashMap**: Provides O(1) average case lookups but doesn't maintain order; use when order doesn't matter
- **Map** (builtin): Maintains insertion order but not sorted order; use when insertion order matters
- **@sorted_map.SortedMap**: Maintains keys in sorted order; use when you need keys to be sorted

Choose SortedMap when you need:
- Key-value pairs sorted by key
- Efficient range queries
- Ordered traversal guarantees

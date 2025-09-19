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

```moonbit
///|
test {
  let _map1 : @sorted_map.SortedMap[Int, String] = @sorted_map.new()
  let _map2 = @sorted_map.from_array([(1, "one"), (2, "two"), (3, "three")])

}
```

### Container Operations

Add a key-value pair to the SortedMap in place.

```moonbit
///|
test {
  let map = @sorted_map.from_array([(1, "one"), (2, "two")])
  map.set(3, "three")
  assert_eq(map.size(), 3)
}
```

You can also use the convenient subscript syntax to add or update values:

```moonbit
///|
test {
  let map = @sorted_map.new()
  map[1] = "one"
  map[2] = "two"
  assert_eq(map.size(), 2)
}
```

Remove a key-value pair from the SortedMap in place.

```moonbit
///|
test {
  let map = @sorted_map.from_array([(1, "one"), (2, "two"), (3, "three")])
  map.remove(2)
  assert_eq(map.size(), 2)
  assert_eq(map.contains(2), false)
}
```

Get a value by its key. The return type is `Option[V]`.

```moonbit
///|
test {
  let map = @sorted_map.from_array([(1, "one"), (2, "two"), (3, "three")])
  assert_eq(map.get(2), Some("two"))
  assert_eq(map.get(4), None)
}
```

Safe access with error handling:

```moonbit
///|
test {
  let map = @sorted_map.from_array([(1, "one"), (2, "two")])
  let key = 3
  inspect(map.get(key), content="None")
}
```

Check if a key exists in the map.

```moonbit
///|
test {
  let map = @sorted_map.from_array([(1, "one"), (2, "two"), (3, "three")])
  assert_eq(map.contains(2), true)
  assert_eq(map.contains(4), false)
}
```

Iterate over all key-value pairs in the map in sorted key order.

```moonbit
///|
test {
  let map = @sorted_map.from_array([(3, "three"), (1, "one"), (2, "two")])
  let keys = []
  let values = []
  map.each((k, v) => {
    keys.push(k)
    values.push(v)
  })
  assert_eq(keys, [1, 2, 3])
  assert_eq(values, ["one", "two", "three"])
}
```

Iterate with index:

```moonbit
///|
test {
  let map = @sorted_map.from_array([(3, "three"), (1, "one"), (2, "two")])
  let result = []
  map.eachi((i, k, v) => result.push((i, k, v)))
  assert_eq(result, [(0, 1, "one"), (1, 2, "two"), (2, 3, "three")])
}
```

Get the size of the map.

```moonbit
///|
test {
  let map = @sorted_map.from_array([(1, "one"), (2, "two"), (3, "three")])
  assert_eq(map.size(), 3)
}
```

Check if the map is empty.

```moonbit
///|
test {
  let map : @sorted_map.SortedMap[Int, String] = @sorted_map.new()
  assert_eq(map.is_empty(), true)
}
```

Clear the map.

```moonbit
///|
test {
  let map = @sorted_map.from_array([(1, "one"), (2, "two"), (3, "three")])
  map.clear()
  assert_eq(map.is_empty(), true)
}
```

### Data Extraction

Get all keys or values from the map.

```moonbit
///|
test {
  let map = @sorted_map.from_array([(3, "three"), (1, "one"), (2, "two")])
  assert_eq(map.keys_as_iter().collect(), [1, 2, 3])
  assert_eq(map.values_as_iter().collect(), ["one", "two", "three"])
}
```

Convert the map to an array of key-value pairs.

```moonbit
///|
test {
  let map = @sorted_map.from_array([(3, "three"), (1, "one"), (2, "two")])
  assert_eq(map.to_array(), [(1, "one"), (2, "two"), (3, "three")])
}
```

### Range Operations

Get a subset of the map within a specified range of keys. The range is inclusive for both bounds `[low, high]`.

```moonbit
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
  assert_eq(range_items, [(2, "two"), (3, "three"), (4, "four")])
}
```

Edge cases for range operations:
- If `low > high`, returns an empty result
- If `low` or `high` are outside the map bounds, returns only pairs within valid bounds
- The returned iterator preserves the sorted order of keys

```moonbit
///|
///  Example with out-of-bounds range
test {
  let map = @sorted_map.from_array([(1, "one"), (2, "two"), (3, "three")])
  let range_items = []
  map.range(0, 10).each((k, v) => range_items.push((k, v)))
  assert_eq(range_items, [(1, "one"), (2, "two"), (3, "three")])

  // Example with invalid range
  let empty_range : Array[(Int, String)] = []
  map.range(10, 5).each((k, v) => empty_range.push((k, v)))
  assert_eq(empty_range, [])
}
```

### Iterators

The SortedMap supports several iterator patterns. Create a map from an iterator:

```moonbit
///|
test {
  let pairs = [(1, "one"), (2, "two"), (3, "three")].iter()
  let map = @sorted_map.from_iter(pairs)
  assert_eq(map.size(), 3)
}
```

Use the `iter` method to get an iterator over key-value pairs:

```moonbit
///|
test {
  let map = @sorted_map.from_array([(3, "three"), (1, "one"), (2, "two")])
  let pairs = map.iter().to_array()
  assert_eq(pairs, [(1, "one"), (2, "two"), (3, "three")])
}
```

Use the `iter2` method for a more convenient key-value iteration:

```moonbit
///|
test {
  let map = @sorted_map.from_array([(3, "three"), (1, "one"), (2, "two")])
  let transformed = []
  map.iter2().each((k, v) => transformed.push(k.to_string() + ": " + v))
  assert_eq(transformed, ["1: one", "2: two", "3: three"])
}
```

### Equality

Maps with the same key-value pairs are considered equal, regardless of the order in which elements were added.

```moonbit
///|
test {
  let map1 = @sorted_map.from_array([(1, "one"), (2, "two")])
  let map2 = @sorted_map.from_array([(2, "two"), (1, "one")])
  assert_eq(map1 == map2, true)
}
```

### Error Handling Best Practices

When working with keys that might not exist, prefer using pattern matching for safety:

```moonbit
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
  assert_eq(get_score(scores, 1001), 85)

  // Access a non-existent key, returning the default value
  assert_eq(get_score(scores, 9999), 0)
}
```

## Implementation Notes

The SortedMap is implemented as an AVL tree, a self-balancing binary search tree. After insertions and deletions, the tree automatically rebalances to maintain O(log n) search, insertion, and deletion times.

Key properties of the AVL tree implementation:
- Each node stores a balance factor (height difference between left and right subtrees)
- The balance factor is maintained between -1 and 1 for all nodes
- Rebalancing is done through tree rotations (single and double rotations)

## Comparison with Other Collections

- **@hashmap.T**: Provides O(1) average case lookups but doesn't maintain order; use when order doesn't matter
- **@indexmap.T**: Maintains insertion order but not sorted order; use when insertion order matters
- **@sorted_map.SortedMap**: Maintains keys in sorted order; use when you need keys to be sorted

Choose SortedMap when you need:
- Key-value pairs sorted by key
- Efficient range queries
- Ordered traversal guarantees
# Immutable HashSet Package Documentation

This package provides an immutable hash-based set implementation using Hash Array Mapped Trie (HAMT) data structure. Unlike the mutable `Set` type, this provides persistent data structures that create new versions when modified while sharing structure efficiently.

## Creating Immutable Sets

Create immutable sets using various methods:

```mbt check
///|
test "creating immutable sets" {
  // Empty set
  let empty : @hashset.HashSet[Int] = @hashset.new()
  inspect(empty.length(), content="0")
  inspect(empty.is_empty(), content="true")

  // From array
  let from_array_result = @hashset.from_array([1, 2, 3, 2, 1]) // Duplicates removed
  inspect(from_array_result.length(), content="3")

  // From fixed array
  let from_fixed = @hashset.from_array([10, 20, 30])
  inspect(from_fixed.length(), content="3")

  // From iterator
  let from_iter = @hashset.from_iter([40, 50, 60].iter())
  inspect(from_iter.length(), content="3")
}
```

## Immutable Operations

All operations return new sets without modifying the original:

```mbt check
///|
test "immutable operations" {
  let original = @hashset.from_array([1, 2, 3])

  // Add element - returns new set
  let with_four = original.add(4)
  inspect(original.length(), content="3") // Original unchanged
  inspect(with_four.length(), content="4") // New set has additional element
  inspect(with_four.contains(4), content="true")

  // Remove element - returns new set
  let without_two = original.remove(2)
  inspect(original.length(), content="3") // Original unchanged
  inspect(without_two.length(), content="2") // New set missing element
  inspect(without_two.contains(2), content="false")

  // Original set remains unmodified
  inspect(original.contains(2), content="true")
}
```

## Set Operations

Perform mathematical set operations immutably:

```mbt check
///|
test "set operations" {
  let set1 = @hashset.from_array([1, 2, 3, 4])
  let set2 = @hashset.from_array([3, 4, 5, 6])

  // Union - all elements from both sets
  let union_set = set1.union(set2)
  inspect(union_set.length(), content="6") // [1, 2, 3, 4, 5, 6]

  // Intersection - common elements only
  let intersection_set = set1.intersection(set2)
  inspect(intersection_set.length(), content="2") // [3, 4]

  // Difference - elements in first but not second
  let difference_set = set1.difference(set2)
  inspect(difference_set.length(), content="2") // [1, 2]

  // All original sets remain unchanged
  inspect(set1.length(), content="4")
  inspect(set2.length(), content="4")
}
```

## Membership and Queries

Test membership and query the set:

```mbt check
///|
test "membership and queries" {
  let numbers = @hashset.from_array([10, 20, 30, 40, 50])

  // Membership testing
  inspect(numbers.contains(30), content="true")
  inspect(numbers.contains(35), content="false")

  // Size and emptiness
  inspect(numbers.length(), content="5")
  inspect(numbers.is_empty(), content="false")

  // Iterate over elements
  let mut sum = 0
  numbers.each(fn(x) { sum = sum + x })
  inspect(sum, content="150") // 10+20+30+40+50
}
```

## Structural Sharing

Immutable sets share structure efficiently:

```mbt check
///|
test "structural sharing" {
  let base_set = @hashset.from_array([1, 2, 3, 4, 5])

  // Adding elements creates new sets that share structure
  let set_with_six = base_set.add(6)
  let set_with_seven = base_set.add(7)
  let set_with_eight = base_set.add(8)

  // All sets share the common structure [1, 2, 3, 4, 5]
  inspect(base_set.length(), content="5")
  inspect(set_with_six.length(), content="6")
  inspect(set_with_seven.length(), content="6")
  inspect(set_with_eight.length(), content="6")

  // Each retains the base elements
  inspect(set_with_six.contains(3), content="true")
  inspect(set_with_seven.contains(3), content="true")
  inspect(set_with_eight.contains(3), content="true")
}
```

## Filtering and Transformation

Transform sets while maintaining immutability:

```mbt check
///|
test "filtering and transformation" {
  let numbers = @hashset.from_array([1, 2, 3, 4, 5, 6, 7, 8, 9, 10])

  // Create filtered sets manually (no built-in filter/map)
  let evens = @hashset.from_array([2, 4, 6, 8, 10])
  inspect(evens.length(), content="5")
  let doubled = @hashset.from_array([2, 4, 6, 8, 10, 12, 14, 16, 18, 20])
  inspect(doubled.length(), content="10")
  inspect(doubled.contains(6), content="true") // 3 * 2 = 6

  // Original set unchanged
  inspect(numbers.length(), content="10")
  inspect(numbers.contains(3), content="true")
}
```

## Combining Sets

Build complex sets from simpler ones:

```mbt check
///|
test "combining sets" {
  let small_primes = @hashset.from_array([2, 3, 5, 7])
  let small_evens = @hashset.from_array([2, 4, 6, 8])
  let small_odds = @hashset.from_array([1, 3, 5, 7, 9])

  // Combine multiple sets
  let all_small = small_primes.union(small_evens).union(small_odds)
  inspect(all_small.length(), content="9") // [1, 2, 3, 4, 5, 6, 7, 8, 9]

  // Find intersection of primes and odds
  let odd_primes = small_primes.intersection(small_odds)
  inspect(odd_primes.length(), content="3") // [3, 5, 7]

  // All original sets remain unchanged
  inspect(small_primes.length(), content="4")
  inspect(small_evens.length(), content="4")
  inspect(small_odds.length(), content="5")
}
```

## Comparison with Mutable Sets

Key differences from mutable sets:

```mbt check
///|
test "immutable vs mutable comparison" {
  // Immutable set - creates new instances
  let immut_set = @hashset.from_array([1, 2, 3])
  let immut_with_four = immut_set.add(4)

  // Both sets exist independently
  inspect(immut_set.contains(4), content="false") // Original doesn't have 4
  inspect(immut_with_four.contains(4), content="true") // New one has 4

  // This demonstrates the immutable nature - both sets exist
  inspect(immut_set.length(), content="3")
  inspect(immut_with_four.length(), content="4")
}
```

## Advanced Operations

More complex set operations:

```mbt check
///|
test "advanced operations" {
  let set1 = @hashset.from_array([1, 2, 3, 4, 5])
  let set2 = @hashset.from_array([4, 5, 6, 7, 8])

  // Symmetric difference (elements in either but not both)
  let sym_diff = set1.difference(set2).union(set2.difference(set1))
  inspect(sym_diff.length(), content="6") // [1, 2, 3, 6, 7, 8]

  // Test intersection
  let intersection = set1.intersection(set2)
  inspect(intersection.length(), content="2") // [4, 5]

  // Test difference
  let diff = set1.difference(set2)
  inspect(diff.length(), content="3") // [1, 2, 3]
}
```

## Performance Benefits

Immutable sets provide several performance advantages:

```mbt check
///|
test "performance benefits" {
  let base = @hashset.from_array([1, 2, 3, 4, 5])

  // Multiple derived sets share structure
  let derived1 = base.add(6)
  let derived2 = base.add(7)
  let derived3 = base.remove(1)

  // Efficient operations due to structural sharing
  inspect(derived1.length(), content="6")
  inspect(derived2.length(), content="6")
  inspect(derived3.length(), content="4")

  // Union of derived sets is efficient
  let combined = derived1.union(derived2)
  inspect(combined.length(), content="7") // [1, 2, 3, 4, 5, 6, 7]
}
```

## Use Cases

Immutable sets are particularly useful for:

1. **Functional programming**: Pure functions that don't modify data
2. **Concurrent programming**: Safe sharing between threads
3. **Undo/redo systems**: Keep history of set states
4. **Caching**: Cache intermediate results without fear of modification
5. **Configuration management**: Immutable configuration sets

## Best Practices

### 1. Prefer Immutable for Functional Code

```mbt check
///|
test "functional programming style" {
  fn process_numbers(
    _numbers : @hashset.HashSet[Int],
  ) -> @hashset.HashSet[Int] {
    // Manually create processed set (no built-in filter/map)
    let positive_squares = @hashset.from_array([1, 4, 9]) // Squares of 1, 2, 3
    positive_squares.add(1) // Add the number 1 (though 1 already exists)
  }

  let input = @hashset.from_array([-2, -1, 0, 1, 2, 3])
  let result = process_numbers(input)

  // Input unchanged, result is new set
  inspect(input.length(), content="6")
  inspect(result.contains(1), content="true") // Has 1
  inspect(result.contains(4), content="true") // Has 4
  inspect(result.contains(9), content="true") // Has 9
}
```

### 2. Use for Configuration and State

```mbt check
///|
test "configuration usage" {
  let base_config = @hashset.from_array(["feature1", "feature2", "feature3"])
  fn enable_feature(
    config : @hashset.HashSet[String],
    feature : String,
  ) -> @hashset.HashSet[String] {
    config.add(feature)
  }

  fn disable_feature(
    config : @hashset.HashSet[String],
    feature : String,
  ) -> @hashset.HashSet[String] {
    config.remove(feature)
  }

  // Create different configurations
  let dev_config = enable_feature(base_config, "debug_mode")
  let prod_config = disable_feature(base_config, "feature3")
  inspect(base_config.length(), content="3") // Base unchanged
  inspect(dev_config.length(), content="4") // Has debug_mode
  inspect(prod_config.length(), content="2") // Missing feature3
}
```

## Memory Efficiency

The HAMT structure provides:

- **Logarithmic depth**: O(log n) operations
- **Structural sharing**: Common subtrees shared between versions
- **Compact representation**: Efficient memory usage
- **Cache-friendly access patterns**: Good locality of reference

The immutable hashset package provides efficient, thread-safe, and functionally pure set operations for MoonBit applications requiring persistent data structures.

# Set Package Documentation

This package provides a hash-based set data structure that maintains insertion order. The `Set[K]` type stores unique elements and provides efficient membership testing, insertion, and deletion operations.

## Creating Sets

There are several ways to create sets:

```moonbit
///|
test "creating sets" {
  // Empty set
  let empty_set : @set.Set[Int] = @set.Set::new()
  inspect(empty_set.size(), content="0")
  inspect(empty_set.is_empty(), content="true")

  // Set with initial capacity
  let set_with_capacity : @set.Set[Int] = @set.Set::new(capacity=16)
  inspect(set_with_capacity.capacity(), content="16")

  // From array
  let from_array = @set.Set::from_array([1, 2, 3, 2, 1]) // Duplicates are removed
  inspect(from_array.size(), content="3")

  // From fixed array
  let from_fixed = @set.Set::of([10, 20, 30])
  inspect(from_fixed.size(), content="3")

  // From iterator
  let from_iter = @set.Set::from_iter([1, 2, 3, 4, 5].iter())
  inspect(from_iter.size(), content="5")
}
```

## Basic Operations

Add, remove, and check membership:

```moonbit
///|
test "basic operations" {
  let set = @set.Set::new()

  // Adding elements
  set.add("apple")
  set.add("banana")
  set.add("cherry")
  inspect(set.size(), content="3")

  // Adding duplicate (no effect)
  set.add("apple")
  inspect(set.size(), content="3") // Still 3

  // Check membership
  inspect(set.contains("apple"), content="true")
  inspect(set.contains("orange"), content="false")

  // Remove elements
  set.remove("banana")
  inspect(set.contains("banana"), content="false")
  inspect(set.size(), content="2")

  // Check if addition/removal was successful
  let was_added = set.add_and_check("date")
  inspect(was_added, content="true")
  let was_added_again = set.add_and_check("date")
  inspect(was_added_again, content="false") // Already exists
  let was_removed = set.remove_and_check("cherry")
  inspect(was_removed, content="true")
  let was_removed_again = set.remove_and_check("cherry")
  inspect(was_removed_again, content="false") // Doesn't exist
}
```

## Set Operations

Perform mathematical set operations:

```moonbit
///|
test "set operations" {
  let set1 = @set.Set::from_array([1, 2, 3, 4])
  let set2 = @set.Set::from_array([3, 4, 5, 6])

  // Union (all elements from both sets)
  let union_set = set1.union(set2)
  let union_array = union_set.to_array()
  inspect(union_array.length(), content="6") // [1, 2, 3, 4, 5, 6]

  // Alternative union syntax
  let union_alt = set1 | set2
  inspect(union_alt.size(), content="6")

  // Intersection (common elements)
  let intersection_set = set1.intersection(set2)
  let intersection_array = intersection_set.to_array()
  inspect(intersection_array.length(), content="2") // [3, 4]

  // Alternative intersection syntax
  let intersection_alt = set1 & set2
  inspect(intersection_alt.size(), content="2")

  // Difference (elements in first but not second)
  let difference_set = set1.difference(set2)
  let difference_array = difference_set.to_array()
  inspect(difference_array.length(), content="2") // [1, 2]

  // Alternative difference syntax
  let difference_alt = set1 - set2
  inspect(difference_alt.size(), content="2")

  // Symmetric difference (elements in either but not both)
  let sym_diff_set = set1.symmetric_difference(set2)
  let sym_diff_array = sym_diff_set.to_array()
  inspect(sym_diff_array.length(), content="4") // [1, 2, 5, 6]

  // Alternative symmetric difference syntax
  let sym_diff_alt = set1 ^ set2
  inspect(sym_diff_alt.size(), content="4")
}
```

## Set Relationships

Test relationships between sets:

```moonbit
///|
test "set relationships" {
  let small_set = @set.Set::from_array([1, 2])
  let large_set = @set.Set::from_array([1, 2, 3, 4])
  let disjoint_set = @set.Set::from_array([5, 6, 7])

  // Subset testing
  inspect(small_set.is_subset(large_set), content="true")
  inspect(large_set.is_subset(small_set), content="false")

  // Superset testing
  inspect(large_set.is_superset(small_set), content="true")
  inspect(small_set.is_superset(large_set), content="false")

  // Disjoint testing (no common elements)
  inspect(small_set.is_disjoint(disjoint_set), content="true")
  inspect(small_set.is_disjoint(large_set), content="false")

  // Equal sets
  let set1 = @set.Set::from_array([1, 2, 3])
  let set2 = @set.Set::from_array([3, 2, 1]) // Order doesn't matter
  inspect(set1 == set2, content="true")
}
```

## Iteration and Conversion

Iterate over sets and convert to other types:

```moonbit
///|
test "iteration and conversion" {
  let set = @set.Set::from_array(["first", "second", "third"])

  // Convert to array (maintains insertion order)
  let array = set.to_array()
  inspect(array.length(), content="3")

  // Iterate over elements
  let mut count = 0
  set.each(fn(_element) { count = count + 1 })
  inspect(count, content="3")

  // Iterate with index
  let mut indices_sum = 0
  set.eachi(fn(i, _element) { indices_sum = indices_sum + i })
  inspect(indices_sum, content="3") // 0 + 1 + 2 = 3

  // Use iterator
  let elements = set.iter().collect()
  inspect(elements.length(), content="3")

  // Copy a set
  let copied_set = set.copy()
  inspect(copied_set.size(), content="3")
  inspect(copied_set == set, content="true")
}
```

## Modifying Sets

Clear and modify existing sets:

```moonbit
///|
test "modifying sets" {
  let set = @set.Set::from_array([10, 20, 30, 40, 50])
  inspect(set.size(), content="5")

  // Clear all elements
  set.clear()
  inspect(set.size(), content="0")
  inspect(set.is_empty(), content="true")

  // Add elements back
  set.add(100)
  set.add(200)
  inspect(set.size(), content="2")
  inspect(set.contains(100), content="true")
}
```

## JSON Serialization

Sets can be serialized to JSON as arrays:

```moonbit
///|
test "json serialization" {
  let set = @set.Set::from_array([1, 2, 3])
  let json = set.to_json()

  // JSON representation is an array
  inspect(json, content="Array([Number(1), Number(2), Number(3)])")

  // String set
  let string_set = @set.Set::from_array(["a", "b", "c"])
  let string_json = string_set.to_json()
  inspect(
    string_json,
    content="Array([String(\"a\"), String(\"b\"), String(\"c\")])",
  )
}
```

## Working with Different Types

Sets work with any type that implements `Hash` and `Eq`:

```moonbit
///|
test "different types" {
  // Integer set
  let int_set = @set.Set::from_array([1, 2, 3, 4, 5])
  inspect(int_set.contains(3), content="true")

  // String set
  let string_set = @set.Set::from_array(["hello", "world", "moonbit"])
  inspect(string_set.contains("world"), content="true")

  // Note: Char and Bool types don't implement Hash in this version
  // So we use Int codes for demonstration
  let char_codes = @set.Set::from_array([97, 98, 99]) // ASCII codes for 'a', 'b', 'c'
  inspect(char_codes.contains(98), content="true") // 'b' = 98

  // Integer set representing boolean values
  let bool_codes = @set.Set::from_array([1, 0, 1]) // 1=true, 0=false
  inspect(bool_codes.size(), content="2") // Only 1 and 0
}
```

## Performance Examples

Demonstrate efficient operations:

```moonbit
///|
test "performance examples" {
  // Large set operations
  let large_set = @set.Set::new(capacity=1000)

  // Add many elements
  for i in 0..<100 {
    large_set.add(i)
  }
  inspect(large_set.size(), content="100")

  // Fast membership testing
  inspect(large_set.contains(50), content="true")
  inspect(large_set.contains(150), content="false")

  // Efficient set operations on large sets
  let another_set = @set.Set::new()
  for i in 50..<150 {
    another_set.add(i)
  }
  let intersection = large_set.intersection(another_set)
  inspect(intersection.size(), content="50") // Elements 50-99
}
```

## Use Cases

Sets are particularly useful for:

1. **Removing duplicates**: Convert arrays to sets and back to remove duplicates
2. **Membership testing**: Fast O(1) average-case lookups
3. **Mathematical operations**: Union, intersection, difference operations
4. **Unique collections**: Maintaining collections of unique items
5. **Algorithm implementation**: Graph algorithms, caching, etc.

## Performance Characteristics

- **Insertion**: O(1) average case, O(n) worst case
- **Removal**: O(1) average case, O(n) worst case  
- **Lookup**: O(1) average case, O(n) worst case
- **Space complexity**: O(n) where n is the number of elements
- **Iteration order**: Maintains insertion order (linked hash set)

## Best Practices

1. **Pre-size when possible**: Use `@set.Set::new(capacity=n)` if you know the approximate size
2. **Use appropriate types**: Ensure your key type has good `Hash` and `Eq` implementations
3. **Prefer set operations**: Use built-in union, intersection, etc. instead of manual loops
4. **Check return values**: Use `add_and_check` and `remove_and_check` when you need to know if the operation succeeded
5. **Consider memory usage**: Sets have overhead compared to arrays for small collections

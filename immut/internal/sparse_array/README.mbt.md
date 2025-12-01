# Immutable Internal Sparse Array Package Documentation

This package provides sparse array and bitset utilities used internally by immutable data structures. It implements efficient storage for arrays with gaps and bitset operations for tracking element presence.

## Sparse Array Basics

Create and manipulate sparse arrays:

```mbt check
///|
test "sparse array basics" {
  // Empty sparse array
  let empty_array : @sparse_array.SparseArray[String] = @sparse_array.empty()
  inspect(empty_array.length(), content="0")

  // Singleton sparse array
  let single = @sparse_array.singleton(5, "value")
  inspect(single.length(), content="1")

  // Check if element exists
  match single.get(5) {
    Some(val) => inspect(val, content="value")
    None => inspect(false, content="true")
  }

  // Doubleton (two elements)
  let double = @sparse_array.doubleton(2, "first", 7, "second")
  inspect(double.length(), content="2")
}
```

## Sparse Array Operations

Add, remove, and modify elements:

```mbt check
///|
test "sparse array operations" {
  let arr = @sparse_array.singleton(3, 100)

  // Add new element
  let with_new = arr.add(8, 200)
  inspect(with_new.length(), content="2")

  // Replace existing element
  let replaced = with_new.replace(3, 150)
  inspect(replaced.length(), content="2")

  // Remove element
  let removed = replaced.remove(8)
  inspect(removed.length(), content="1")

  // Check final value
  match removed.get(3) {
    Some(val) => inspect(val, content="150")
    None => inspect(false, content="true")
  }
}
```

## Bitset Operations

Work with compact bitsets for tracking presence:

```mbt check
///|
test "bitset operations" {
  // Note: Bitset constructor is internal, so we demonstrate concepts
  // In real usage, bitsets are created by sparse array operations

  let sparse = @sparse_array.singleton(3, "test")
  inspect(sparse.length(), content="1")

  // Add more elements to create internal bitsets
  let with_more = sparse.add(7, "another").add(15, "third")
  inspect(with_more.length(), content="3")

  // Access elements by index
  match with_more.get(3) {
    Some(val) => inspect(val, content="test")
    None => inspect(false, content="true")
  }

  // Remove element
  let removed = with_more.remove(7)
  inspect(removed.length(), content="2")
}
```

## Sparse Array Set Operations

Perform set-like operations on sparse arrays:

```mbt check
///|
test "sparse array set operations" {
  let arr1 = @sparse_array.doubleton(1, "a", 3, "c")
  let arr2 = @sparse_array.doubleton(3, "C", 5, "e")

  // Intersection - keep common indices
  let intersection = arr1.intersection(arr2, fn(val1, val2) {
    Some(val1 + val2)
  })
  match intersection {
    Some(result) => inspect(result.length(), content="1") // Only index 3 is common
    None => inspect(false, content="true")
  }

  // Difference - remove common elements
  let difference = arr1.difference(arr2, fn(_val1, _val2) { None })
  match difference {
    Some(result) => inspect(result.length(), content="1") // Only index 1 remains
    None => inspect(false, content="true")
  }
}
```

## Sparse Array Transformations

Transform sparse arrays while maintaining efficiency:

```mbt check
///|
test "sparse array transformations" {
  let numbers = @sparse_array.doubleton(1, 10, 5, 50)

  // Map values to new type
  let doubled = numbers.map(fn(x) { x * 2 })
  inspect(doubled.length(), content="2")
  match doubled.get(1) {
    Some(val) => inspect(val, content="20")
    None => inspect(false, content="true")
  }

  // Filter elements (keeping only those > 30)
  let filtered = numbers.filter(fn(x) { if x > 30 { Some(x) } else { None } })
  match filtered {
    Some(f) => inspect(f.length(), content="1") // Only 50 remains
    None => inspect(false, content="true")
  }
}
```

## Sparse Array Combinations

Combine multiple sparse arrays:

```mbt check
///|
test "sparse array combinations" {
  let arr1 = @sparse_array.doubleton(1, "a", 3, "c")
  let arr2 = @sparse_array.doubleton(2, "b", 3, "C") // Overlaps at index 3

  // Union with conflict resolution
  let combined = arr1.union(arr2, fn(old_val, new_val) { old_val + new_val })
  inspect(combined.length(), content="3")

  // Check combined values
  match combined.get(3) {
    Some(val) => inspect(val, content="cC") // Combined "c" + "C"
    None => inspect(false, content="true")
  }
}
```

## Advanced Sparse Array Operations

Work with sparse arrays efficiently:

```mbt check
///|
test "advanced sparse operations" {
  let numbers = @sparse_array.doubleton(2, 20, 5, 50)

  // Add more elements
  let extended = numbers.add(10, 100).add(15, 150)
  inspect(extended.length(), content="4")

  // Access specific elements
  match extended.get(10) {
    Some(val) => inspect(val, content="100")
    None => inspect(false, content="true")
  }

  // Check non-existent element
  match extended.get(7) {
    Some(_) => inspect(false, content="true")
    None => inspect(true, content="true") // Should be None
  }
}
```

## Internal Usage Context

These utilities are used by:

1. **HAMT (Hash Array Mapped Trie)**: Efficient immutable hash tables
2. **Immutable vectors**: Sparse storage for large vectors
3. **Immutable sets**: Compact representation of set membership
4. **Tree structures**: Efficient navigation and storage

## Performance Characteristics

### Sparse Arrays
- **Access**: O(1) for existing elements
- **Insertion**: O(1) amortized
- **Space**: Only stores non-empty elements
- **Cache efficiency**: Compact storage layout

### Bitsets
- **Set/clear**: O(1) bit operations
- **Union/intersection**: O(1) bitwise operations
- **Size counting**: O(1) with population count
- **Memory**: 1 bit per possible position

## Design Principles

1. **Immutability**: All operations return new instances
2. **Structural sharing**: Efficient memory usage
3. **Bit-level efficiency**: Compact representation
4. **Zero-cost abstractions**: No runtime overhead

This package provides the low-level building blocks for efficient immutable data structures in the MoonBit standard library.

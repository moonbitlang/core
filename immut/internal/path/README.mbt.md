# Immutable Internal Path Package Documentation

This package provides internal path utilities for immutable data structures, specifically for navigating Hash Array Mapped Trie (HAMT) structures. It is used internally by immutable collections to track positions within the tree structure.

## Path Structure

The `Path` type represents a position in a HAMT structure:

```mbt check
///|
test "path basics" {
  // Create a path from a hashable value
  let path = @path.of(42)

  // Check if this is the last level
  let is_last = path.is_last()
  inspect(is_last, content="false") // Single level path

  // Get the index at current level
  let idx = path.idx()
  inspect(idx >= 0, content="true") // Should be valid index
}
```

## Path Navigation

Navigate through HAMT tree levels:

```mbt check
///|
test "path navigation" {
  let initial_path = @path.of("test_key")

  // Move to next level in the tree
  let next_path = initial_path.next()

  // Paths should be different
  inspect(initial_path == next_path, content="false")

  // Check indices at different levels
  let initial_idx = initial_path.idx()
  let next_idx = next_path.idx()
  inspect(initial_idx >= 0, content="true")
  inspect(next_idx >= 0, content="true")
}
```

## Path Construction

Build paths for tree navigation:

```mbt check
///|
test "path construction" {
  let base_path = @path.of(12345)

  // Push additional level information
  let extended_path = base_path.push(7)

  // Extended path should be different
  inspect(base_path == extended_path, content="false")

  // Check properties
  let base_idx = base_path.idx()
  let extended_idx = extended_path.idx()
  inspect(base_idx >= 0, content="true")
  inspect(extended_idx >= 0, content="true")
}
```

## Internal Usage

This package is used internally by:

1. **HAMT implementations**: Navigate tree structures efficiently
2. **Immutable collections**: Track insertion and lookup paths  
3. **Hash table operations**: Determine bucket positions
4. **Tree balancing**: Manage tree depth and structure

## Technical Details

The Path type:
- Encodes tree navigation information compactly
- Uses bit manipulation for efficient path operations
- Supports up to 32 levels of tree depth
- Provides O(1) path operations

## Performance Characteristics

- **Path creation**: O(1) from hash values
- **Navigation**: O(1) to move between levels
- **Index calculation**: O(1) bit operations
- **Memory usage**: Single UInt per path (very compact)

This is an internal implementation detail used by immutable data structures and is not intended for direct use by application developers.

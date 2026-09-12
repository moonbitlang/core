# MoonBit Array::sort Implementation Guide

## Overview

MoonBit's `Array::sort` is a sophisticated hybrid sorting algorithm that combines multiple strategies to achieve optimal performance across different scenarios. It's an **in-place, unstable sort** with guaranteed **O(n log n)** worst-case time complexity.

The implementation lives in `builtin/array_sort_impl.mbt`, where the unstable-sort
helpers carry a `fixed_` prefix. The same file also contains the separate
TimSort implementation used by `stable_sort`. The snippets below describe the
unstable sort.

## Core Strategy: Adaptive QuickSort

The main algorithm is an adaptive QuickSort implementation with several optimizations and fallback strategies to handle edge cases efficiently.

### Algorithm Flow

```
Array::sort(arr)
    ├── Calculate budget for unbalanced partitions
    └── fixed_quick_sort(arr, pred=None, limit)
        ├── If len ≤ 16: Use Insertion Sort
        ├── If limit == 0: Use Heap Sort (fallback)
        ├── Choose pivot intelligently
        ├── If likely sorted: Try Bounded Insertion Sort
        ├── Partition array around pivot
        ├── Track balance and adjust limit
        ├── Skip duplicate pivots if detected
        └── Recurse on smaller partition first (tail recursion optimization)
```

## Key Components

### 1. Size-Based Strategy Selection

```mbt
let bubble_sort_len = 16
if len <= bubble_sort_len {
    if len >= 2 {
        fixed_bubble_sort(arr)  // Insertion sort despite the historical name
    }
    return
}
```

**Small Arrays (≤16 elements)**: Uses insertion sort, implemented by the historically named `fixed_bubble_sort`. It grows a sorted prefix by moving each new element left through adjacent swaps.

### 2. Unbalanced-Partition Budget

`fixed_get_limit(len)` computes `floor(log₂(len)) + 1` for a non-empty
array. Each partition whose smaller side has fewer than `len / 8` elements
consumes one unit of this budget; balanced partitions do not consume it.
When the budget reaches zero, `fixed_quick_sort` switches to heap sort.
This limits the work spent on severely unbalanced partitions and guarantees
O(n log n) worst-case time. It is not a limit on all recursive calls.

### 3. Intelligent Pivot Selection

The `fixed_choose_pivot` function uses sophisticated heuristics:

- **For arrays with 17–50 elements**: Samples near the 25%, 50%, and 75% positions (smaller arrays have already used insertion sort)
- **For arrays > 50 elements**: Median-of-medians approach
  - Samples 9 elements (3 groups of 3)
  - Sorts each group and finds median-of-medians

The function also detects if the array appears sorted by counting swaps during pivot selection.

### 4. Adaptive Sorting for Nearly-Sorted Data

```mbt
if was_partitioned && balanced && likely_sorted {
    if fixed_try_bubble_sort(arr) {
        return  // Successfully sorted with insertion sort
    }
}
```

When the array appears nearly sorted, it attempts a **bounded insertion sort** (named `fixed_try_bubble_sort`) that:
- Returns `false` after the ninth element that needs to move left
- Completes in O(n) for already sorted arrays
- Falls back to QuickSort if too many inversions are found

### 5. Partition Optimization

The partition function:
- Uses the classic Lomuto partition scheme
- Returns the final pivot position and a boolean that stays true when the partition scan moves no elements; placing the pivot itself does not affect this flag
- Tracks whether the array was already partitioned (helps detect sorted subarrays)

### 6. Balance Tracking

```mbt
balanced = {
    minimum(pivot, len - pivot) >= len / 8
}
```

The algorithm tracks partition balance. Every unbalanced partition (smaller side below `len / 8`) decrements the budget once; balanced partitions leave it unchanged.

### 7. Duplicate Handling

```mbt
if pred is Some(p) && p == arr.unsafe_get(pivot) {
    // Skip all elements equal to the pivot
    let mut i = pivot
    while i < len && p == arr.unsafe_get(i) {
        i = i + 1
    }
    // Continue sorting only arr.slice(i, len).
}
```

When the pivot equals the lower bound inherited from an earlier partition,
the algorithm skips the contiguous equal prefix after partitioning. Further
equal elements may remain later in the slice and are handled by later passes.

### 8. Tail Recursion Optimization

```mbt
// Recurse on smaller partition, iterate on larger
let left = arr.slice(0, pivot)
let right = arr.slice(pivot + 1, len)
if left.length() < right.length() {
    fixed_quick_sort(left, pred, limit)  // Recurse on smaller
    continue limit, right, Some(arr.unsafe_get(pivot)), ..  // Iterate on larger
}
```

To minimize stack depth, the algorithm:
- Recursively sorts the smaller partition
- Iteratively sorts the larger partition
- This guarantees O(log n) stack space in the worst case

## Performance Characteristics

### Time Complexity
- **Best case**: O(n) for already sorted arrays (detected by the bounded insertion-sort pass)
- **Average case**: O(n log n)
- **Worst case**: O(n log n) (guaranteed by heap sort fallback)

### Space Complexity
- **Stack space**: O(log n) due to tail recursion optimization
- **Additional space**: O(1) - all operations are in-place

### Key Optimizations
1. **Cache-friendly**: Insertion sort for small subarrays
2. **Branch prediction**: Likely sorted arrays handled specially
3. **Minimal comparisons**: Smart pivot selection reduces comparisons
4. **Duplicate optimization**: Skips equal elements efficiently
5. **Stack optimization**: Tail recursion on larger partition

## Stability Note

This implementation is **unstable** - equal elements may be reordered. This is a deliberate trade-off for:
- Better performance (fewer moves)
- Lower memory usage (in-place operation)
- Simpler implementation

## Example Usage

```mbt
let arr = [5, 4, 3, 2, 1]
arr.sort()
assert_eq(arr, [1, 2, 3, 4, 5])
```

## Algorithm Decision Tree

```
Array Size?
├── ≤ 16 elements → Insertion Sort
└── > 16 elements
    ├── Unbalanced-partition budget exhausted? → Heap Sort
    └── Continue with QuickSort
        ├── Choose pivot (median-of-medians for large arrays)
        ├── Array likely sorted? → Try Bounded Insertion Sort
        │   ├── Success → Done
        │   └── Failed → Continue partitioning
        ├── Partition around pivot
        ├── Check for duplicates → Skip if found
        └── Recurse/iterate based on partition sizes
```

## Summary

MoonBit's `Array::sort` is a production-ready sorting implementation that:
- Adapts to input characteristics (sorted, random, reverse-sorted)
- Handles edge cases gracefully (duplicates, small arrays)
- Guarantees O(n log n) worst-case performance
- Minimizes stack usage through tail recursion
- Optimizes for modern CPU cache hierarchies

The implementation represents a careful balance between theoretical optimality and practical performance, making it suitable for a wide range of real-world applications.

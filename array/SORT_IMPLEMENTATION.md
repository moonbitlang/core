# MoonBit Array::sort Implementation Guide

## Overview

MoonBit's `Array::sort` is a sophisticated hybrid sorting algorithm that combines multiple strategies to achieve optimal performance across different scenarios. It's an **in-place, unstable sort** with guaranteed **O(n log n)** worst-case time complexity.

## Core Strategy: Adaptive QuickSort

The main algorithm is an adaptive QuickSort implementation with several optimizations and fallback strategies to handle edge cases efficiently.

### Algorithm Flow

```
Array::sort(arr)
    ├── Calculate recursion limit based on array length
    └── quick_sort(arr, start=0, end=len, pred=None, limit)
        ├── If len ≤ 16: Use Insertion Sort
        ├── If limit == 0: Use Heap Sort (fallback)
        ├── Choose pivot intelligently
        ├── If likely sorted: Try Bubble Sort
        ├── Partition array around pivot
        ├── Track balance and adjust limit
        ├── Skip duplicate pivots if detected
        └── Recurse on smaller partition first (tail recursion optimization)
```

## Key Components

### 1. Size-Based Strategy Selection

```mbt
let insertion_sort_len = 16
if len <= insertion_sort_len {
    arr.insertion_sort(start, end)  // Small arrays: O(n²) but cache-friendly
}
```

**Small Arrays (≤16 elements)**: Uses insertion sort for its excellent cache locality and low overhead on small datasets.

### 2. Recursion Depth Limiting

```mbt
fn get_limit(len: Int) -> Int {
    // Returns log₂(len) - the maximum balanced recursion depth
    let mut limit = 0
    while len > 0 {
        len = len / 2
        limit += 1
    }
    limit
}
```

The algorithm tracks recursion depth and switches to **Heap Sort** if the limit is exceeded, preventing O(n²) worst-case scenarios.

### 3. Intelligent Pivot Selection

The `choose_pivot` function uses sophisticated heuristics:

- **For arrays < 8 elements**: Simple middle element
- **For arrays ≥ 8 elements**: Samples at 25%, 50%, 75% positions
- **For arrays > 50 elements**: Median-of-medians approach
  - Samples 9 elements (3 groups of 3)
  - Sorts each group and finds median-of-medians

The function also detects if the array appears sorted by counting swaps during pivot selection.

### 4. Adaptive Sorting for Nearly-Sorted Data

```mbt
if was_partitioned && balanced && likely_sorted {
    if arr.try_bubble_sort(start, end) {
        return  // Successfully sorted with bubble sort
    }
}
```

When the array appears nearly sorted, it attempts a **limited bubble sort** that:
- Tolerates at most 8 unsorted elements
- Completes in O(n) for already sorted arrays
- Falls back to QuickSort if too many inversions are found

### 5. Partition Optimization

The partition function:
- Uses the classic Lomuto partition scheme
- Returns both the final pivot position and a boolean indicating if any swaps occurred
- Tracks whether the array was already partitioned (helps detect sorted subarrays)

### 6. Balance Tracking

```mbt
balanced = {
    let pivot_pos = actual_pivot_pos - current_start
    let diff = len - pivot_pos
    (if pivot_pos < diff { pivot_pos } else { diff }) >= len / 8
}
```

The algorithm tracks partition balance. If the pivot consistently creates unbalanced partitions (< 1/8 of elements on one side), it decrements the recursion limit faster.

### 7. Duplicate Handling

```mbt
if pred == arr[actual_pivot_pos] {
    // Skip all elements equal to the pivot
    let mut i = actual_pivot_pos
    while i < current_end && pred == arr[i] {
        i = i + 1
    }
    current_start = i
    continue
}
```

When consecutive equal pivots are detected, the algorithm skips over all equal elements, significantly improving performance on arrays with many duplicates.

### 8. Tail Recursion Optimization

```mbt
// Recurse on smaller partition, iterate on larger
if left_end - left_start < right_end - right_start {
    arr.quick_sort(left_start, left_end, pred, limit)  // Recurse on smaller
    current_start = right_start                         // Iterate on larger
    current_end = right_end
}
```

To minimize stack depth, the algorithm:
- Recursively sorts the smaller partition
- Iteratively sorts the larger partition
- This guarantees O(log n) stack space in the worst case

## Performance Characteristics

### Time Complexity
- **Best case**: O(n) for already sorted arrays (detected and sorted with bubble sort)
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
    ├── Recursion limit exceeded? → Heap Sort
    └── Continue with QuickSort
        ├── Choose pivot (median-of-medians for large arrays)
        ├── Array likely sorted? → Try Bubble Sort
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

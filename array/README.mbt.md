# Array Package Documentation

This package provides array manipulation utilities for MoonBit, including fixed-size arrays (`FixedArray`), dynamic arrays (`Array`), and array views (`ArrayView`/`View`).

## Creating Arrays

There are several ways to create arrays in MoonBit:

```moonbit
test "array creation" {
  // Using array literal
  let arr1 = [1, 2, 3]
  inspect(arr1, content="[1, 2, 3]")

  // Creating with indices
  let arr2 = Array::makei(3, i => i * 2)
  inspect(arr2, content="[0, 2, 4]")

  // Creating from iterator
  let arr3 = Array::from_iter("hello".iter())
  inspect(arr3, content="['h', 'e', 'l', 'l', 'o']")
}
```

## Array Operations

Common array operations include mapping, filtering, and folding:

```moonbit
test "array operations" {
  let nums = [1, 2, 3, 4, 5]

  // Filtering out odd numbers and negating the remaining
  let neg_evens = nums.filter_map(x => if x % 2 == 0 { Some(-x) } else { None })
  inspect(neg_evens, content="[-2, -4]")

  // Summing array
  let sum = nums.fold(init=0, (acc, x) => acc + x)
  inspect(sum, content="15")

  // Finding last element
  let last = nums.last()
  inspect(last, content="Some(5)")
}
```

## Sorting

The package provides various sorting utilities:

```moonbit
test "sorting" {
  let arr = [3, 1, 4, 1, 5, 9, 2, 6]

  // Basic sorting - creates new sorted array
  let sorted1 = arr.copy()
  sorted1.sort()
  inspect(sorted1, content="[1, 1, 2, 3, 4, 5, 6, 9]")

  // Custom comparison
  let strs = ["aa", "b", "ccc"]
  let sorted2 = strs.copy()
  sorted2.sort_by((a, b) => a.length().compare(b.length()))
  inspect(
    sorted2,
    content=(
      #|["b", "aa", "ccc"]
    ),
  )

  // Sort by key
  let pairs = [(2, "b"), (1, "a"), (3, "c")]
  let sorted3 = pairs.copy()
  sorted3.sort_by_key(p => p.0)
  inspect(
    sorted3,
    content=(
      #|[(1, "a"), (2, "b"), (3, "c")]
    ),
  )
}
```

## Array Views

Array views provide a lightweight way to work with array slices:

```moonbit
test "array views" {
  let arr = [1, 2, 3, 4, 5]
  let view = arr[1:4]
  inspect(view, content="[2, 3, 4]")

  // Map view to new array
  let doubled = view.map(x => x * 2)
  inspect(doubled, content="[4, 6, 8]")
}
```

## Fixed Arrays

Fixed arrays provide immutable array operations:

```moonbit
test "fixed arrays" {
  let fixed : FixedArray[_] = [1, 2, 3]

  // Concatenation creates new array
  let combined = fixed + [4, 5]
  inspect(combined, content="[1, 2, 3, 4, 5]")

  // Check for containment
  let has_two = fixed.contains(2)
  inspect(has_two, content="true")

  // Check if array starts/ends with sequence
  let starts = fixed.starts_with([1, 2])
  inspect(starts, content="true")
  let ends = fixed.ends_with([2, 3])
  inspect(ends, content="true")
}
```

## Utilities

Additional array utilities for common operations:

```moonbit
test "utilities" {
  // Join string array
  let words = ["hello", "world"]
  let joined = words.join(" ")
  inspect(joined, content="hello world")

  // Random shuffling
  let nums = [1, 2, 3, 4, 5]
  // Using deterministic `rand` function below for demonstration
  // NOTE: When using a normal `rand` function, the actual result may vary
  let shuffled = nums.shuffle(rand=(_) => { 1 })
  inspect(shuffled, content="[1, 3, 4, 5, 2]")
}
```

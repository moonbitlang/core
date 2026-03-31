# HashSet

A mutable hash set based on a Robin Hood hash table.

# Usage

## Create

You can create an empty set using `new()` or construct it using `from_array()`.

```mbt check
///|
test {
  let _set1 = @hashset.from_array([1, 2, 3, 4, 5])
  let _set2 : @hashset.HashSet[String] = @hashset.new()
}
```

## Insert & Contain

You can use `insert()` to add a key to the set, and `contains()` to check whether a key exists.

```mbt check
///|
test {
  let set : @hashset.HashSet[String] = @hashset.new()
  set.add("a")
  assert_eq(set.contains("a"), true)
}
```

## Remove

You can use `remove()` to remove a key.

```mbt check
///|
test {
  let set = @hashset.from_array(["a", "b", "c"])
  set.remove("a")
  assert_eq(set.contains("a"), false)
}
```

## Size & Capacity

You can use `size()` to get the number of keys in the set, or `capacity()` to get the current capacity.

```mbt check
///|
test {
  let set = @hashset.from_array(["a", "b", "c"])
  assert_eq(set.length(), 3)
  assert_eq(set.capacity(), 8)
}
```

Similarly, you can use `is_empty()` to check whether the set is empty.

```mbt check
///|
test {
  let set : @hashset.HashSet[Int] = @hashset.new()
  assert_eq(set.is_empty(), true)
}
```

## Clear

You can use `clear` to remove all keys from the set, but the allocated memory will not change.

```mbt check
///|
test {
  let set = @hashset.from_array(["a", "b", "c"])
  set.clear()
  assert_eq(set.is_empty(), true)
}
```

## Iteration

You can use `each()` or `eachi()` to iterate through all keys.

```mbt check
///|
test {
  let set = @hashset.from_array(["a", "b", "c"])
  let arr = []
  set.each(k => arr.push(k))
  let arr2 = []
  set.eachi((i, k) => arr2.push((i, k)))
}
```

## Add & Remove with Check

`add_and_check()` returns `true` if the element was newly added (not already present). `remove_and_check()` returns `true` if the element was actually removed.

```mbt check
///|
test {
  let set = @hashset.from_array([1, 2, 3])
  assert_eq(set.add_and_check(4), true) // new element
  assert_eq(set.add_and_check(4), false) // already exists
  assert_eq(set.remove_and_check(4), true) // removed
  assert_eq(set.remove_and_check(4), false) // not present
}
```

## Retain

`retain()` keeps only elements that satisfy a predicate, removing the rest in place.

```mbt check
///|
test {
  let set = @hashset.from_array([1, 2, 3, 4, 5])
  set.retain(fn(x) { x % 2 == 0 })
  assert_eq(set.contains(1), false)
  assert_eq(set.contains(2), true)
}
```

## Copy

`copy()` creates a shallow clone of the set.

```mbt check
///|
test {
  let set = @hashset.from_array([1, 2, 3])
  let cloned = set.copy()
  cloned.add(4)
  assert_eq(set.contains(4), false) // original unchanged
  assert_eq(cloned.contains(4), true)
}
```

## Iterators & Conversion

`iter()` returns an iterator. `to_array()` collects elements into an array. `from_iter()` constructs a set from an iterator.

```mbt check
///|
test {
  let set = @hashset.from_array([1, 2, 3])
  let arr = set.to_array()
  arr.sort()
  assert_eq(arr, [1, 2, 3])
  // from_iter
  let set2 = @hashset.from_iter([4, 5, 6].iter())
  assert_eq(set2.length(), 3)
}
```

## Set Operations

`union()`, `intersection()`, `difference()`, and `symmetric_difference()` return new sets. These also have operator aliases: `|` (union), `&` (intersection), `-` (difference), `^` (symmetric difference).

```mbt check
///|
test {
  let m1 = @hashset.from_array(["a", "b", "c"])
  let m2 = @hashset.from_array(["b", "c", "d"])
  fn to_sorted_array(set : @hashset.HashSet[String]) {
    let arr = set.to_array()
    arr.sort()
    arr
  }

  assert_eq(m1.union(m2) |> to_sorted_array, ["a", "b", "c", "d"])
  assert_eq(m1.intersection(m2) |> to_sorted_array, ["b", "c"])
  assert_eq(m1.difference(m2) |> to_sorted_array, ["a"])
  assert_eq(m1.symmetric_difference(m2) |> to_sorted_array, ["a", "d"])
  // operator aliases
  assert_eq((m1 | m2) |> to_sorted_array, ["a", "b", "c", "d"])
  assert_eq((m1 & m2) |> to_sorted_array, ["b", "c"])
  assert_eq((m1 - m2) |> to_sorted_array, ["a"])
  assert_eq((m1 ^ m2) |> to_sorted_array, ["a", "d"])
}
```

## Set Predicates

`is_subset()`, `is_superset()`, and `is_disjoint()` test set relationships.

```mbt check
///|
test {
  let small = @hashset.from_array([1, 2])
  let big = @hashset.from_array([1, 2, 3, 4])
  let other = @hashset.from_array([5, 6])
  assert_eq(small.is_subset(big), true)
  assert_eq(big.is_superset(small), true)
  assert_eq(small.is_disjoint(other), true)
  assert_eq(small.is_disjoint(big), false)
}
```


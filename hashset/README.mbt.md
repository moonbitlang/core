# HashSet

A mutable hash set based on a Robin Hood hash table.

# Usage

## Create

You can create an empty set using `new()` or construct it using `from_array()`.

```moonbit
test {
  let _set1 = @hashset.of([1, 2, 3, 4, 5])
  let _set2 : @hashset.T[String] = @hashset.new()
}
```

## Insert & Contain

You can use `insert()` to add a key to the set, and `contains()` to check whether a key exists.

```moonbit
test {
  let set : @hashset.T[String] = @hashset.new()
  set.add("a")
  assert_eq!(set.contains("a"), true)
}
```

## Remove

You can use `remove()` to remove a key.

```moonbit
test {
  let set = @hashset.of(["a", "b", "c"])
  set.remove("a")
  assert_eq!(set.contains("a"), false)
}
```

## Size & Capacity

You can use `size()` to get the number of keys in the set, or `capacity()` to get the current capacity.

```moonbit
test {
  let set = @hashset.of(["a", "b", "c"])
  assert_eq!(set.size(), 3)
  assert_eq!(set.capacity(), 8)
}
```

Similarly, you can use `is_empty()` to check whether the set is empty.

```moonbit
test {
  let set : @hashset.T[Int] = @hashset.new()
  assert_eq!(set.is_empty(), true)
}
```

## Clear

You can use `clear` to remove all keys from the set, but the allocated memory will not change.

```moonbit
test {
  let set = @hashset.of(["a", "b", "c"])
  set.clear()
  assert_eq!(set.is_empty(), true)
}
```

## Iteration

You can use `each()` or `eachi()` to iterate through all keys.

```moonbit
test {
  let set = @hashset.of(["a", "b", "c"])
  let arr = []
  set.each(fn(k) { arr.push(k) })
  let arr2 = []
  set.eachi(fn(i, k) { arr2.push((i, k)) })
}
```

## Set Operations

You can use `union()`, `intersection()`, `difference()` and `symmetric_difference()` to perform set operations.

```moonbit
test {
  let m1 = @hashset.of(["a", "b", "c"])
  let m2 = @hashset.of(["b", "c", "d"])
  assert_eq!(m1.union(m2).to_array()..sort(), ["a", "b", "c", "d"])
  assert_eq!(m1.intersection(m2).to_array()..sort(), ["b", "c"])
  assert_eq!(m1.difference(m2).to_array()..sort(), ["a"])
  assert_eq!(m1.symmetric_difference(m2).to_array()..sort(), ["a", "d"])
}
```


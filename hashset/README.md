# HashSet

A mutable hash set based on a Robin Hood hash table.

# Usage

## Create

You can create an empty set using `new()` or construct it using `from_array()`.

```moonbit
let set1 = @hashset.of([1, 2, 3, 4, 5])
let set2 : @hashset.T[String] = @hashset.new()
```

## Insert & Contain

You can use `insert()` to add a key to the set, and `contains()` to check whether a key exists.

```moonbit
let set : @hashset.T[String] = @hashset.new()
set.insert("a")
println(set.contains("a")) // true
```

## Remove

You can use `remove()` to remove a key.

```moonbit
let set = @hashset.of([("a"), ("b"), ("c")])
set.remove("a")
println(set.contains("a")) // false
```

## Size & Capacity

You can use `size()` to get the number of keys in the set, or `capacity()` to get the current capacity.

```moonbit
let set = @hashset.of([("a"), ("b"), ("c")])
println(set.size()) // 3
println(set.capacity()) // 8
```

Similarly, you can use `is_empty()` to check whether the set is empty.

```moonbit
let set = @hashset.new()
println(set.is_empty()) // true
```

## Clear

You can use `clear` to remove all keys from the set, but the allocated memory will not change.

```moonbit
let set = @hashset.of([("a"), ("b"), ("c")])
set.clear()
println(set.is_empty()) // true
```

## Iteration

You can use `each()` or `eachi()` to iterate through all keys.

```moonbit
let set = @hashset.of([("a"), ("b"), ("c")])
set.each(fn(k) { println("element: \{k}") })
set.eachi(fn(i, k) { println("index: \{i}, element:\{k}") })
```

## Set Operations

You can use `union()`, `intersection()`, `difference()` and `symmetric_difference()` to perform set operations.

```moonbit
let m1 = @hashset.of(["a", "b", "c"])
let m2 = @hashset.of(["b", "c", "d"])
println(m1.union(m2)) // of(["a", "b", "c", "d"])
println(m1.intersection(m2)) // of(["b", "c"])
println(m1.difference(m2)) // of(["a"])
println(m1.symmetric_difference(m2)) // of(["a", "d"])
```


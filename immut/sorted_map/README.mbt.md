# Immutable Map

An immutable tree map based on size balanced tree.

# Usage

## Create

You can create an empty map using `new()` or construct it with a single
key-value pair using `singleton()`.

```mbt check
///|
test {
  let map1 : @sorted_map.SortedMap[String, Int] = @sorted_map.new()
  let map2 = @sorted_map.singleton("a", 1)
  assert_eq(map1.length(), 0)
  assert_eq(map2.length(), 1)
}
```

Also, you can construct it from an array using `of()` or `from_array()`.

```mbt check
///|
test {
  let map = @sorted_map.from_array([("a", 1), ("b", 2), ("c", 3)])
  assert_eq(map.values().collect(), [1, 2, 3])
  assert_eq(map.keys_as_iter().collect(), ["a", "b", "c"])
}
```

## Insert & Lookup

You can use `add()` to add a key-value pair to the map and create a new map. Or
use `lookup()` to get the value associated with a key.

```mbt check
///|
test {
  let map : @sorted_map.SortedMap[String, Int] = @sorted_map.new()
  let map = map.add("a", 1)
  assert_eq(map.get("a"), Some(1))
}
```

## Remove

You can use `remove()` to remove a key-value pair from the map.

```mbt check
///|
test {
  let map = @sorted_map.from_array([("a", 1), ("b", 2), ("c", 3)])
  let map = map.remove("a")
  assert_eq(map.get("a"), None)
}
```

## Contains

You can use `contains()` to check whether a key exists.

```mbt check
///|
test {
  let map = @sorted_map.from_array([("a", 1), ("b", 2), ("c", 3)])
  assert_eq(map.contains("a"), true)
  assert_eq(map.contains("d"), false)
}
```

## Size

You can use `size()` to get the number of key-value pairs in the map.

```mbt check
///|
test {
  let map = @sorted_map.from_array([("a", 1), ("b", 2), ("c", 3)])
  assert_eq(map.length(), 3)
}
```

Similarly, you can use `is_empty()` to check whether the map is empty.

```mbt check
///|
test {
  let map : @sorted_map.SortedMap[String, Int] = @sorted_map.new()
  assert_eq(map.is_empty(), true)
}
```

## Traversal

Use `each()` or `eachi()` to iterate through all key-value pairs.

```mbt check
///|
test {
  let map = @sorted_map.from_array([("a", 1), ("b", 2), ("c", 3)])
  let arr = []
  map.each((k, v) => arr.push("key:\{k}, value:\{v}"))
  assert_eq(arr, ["key:a, value:1", "key:b, value:2", "key:c, value:3"])
  let arr = []
  map.eachi((i, k, v) => arr.push("index:\{i}, key:\{k}, value:\{v}"))
  assert_eq(arr, [
    "index:0, key:a, value:1", "index:1, key:b, value:2", "index:2, key:c, value:3",
  ])
}
```

Use `map_with_key()` to map a function over all values.

```mbt check
///|
test {
  let map = @sorted_map.from_array([("a", 1), ("b", 2), ("c", 3)])
  let map = map.map_with_key((_, v) => v + 1)
  assert_eq(map.values().collect(), [2, 3, 4])
  let map = map.map_with_key((_k, v) => v + 1)
  assert_eq(map.values().collect(), [3, 4, 5])
}
```

Use `foldl_with_key()` to fold the values in the map. The default order of fold
is Pre-order. Similarly, you can use `rev_fold()` to do a Post-order fold.

```mbt check
///|
test {
  let map = @sorted_map.from_array([("a", 1), ("b", 2), ("c", 3)])
  assert_eq(map.foldl_with_key((acc, _, v) => acc + v, init=0), 6) // 6
  assert_eq(
    map.foldl_with_key((acc, k, v) => acc + k + v.to_string(), init=""),
    "a1b2c3",
  ) // "a1b2c3"
  assert_eq(
    map.rev_fold((acc, k, v) => acc + k + v.to_string(), init=""),
    "c3b2a1",
  ) // "c3b2a1"
}
```

Use `filter_with_key()` to filter all keys/values that satisfy the predicate.

```mbt check
///|
test {
  let map = @sorted_map.from_array([("a", 1), ("b", 2), ("c", 3)])
  let map = map.filter_with_key((_, v) => v > 1)
  assert_eq(map.values().collect(), [2, 3])
  assert_eq(map.keys_as_iter().collect(), ["b", "c"])
  let map = map.filter_with_key((k, v) => k > "a" && v > 1)
  assert_eq(map.values().collect(), [2, 3])
  assert_eq(map.keys_as_iter().collect(), ["b", "c"])
}
```

## Conversion

Use `values()` to get all values in ascending order of their keys.

```mbt check
///|
test {
  let map = @sorted_map.from_array([("a", 1), ("b", 2), ("c", 3)])
  let values = map.values()
  assert_eq(values.collect(), [1, 2, 3])
}
```

Use `keys()` to get all keys of the map in ascending order.

```mbt check
///|
test {
  let map = @sorted_map.from_array([("a", 1), ("b", 2), ("c", 3)])
  let keys = map.keys_as_iter() // ["a", "b", "c"]
  assert_eq(keys.collect(), ["a", "b", "c"])
}
```

### Reverse Iteration

Use `rev_keys()` to get all keys in descending order.

```mbt check
///|
test {
  let map = @sorted_map.from_array([("a", 1), ("b", 2), ("c", 3)])
  let keys = map.rev_keys().collect()
  assert_eq(keys, ["c", "b", "a"])
}
```

Use `rev_values()` to get all values in descending order of their keys.

```mbt check
///|
test {
  let map = @sorted_map.from_array([("a", 1), ("b", 2), ("c", 3)])
  let values = map.rev_values().collect()
  assert_eq(values, [3, 2, 1])
}
```

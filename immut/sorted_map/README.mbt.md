
# Immutable Map

An immutable tree map based on size balanced tree.

# Usage

## Create

You can create an empty map using `new()` or construct it with a single key-value pair using `singleton()`.

```moonbit
test {
  let map1 : @sorted_map.T[String, Int] = @sorted_map.new()
  let map2 = @sorted_map.singleton("a", 1)
  assert_eq!(map1.size(), 0)
  assert_eq!(map2.size(), 1)
}
```

Also, you can construct it from an array using `of()` or `from_array()`.

```moonbit
test {
  let map = @sorted_map.of([("a", 1), ("b", 2), ("c", 3)])
  assert_eq!(map.elems(), [1, 2, 3])
  assert_eq!(map.keys(), ["a", "b", "c"])
}
```

## Insert & Lookup

You can use `add()` to add a key-value pair to the map and create a new map. Or use `lookup()` to get the value associated with a key.

```moonbit
test {
  let map : @sorted_map.T[String,Int] = @sorted_map.new()
  let map = map.add("a", 1)
  assert_eq!(map.lookup("a"), Some(1))
}
```

## Remove

You can use `remove()` to remove a key-value pair from the map.

```moonbit
test {
  let map = @sorted_map.of([("a", 1), ("b", 2), ("c", 3)])
  let map = map.remove("a")
  assert_eq!(map.lookup("a"), None)
}
```

## Contains

You can use `contains()` to check whether a key exists.

```moonbit
test {
  let map = @sorted_map.of([("a", 1), ("b", 2), ("c", 3)])
  assert_eq!(map.contains("a"), true)
  assert_eq!(map.contains("d"), false)
}
```

## Size

You can use `size()` to get the number of key-value pairs in the map.

```moonbit
test {
  let map = @sorted_map.of([("a", 1), ("b", 2), ("c", 3)])
  assert_eq!(map.size(), 3)
}
```

Similarly, you can use `is_empty()` to check whether the map is empty.

```moonbit
test {
  let map : @sorted_map.T[String, Int] = @sorted_map.new()
  assert_eq!(map.is_empty(), true)
}
```

## Traversal

Use `each()` or `eachi()` to iterate through all key-value pairs.

```moonbit
test {
  let map = @sorted_map.of([("a", 1), ("b", 2), ("c", 3)])
  let arr = []
  map.each(fn(k, v) { arr.push("key:\{k}, value:\{v}") })
  assert_eq!(arr, ["key:a, value:1", "key:b, value:2", "key:c, value:3"])
  let arr = []
  map.eachi(fn(i, k, v) { arr.push("index:\{i}, key:\{k}, value:\{v}") })
  assert_eq!(arr, ["index:0, key:a, value:1", "index:1, key:b, value:2", "index:2, key:c, value:3"])
}
```

Use `map()` or `map_with_key()` to map a function over all values.

```moonbit
test {
  let map = @sorted_map.of([("a", 1), ("b", 2), ("c", 3)])
  let map = map.map(fn(v) { v + 1 })
  assert_eq!(map.elems(), [2, 3, 4])
  let map = map.map_with_key(fn(_k, v) { v + 1 })
  assert_eq!(map.elems(), [3, 4, 5])
}
```

Use `fold()` or `foldl_with_key()` to fold the values in the map. The default order of fold is Pre-order.
Similarly, you can use `foldr_with_key()` to do a Post-order fold.

```moonbit
test {
  let map = @sorted_map.of([("a", 1), ("b", 2), ("c", 3)])
  assert_eq!(map.fold(fn (acc, v) { acc + v }, init=0), 6) // 6
  assert_eq!(map.foldl_with_key(fn (acc, k, v) { acc + k + v.to_string() }, init=""), "a1b2c3") // "a1b2c3"
  assert_eq!(map.foldr_with_key(fn (acc, k, v) { acc + k + v.to_string() }, init=""), "c3b2a1") // "c3b2a1"
}
```

Use `filter()` or `filter_with_key()` to filter all keys/values that satisfy the predicate.

```moonbit
test {
  let map = @sorted_map.of([("a", 1), ("b", 2), ("c", 3)])
  let map = map.filter(fn (v) { v > 1 })
  assert_eq!(map.elems(), [2, 3])
  assert_eq!(map.keys(), ["b", "c"])
  let map = map.filter_with_key(fn (k, v) { k > "a" && v > 1 })
  assert_eq!(map.elems(), [2, 3])
  assert_eq!(map.keys(), ["b", "c"])
}
```

## Conversion

Use `elems()` to get all values in ascending order of their keys.

```moonbit
test {
  let map = @sorted_map.of([("a", 1), ("b", 2), ("c", 3)])
  let elems = map.elems() // [1, 2, 3]
  assert_eq!(elems, [1, 2, 3])
}
```

Use `keys()` to get all keys of the map in ascending order.

```moonbit
test {
  let map = @sorted_map.of([("a", 1), ("b", 2), ("c", 3)])
  let keys = map.keys() // ["a", "b", "c"]
  assert_eq!(keys, ["a", "b", "c"])
}
```


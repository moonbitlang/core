# HashMap

A mutable hash map based on a Robin Hood hash table.

# Usage

## Create

You can create an empty map using `new()` or construct it using `from_array()`.

```mbt check
///|
test {
  let _map2 : @hashmap.HashMap[String, Int] = @hashmap.new()
}
```

## Set & Get

You can use `set()` to add a key-value pair to the map, and use `get()` to get a value.

```mbt check
///|
test {
  let map : @hashmap.HashMap[String, Int] = @hashmap.new()
  map.set("a", 1)
  assert_eq(map.get("a"), Some(1))
  assert_eq(map.get_or_default("a", 0), 1)
  assert_eq(map.get_or_default("b", 0), 0)
  map.remove("a")
  assert_eq(map.contains("a"), false)
}
```

## Remove

You can use `remove()` to remove a key-value pair.

```mbt check
///|
test {
  let map = @hashmap.from_array([("a", 1), ("b", 2), ("c", 3)])
  map.remove("a") |> ignore
  assert_false(map.contains("a"))
}
```

## Contains

You can use `contains()` to check whether a key exists.

```mbt check
///|
test {
  let map = @hashmap.from_array([("a", 1), ("b", 2), ("c", 3)])
  assert_eq(map.contains("a"), true)
  assert_eq(map.contains("d"), false)
}
```

## Size & Capacity

You can use `size()` to get the number of key-value pairs in the map, or `capacity()` to get the current capacity.

```mbt check
///|
test {
  let map = @hashmap.from_array([("a", 1), ("b", 2), ("c", 3)])
  assert_eq(map.length(), 3)
  assert_eq(map.capacity(), 8)
}
```

Similarly, you can use `is_empty()` to check whether the map is empty.

```mbt check
///|
test {
  let map : @hashmap.HashMap[String, Int] = @hashmap.new()
  assert_eq(map.is_empty(), true)
}
```

## Clear

You can use `clear` to remove all key-value pairs from the map, but the allocated memory will not change.

```mbt check
///|
test {
  let map = @hashmap.from_array([("a", 1), ("b", 2), ("c", 3)])
  map.clear()
  assert_eq(map.is_empty(), true)
}
```

## Iteration

You can use `each()` or `eachi()` to iterate through all key-value pairs.

```mbt check
///|
test {
  let map = @hashmap.from_array([("a", 1), ("b", 2), ("c", 3)])
  let arr = []
  map.each((k, v) => arr.push((k, v)))
  let arr2 = []
  map.eachi((i, k, v) => arr2.push((i, k, v)))
}
```

Or use `iter()`, `keys()`, or `values()` to get iterators:

```mbt check
///|
test {
  let map = @hashmap.from_array([("a", 1)])
  let _iter = map.iter()
  let _keys = map.keys()
  let _vals = map.values()
}
```

## Get or Initialize

Use `get_or_init()` to get a value or initialize it if missing:

```mbt check
///|
test {
  let map : @hashmap.HashMap[String, Int] = @hashmap.new()
  let val = map.get_or_init("key", () => 42)
  assert_eq(val, 42)
  assert_eq(map.get("key"), Some(42))
}
```

## Transform and Filter

Use `map()` to transform values and `retain()` to filter in place:

```mbt check
///|
test {
  let map = @hashmap.from_array([(1, "a"), (2, "b")])
  let mapped = map.map((k, _v) => k * 10)
  assert_eq(mapped.get(1), Some(10))
  let map2 = @hashmap.from_array([("a", 1), ("b", 2), ("c", 3)])
  map2.retain((_k, v) => v > 1)
  assert_eq(map2.contains("a"), false)
  assert_eq(map2.contains("b"), true)
}
```

## Merging

Use `merge()` to combine two maps:

```mbt check
///|
test {
  let m1 = @hashmap.from_array([("a", 1)])
  let m2 = @hashmap.from_array([("b", 2)])
  let merged = m1.merge(m2)
  assert_eq(merged.get("a"), Some(1))
  assert_eq(merged.get("b"), Some(2))
}
```

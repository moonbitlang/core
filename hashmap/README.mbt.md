# HashMap

A mutable hash map based on a Robin Hood hash table.

# Usage

## Create

You can create an empty map using `new()` or construct it from entries using `HashMap([...])`.

```mbt check
///|
test {
  let _map1 = @hashmap.HashMap([("a", 1), ("b", 2)])
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

## Index Access

Use subscript syntax `map[key]` for direct access. Panics if the key is not found.

```mbt check
///|
test {
  let map = @hashmap.from_array([("x", 10), ("y", 20)])
  assert_eq(map["x"], 10)
  map["z"] = 30
  assert_eq(map["z"], 30)
}
```

## Contains Key-Value

`contains_kv()` checks whether a specific key-value pair exists (not just the key).

```mbt check
///|
test {
  let map = @hashmap.from_array([("a", 1), ("b", 2)])
  assert_eq(map.contains_kv("a", 1), true)
  assert_eq(map.contains_kv("a", 99), false)
}
```

## Copy

`copy()` creates a shallow clone.

```mbt check
///|
test {
  let map = @hashmap.from_array([("a", 1)])
  let cloned = map.copy()
  cloned.set("b", 2)
  assert_eq(map.contains("b"), false) // original unchanged
}
```

## From Iterator

```mbt check
///|
test {
  let map = @hashmap.from_iter([("a", 1), ("b", 2)].iter())
  assert_eq(map.length(), 2)
}
```

## Merging

`merge()` returns a new map combining both. `merge_in_place()` mutates the receiver. On key conflicts, the right map's value wins.

```mbt check
///|
test {
  let m1 = @hashmap.from_array([("a", 1)])
  let m2 = @hashmap.from_array([("b", 2)])
  let merged = m1.merge(m2)
  assert_eq(merged.get("a"), Some(1))
  assert_eq(merged.get("b"), Some(2))
  // merge_in_place
  let m3 = @hashmap.from_array([("x", 1)])
  let m4 = @hashmap.from_array([("y", 2)])
  m3.merge_in_place(m4)
  assert_eq(m3.contains("y"), true)
}
```

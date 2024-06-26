# Moonbit/Core Map

## Overview

An immutable tree map based on the AVL tree.

## Usage

### Create

You can create an empty map using `empty()` or construct it with a single key-value pair using `singleton()`.

```moonbit
let map1 : Map[String, Int] = empty()
let map2 = singleton("a", 1)
```

Also, you can construct it from an array using `from_array()`.

```moonbit
let map = of([("a", 1), ("b", 2), ("c", 3)])
```

### Insert & Lookup

You can use `insert()` to add a key-value pair to the map and create a new map. Or use `lookup()` to get the value associated with a key.

```moonbit
let map : Map[String, Int] = empty()
let map = map.insert("a", 1)
map.lookup("a") // 1
```

### Remove

You can use `remove()` to remove a key-value pair from the map.

```moonbit
let map = of([("a", 1), ("b", 2), ("c", 3)])
let map = map.remove("a")
```

### Contains

You can use `contains()` to check whether a key exists.

```moonbit
let map = of([("a", 1), ("b", 2), ("c", 3)])
map.contains("a") // true
map.contains("d") // false
```

### Size

You can use `size()` to get the number of key-value pairs in the map.

```moonbit
let map = of([("a", 1), ("b", 2), ("c", 3)])
map.size() // 3
```

Similarly, you can use `is_empty()` to check whether the map is empty.

```moonbit
let map : Map[String, Int] = Map::empty()
map.is_empty() // true
```

### Traversal

Use `each()` or `iteri()` to iterate through all key-value pairs.

```moonbit
let map = of([("a", 1), ("b", 2), ("c", 3)])
map.each(fn(k, v) { println(\(k)-\(v)) })
map.iteri(fn(i, k, v) { println(\(i)-\(k)-\(v)) })
```

Use `map()` or `map_with_key()` to map a function over all values.

```moonbit
let map = of([("a", 1), ("b", 2), ("c", 3)])
let map = map.map(fn(v) { v + 1 })
let map = map.map_with_key(fn(_k, v) { v + 1 })
```

Use `fold()` or `foldl_with_key()` to fold the values in the map. The default order of fold is Pre-order.
Similarly, you can use `foldr_with_key()` to do a Post-order fold.

```moonbit
let map = of([("a", 1), ("b", 2), ("c", 3)])
map.fold(fn (acc, v) { acc + v }, ~init=0) // 6
map.foldl_with_key(fn (acc, k, v) { acc + k + v.to_string() }, ~init="") // "a1b2c3"
map.foldr_with_key(fn (acc, k, v) { acc + k + v.to_string() }, ~init="") // "c3b2a1"
```

Use `filter()` or `filter_with_key()` to filter all keys/values that satisfy the predicate.

```moonbit
let map = of([("a", 1), ("b", 2), ("c", 3)])
let map = map.filter(fn (v) { v > 1 })
let map = map.filter_with_key(fn (k, v) { k > "a" && v > 1 })
```

### Conversion

Use `elems()` to get all values in ascending order of their keys.

```moonbit
let map = of([("a", 1), ("b", 2), ("c", 3)])
let elems = map.elems() // [1, 2, 3]
```

Use `keys()` to get all keys of the map in ascending order.

```moonbit
let map = of([("a", 1), ("b", 2), ("c", 3)])
let keys = map.keys() // ["a", "b", "c"]
```

## TODO

- Set operations like `union`/`difference`/`intersection`

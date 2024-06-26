# Moonbit/Core HashMap

## Overview

A mutable hash map based on a Robin Hood hash table.

## Usage

### Create

You can create an empty map using `new()` or construct it using `from_array()`.

```moonbit
let map1 : HashMap[String, Int] = HashMap::new()
let map2 = of([1, 2, 3, 4, 5])
```

### Set & Get

You can use `set()` to add a key-value pair to the map, and use `get()` to get a key-value pair.

```moonbit
let map : HashMap[String, Int] = HashMap::new()
map.set("a", 1)
map.get("a") // 1
map.get_or_default("a", 0) // 1
map.get_or_default("b", 0) // 0
```

### Remove

You can use `remove()` to remove a key-value pair.

```moonbit
let map = of([("a", 1), ("b", 2), ("c", 3)])
map.remove("a")
```

### Contains

You can use `contains()` to check whether a key exists.

```moonbit
let map = of([("a", 1), ("b", 2), ("c", 3)])
map.contains("a") // true
map.contains("d") // false
```

### Size & Capacity

You can use `size()` to get the number of key-value pairs in the map, or `capacity()` to get the current capacity.

```moonbit
let map = of([("a", 1), ("b", 2), ("c", 3)])
map.size() // 3
map.capacity() // 8
```

Similarly, you can use `is_empty()` to check whether the map is empty.

```moonbit
let map : HashMap[String, Int] = HashMap::new()
map.is_empty() // true
```

### Clear

You can use `clear` to remove all key-value pairs from the map, but the allocated memory will not change.

```moonbit
let map = of([("a", 1), ("b", 2), ("c", 3)])
map.clear()
map.is_empty() // true
```

### Iter

You can use `iter()` or `iteri()` to iterate through all key-value pairs.

```moonbit
let map = of([("a", 1), ("b", 2), ("c", 3)])
map.iter(fn(k, v) { println("\(k)-\(v)") })
map.iteri(fn(i, k, v) { println("\(i)-\(k)-\(v)") })
```

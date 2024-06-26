# Moonbit/Core Map

## Overview

A mutable linked hash map based on a Robin Hood hash table, links all entry nodes in a linked list to mantains the order of insertion.

## Usage

### Create

You can create an empty map using `new()` or construct it using `from_array()`.

```moonbit
let map1 : Map[String, Int] = {}
let map2 = { "one" :  1 ,  "two" : 2, "three" : 3, "four" :  4, "five" :  5}
```

### Set & Get

You can use `set()` to add a key-value pair to the map, and use `get()` to get a key-value pair.

```moonbit
let map : Map[String, Int] = {}
map.set("a", 1)
map.get("a") // 1
map.get_or_default("a", 0) // 1
map.get_or_default("b", 0) // 0
```

### Remove

You can use `remove()` to remove a key-value pair.

```moonbit
let map = {"a" :  1, "b" :  2, "c" :  3}
map.remove("a")
```

### Contains

You can use `contains()` to check whether a key exists.

```moonbit
let map = {"a" : 1, "b" :  2, "c" :  3}
map.contains("a") // true
map.contains("d") // false
```

### Size & Capacity

You can use `size()` to get the number of key-value pairs in the map, or `capacity()` to get the current capacity.

```moonbit
let map = {"a" : 1, "b": 2, "c": 3}
map.size() // 3
map.capacity() // 8
```

Similarly, you can use `is_empty()` to check whether the map is empty.

```moonbit
let map : Map[String, Int] = {}
map.is_empty() // true
```

### Clear

You can use `clear` to remove all key-value pairs from the map, but the allocated memory will not change.

```moonbit
let map = {"a": 1,  "b": 2, "c": 3}
map.clear()
map.is_empty() // true
```

### Iter

You can use `each()` or `eachi()` to iterate through all key-value pairs in the order of insertion.

```moonbit
let map = {"a": 1, "b": 2, "c": 3}
map.each(fn(k, v) { println("\(k)-\(v)") })
map.eachi(fn(i, k, v) { println("\(i)-\(k)-\(v)") })
```

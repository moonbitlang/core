# Moonbit/Core Map

## Overview

A mutable linked hash map based on a Robin Hood hash table, links all entry nodes in a linked list to maintains the order of insertion.

## Usage

### Create

You can create an empty map using `new()` or construct it using `from_array()`.

```moonbit 
test {
  let _map1 : Map[String, Int] = {}
  let _map2 = { "one": 1, "two": 2, "three": 3, "four": 4, "five": 5 }

}
```

### Set & Get

You can use `set()` to add a key-value pair to the map, and use `get()` to get a key-value pair.

```moonbit
test {
  let map : Map[String, Int] = {}
  map.set("a", 1)
  assert_eq!(map.get("a"), Some(1))
  assert_eq!(map.get_or_default("a", 0), 1)
  assert_eq!(map.get_or_default("b", 0), 0)
  @json.inspect!(map, content={ "a": 1 })
  map.set("a", 2) // duplicate key
  @json.inspect!(map, content={ "a": 2 })
}
```

### Remove

You can use `remove()` to remove a key-value pair.

```moonbit
test {
  let map = { "a": 1, "b": 2, "c": 3 }
  map.remove("a")
  inspect!(
    map,
    content=
      #|{"b": 2, "c": 3}
    ,
  )
}
```

### Contains

You can use `contains()` to check whether a key exists.

```moonbit
test {
  let map = { "a": 1, "b": 2, "c": 3 }
  assert_eq!(map.contains("a"), true)
  assert_eq!(map.contains("d"), false)
}
```

### Size & Capacity

You can use `size()` to get the number of key-value pairs in the map, or `capacity()` to get the current capacity.

```moonbit
test {
  let map = { "a": 1, "b": 2, "c": 3 }
  assert_eq!(map.size(), 3)
  assert_eq!(map.capacity(), 8)
}
```

Similarly, you can use `is_empty()` to check whether the map is empty.

```moonbit
test {
  let map : Map[String, Int] = {}
  assert_eq!(map.is_empty(), true)
}
```

### Clear

You can use `clear` to remove all key-value pairs from the map, but the allocated memory will not change.

```moonbit
test {
  let map = { "a": 1, "b": 2, "c": 3 }
  map.clear()
  assert_eq!(map.is_empty(), true)
}
```

### Iter

You can use `each()` or `eachi()` to iterate through all key-value pairs in the order of insertion.

```moonbit
test {
  let map = { "a": 1, "b": 2, "c": 3 }
    let arr = []
    map.each(fn(k, v) { arr.push((k, v)) })
    assert_eq!(arr, [("a", 1), ("b", 2), ("c", 3)])
    let arr2 = []
    map.eachi(fn(i, k, v) { arr2.push((i, k, v)) })
    assert_eq!(arr2, [(0, "a", 1), (1, "b", 2), (2, "c", 3)])
}
```

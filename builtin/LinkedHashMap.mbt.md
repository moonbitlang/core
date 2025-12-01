# Moonbit/Core Map

## Overview

A mutable linked hash map based on a Robin Hood hash table, links all entry nodes in a linked list to maintains the order of insertion.

## Usage

### Create

You can create an empty map using `new()` or construct it using `from_array()`.

```mbt check 
///|
test {
  let _map1 : Map[String, Int] = {}
  let _map2 = { "one": 1, "two": 2, "three": 3, "four": 4, "five": 5 }

}
```

### Set & Get

You can use `set()` to add a key-value pair to the map, and use `get()` to get a key-value pair.

```mbt check
///|
test {
  let map : Map[String, Int] = {}
  map.set("a", 1)
  inspect(map.get("a"), content="Some(1)")
  inspect(map.get_or_default("a", 0), content="1")
  inspect(map.get_or_default("b", 0), content="0")
  @json.inspect(map, content={ "a": 1 })
  map.set("a", 2) // duplicate key
  @json.inspect(map, content={ "a": 2 })
}
```

#### Get from Views

For maps with `String` or `Bytes` keys, you can efficiently retrieve values using `StringView` or `BytesView` without creating new strings or bytes. This is useful when working with substrings or sub-arrays.

```mbt check
///|
test {
  // Using get_from_string with StringView
  let string_map = { "hello": 1, "world": 2 }
  let full_string = "say hello to everyone"
  let hello_view = full_string.view(start_offset=4, end_offset=9)
  inspect(string_map.get_from_string(hello_view), content="Some(1)")

  // Using get_from_bytes with BytesView
  let bytes_map = { b"key": 42, b"value": 100 }
  let full_bytes = b"mykey_data"
  let key_view = full_bytes[2:5]
  inspect(bytes_map.get_from_bytes(key_view), content="Some(42)")
}
```

### Remove

You can use `remove()` to remove a key-value pair.

```mbt check
///|
test {
  let map = { "a": 1, "b": 2, "c": 3 }
  map.remove("a")
  inspect(
    map,
    content=(
      #|{"b": 2, "c": 3}
    ),
  )
}
```

### Contains

You can use `contains()` to check whether a key exists.

```mbt check
///|
test {
  let map = { "a": 1, "b": 2, "c": 3 }
  inspect(map.contains("a"), content="true")
  inspect(map.contains("d"), content="false")
}
```

### Size & Capacity

You can use `size()` to get the number of key-value pairs in the map, or `capacity()` to get the current capacity.

```mbt check
///|
test {
  let map = { "a": 1, "b": 2, "c": 3 }
  inspect(map.length(), content="3")
  inspect(map.capacity(), content="4")
}
```

Similarly, you can use `is_empty()` to check whether the map is empty.

```mbt check
///|
test {
  let map : Map[String, Int] = {}
  inspect(map.is_empty(), content="true")
}
```

### Clear

You can use `clear` to remove all key-value pairs from the map, but the allocated memory will not change.

```mbt check
///|
test {
  let map = { "a": 1, "b": 2, "c": 3 }
  map.clear()
  inspect(map.is_empty(), content="true")
}
```

### Iter

You can use `each()` or `eachi()` to iterate through all key-value pairs in the order of insertion.

```mbt check
///|
test {
  let map = { "a": 1, "b": 2, "c": 3 }
  let arr = []
  map.each((k, v) => arr.push((k, v)))
  @json.inspect(arr, content=[["a", 1], ["b", 2], ["c", 3]])
  let arr2 = []
  map.eachi((i, k, v) => arr2.push((i, k, v)))
  @json.inspect(arr2, content=[[0, "a", 1], [1, "b", 2], [2, "c", 3]])
}
```

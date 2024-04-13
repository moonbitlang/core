# Moonbit/Core HashSet

## Overview

A mutable hash set based on a Robin Hood hash table.

## Usage

### Create

You can create an empty set using `new()` or construct it using `from_array()`.

```moonbit
let set1 : HashSet[String] = HashSet::new()
let set2 = HashSet::[1, 2, 3, 4, 5]
```

When creating via `new()`, you can set a custom hasher by providing a labeled argument `~hasher`. 

```moonbit
// Create with custom hasher.
let set = HashSet::new(~hasher=Some(fn(k) { k.length() }))
```

### Insert & Contain

You can use `insert()` to add a key to the set, and `contains()` to check whether a key exists.

```moonbit
let set : HashSet[String] = HashSet::new()
set.insert("a")
set.contains("a") // true
```

### Remove

You can use `remove()` to remove a key.

```moonbit
let set = HashSet::[("a"), ("b"), ("c")]
set.remove("a")
set.contains("a") // false
```

### Size & Capacity

You can use `size()` to get the number of keys in the set, or `capacity()` to get the current capacity.

```moonbit
let set = HashSet::[("a"), ("b"), ("c")]
set.size() // 3
set.capacity() // 8
```

Similarly, you can use `is_empty()` to check whether the set is empty.

```moonbit
let set : HashSet[String] = HashSet::new()
set.is_empty() // true
```

### Clear

You can use `clear` to remove all keys from the set, but the allocated memory will not change.

```moonbit
let set = HashSet::[("a"), ("b"), ("c")]
set.clear()
set.is_empty() // true
```

### Iter

You can use `iter()` or `iteri()` to iterate through all keys.

```moonbit
let set = HashSet::[("a"), ("b"), ("c")]
set.iter(fn(k) { println("\(k)") })
set.iteri(fn(i, k) { println("\(i)-\(k)") })
```

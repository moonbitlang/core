---
moonbit : true
---

# Sorted Map

A mutable map backed by an AVL tree that maintains keys in sorted order.

# Usage

## Create

You can create an empty SortedMap or a SortedMap from other containers.

```moonbit
let _map1 : @sorted_map.T[Int, String] = @sorted_map.new()
let _map2 = @sorted_map.from_array([(1, "one"), (2, "two"), (3, "three")])
```

## Container Operations

Add a key-value pair to the SortedMap in place.

```moonbit
let map = @sorted_map.from_array([(1, "one"), (2, "two")])
map.add(3, "three") 
assert_eq!(map.size(), 3)
```

You can also use the convenient subscript syntax to add or update values:

```moonbit
let map = @sorted_map.new()
map[1] = "one"
map[2] = "two"
assert_eq!(map.size(), 2)
```

Remove a key-value pair from the SortedMap in place.

```moonbit
let map = @sorted_map.from_array([(1, "one"), (2, "two"), (3, "three")])
map.remove(2) 
assert_eq!(map.size(), 2)
assert_eq!(map.contains(2), false)
```

Get a value by its key.

```moonbit
let map = @sorted_map.from_array([(1, "one"), (2, "two"), (3, "three")])
assert_eq!(map.get(2), Some("two"))
assert_eq!(map.get(4), None)
```

Check if a key exists in the map.

```moonbit
let map = @sorted_map.from_array([(1, "one"), (2, "two"), (3, "three")])
assert_eq!(map.contains(2), true)
assert_eq!(map.contains(4), false)
```

Iterate over all key-value pairs in the map in sorted key order.

```moonbit
let map = @sorted_map.from_array([(3, "three"), (1, "one"), (2, "two")])
let keys = []
let values = []
map.each(fn(k, v) { 
  keys.push(k)
  values.push(v)
})
assert_eq!(keys, [1, 2, 3])
assert_eq!(values, ["one", "two", "three"])
```

Iterate with index:

```moonbit
let map = @sorted_map.from_array([(3, "three"), (1, "one"), (2, "two")])
let result = []
map.eachi(fn(i, k, v) { 
  result.push((i, k, v))
})
assert_eq!(result, [(0, 1, "one"), (1, 2, "two"), (2, 3, "three")])
```

Get the size of the map.

```moonbit
let map = @sorted_map.from_array([(1, "one"), (2, "two"), (3, "three")])
assert_eq!(map.size(), 3)
```

Check if the map is empty.

```moonbit
let map : @sorted_map.T[Int, String] = @sorted_map.new()
assert_eq!(map.is_empty(), true)
```

Clear the map.

```moonbit
let map = @sorted_map.from_array([(1, "one"), (2, "two"), (3, "three")])
map.clear()
assert_eq!(map.is_empty(), true)
```

## Data Extraction

Get all keys or values from the map.

```moonbit
let map = @sorted_map.from_array([(3, "three"), (1, "one"), (2, "two")])
assert_eq!(map.keys(), [1, 2, 3])
assert_eq!(map.values(), ["one", "two", "three"])
```

Convert the map to an array of key-value pairs.

```moonbit
let map = @sorted_map.from_array([(3, "three"), (1, "one"), (2, "two")])
assert_eq!(map.to_array(), [(1, "one"), (2, "two"), (3, "three")])
```

## Range Operations

Get a subset of the map within a specified range of keys.

```moonbit
let map = @sorted_map.from_array([
  (1, "one"), (2, "two"), (3, "three"), 
  (4, "four"), (5, "five")
])
let range_items = []
map.range(2, 4).each(fn(k, v) {
  range_items.push((k, v))
})
assert_eq!(range_items, [(2, "two"), (3, "three"), (4, "four")])
```

## Iterators

Create a map from an iterator.

```moonbit
let pairs = [(1, "one"), (2, "two"), (3, "three")].iter()
let map = @sorted_map.from_iter(pairs)
assert_eq!(map.size(), 3)
```

## Equality

Maps with the same key-value pairs are considered equal.

```moonbit
let map1 = @sorted_map.from_array([(1, "one"), (2, "two")])
let map2 = @sorted_map.from_array([(2, "two"), (1, "one")])
assert_eq!(map1 == map2, true)

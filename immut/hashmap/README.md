# Immutable hashmap

This package provides an immutable hash map data structure.

## Basic usage

```mbt
test {
  let map = 
    @hashmap.new()
      .add("a", 1)
      .add("b", 2)
      .add("c", 3)
  assert_eq!(map.find("a"), Some(1))
  assert_eq!(map.find("d"), None)
}
```

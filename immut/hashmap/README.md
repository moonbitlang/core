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
  println(map.find("a")) // Some(1)
  println(map.find("d")) // None
}
```

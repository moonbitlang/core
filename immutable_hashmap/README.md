This package provides an immutable hash map data structure.

## Basic usage
```
test {
  let h =
    @immutable_hashmap.empty()
    .add(1, 1)
    .add(2, 2)
  let h2 = h.add(3, 3)
  @assert.assert_eq(h.find(3), None)
  @assert.assert_eq(h2.find(3), Some(3))
}
```

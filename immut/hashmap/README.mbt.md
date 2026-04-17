# Immutable HashMap

A persistent hash map based on hash array mapped tries (HAMT). All operations return new maps, leaving the original unchanged.

## Create

```mbt check
///|
test "create" {
  let empty : @hashmap.HashMap[String, Int] = @hashmap.new()
  inspect(empty.length(), content="0")
  let single = @hashmap.singleton("a", 1)
  debug_inspect(single.get("a"), content="Some(1)")
  let from_arr = @hashmap.from_array([("a", 1), ("b", 2)])
  inspect(from_arr.length(), content="2")
}
```

## Add, Get, Remove

`add` returns a new map with the key-value pair added. `remove` returns a new map with the key removed.

```mbt check
///|
test "add_get_remove" {
  let map = @hashmap.new().add("a", 1).add("b", 2)
  inspect(map.get("a"), content="Some(1)")
  inspect(map.contains("b"), content="true")
  inspect(map["a"], content="1")
  let map2 = map.remove("a")
  debug_inspect(map2.get("a"), content="None")
  // Original map is unchanged
  debug_inspect(map.get("a"), content="Some(1)")
}
```

## Iteration

```mbt check
///|
test "iteration" {
  let map = @hashmap.singleton("x", 10)
  let sum = map.fold(init=0, (acc, _k, v) => acc + v)
  inspect(sum, content="10")
  let keys = map.keys().to_array()
  inspect(keys, content="[\"x\"]")
  let vals = map.values().to_array()
  inspect(vals, content="[10]")
}
```

## Transform and Filter

```mbt check
///|
test "transform" {
  let map = @hashmap.from_array([("a", 1), ("b", 2), ("c", 3)])
  let doubled = map.map((_k, v) => v * 2)
  debug_inspect(doubled.get("b"), content="Some(4)")
  let filtered = map.filter((_k, v) => v > 1)
  inspect(filtered.contains("a"), content="false")
  inspect(filtered.contains("b"), content="true")
}
```

## Index Access

Use `map["key"]` (the `at` operator) for direct access. Panics if the key is not found.

```mbt check
///|
test "index_access" {
  let map = @hashmap.from_array([("x", 10), ("y", 20)])
  assert_eq(map["x"], 10)
  assert_eq(map["y"], 20)
}
```

## Iteration

`each` iterates over key-value pairs. `iter` and `iter2` return iterators. `keys` and `values` return iterators over keys or values only.

```mbt check
///|
test "iteration_full" {
  let map = @hashmap.singleton("a", 1)
  // each
  let buf = []
  map.each(fn(k, v) { buf.push((k, v)) })
  inspect(buf, content="[(\"a\", 1)]")
  // fold
  let sum = map.fold(init=0, fn(acc, _k, v) { acc + v })
  assert_eq(sum, 1)
  // keys / values
  inspect(map.keys().to_array(), content="[\"a\"]")
  inspect(map.values().to_array(), content="[1]")
  // to_array
  inspect(map.to_array(), content="[(\"a\", 1)]")
}
```

## Set Operations

`union` and `intersection` combine maps; `difference` removes keys. By default, `union` prefers the right map on key conflicts. Use `union_with` and `intersection_with` for custom merge logic.

```mbt check
///|
test "set_operations" {
  let m1 = @hashmap.from_array([("a", 1), ("b", 2)])
  let m2 = @hashmap.from_array([("b", 20), ("c", 3)])
  // Union prefers right map on conflicts
  let u = m1.union(m2)
  inspect(u.get("b"), content="Some(20)")
  inspect(u.get("c"), content="Some(3)")
  // union_with: custom merge function
  let u2 = m1.union_with(m2, fn(_k, v1, v2) { v1 + v2 })
  inspect(u2.get("b"), content="Some(22)") // 2 + 20
  // intersection_with: custom merge
  let i = m1.intersection_with(m2, fn(_k, v1, v2) { v1 * v2 })
  debug_inspect(i.get("b"), content="Some(40)") // 2 * 20
  inspect(i.contains("a"), content="false")
  // Difference keeps keys only in left
  let d = m1.difference(m2)
  debug_inspect(d.get("a"), content="Some(1)")
  inspect(d.contains("b"), content="false")
}
```

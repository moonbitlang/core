# Immutable HashMap

A persistent hash map based on hash array mapped tries (HAMT). All operations return new maps, leaving the original unchanged.

## Create

```mbt check
///|
test "create" {
  let empty : @hashmap.HashMap[String, Int] = @hashmap.new()
  inspect(empty.length(), content="0")
  let single = @hashmap.singleton("a", 1)
  inspect(single.get("a"), content="Some(1)")
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
  inspect(map2.get("a"), content="None")
  // Original map is unchanged
  inspect(map.get("a"), content="Some(1)")
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
  inspect(doubled.get("b"), content="Some(4)")
  let filtered = map.filter((_k, v) => v > 1)
  inspect(filtered.contains("a"), content="false")
  inspect(filtered.contains("b"), content="true")
}
```

## Set Operations

```mbt check
///|
test "set_operations" {
  let m1 = @hashmap.from_array([("a", 1), ("b", 2)])
  let m2 = @hashmap.from_array([("b", 20), ("c", 3)])
  // Union prefers right map on conflicts
  let u = m1.union(m2)
  inspect(u.get("b"), content="Some(20)")
  inspect(u.get("c"), content="Some(3)")
  // Intersection keeps keys present in both
  let i = m1.intersection(m2)
  inspect(i.length(), content="1")
  // Difference keeps keys only in left
  let d = m1.difference(m2)
  inspect(d.get("a"), content="Some(1)")
  inspect(d.contains("b"), content="false")
}
```

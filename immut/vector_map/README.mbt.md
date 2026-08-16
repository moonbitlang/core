# Immutable VectorMap

A persistent map that iterates in **insertion order** — the immutable counterpart of the built-in insertion-ordered `Map`. Operations return a map and never disturb the receiver.

Reach for it over `@immut/hashmap` when the order in which entries were added is part of what you are storing: rendering a list, replaying a log, or anything whose output a reader would notice being shuffled. Reach for `@immut/sorted_map` instead when you want entries in *key* order, and for `@immut/hashmap` when order does not matter at all — it is the leaner structure.

## Create

```mbt check
///|
test "create" {
  let empty : @vector_map.VectorMap[String, Int] = @vector_map.new()
  inspect(empty.is_empty(), content="true")
  let one = @vector_map.singleton("a", 1)
  inspect(one.length(), content="1")
  // The array keeps its order — this is not sorted by key.
  let m = @vector_map.VectorMap([("c", 3), ("a", 1), ("b", 2)])
  debug_inspect(
    m.keys().to_array(),
    content=(
      #|["c", "a", "b"]
    ),
  )
}
```

## Order

A key already in the map keeps its position when its value is replaced; a key that is new goes to the end. Removing a key and adding it back therefore moves it.

```mbt check
///|
test "order" {
  let m = @vector_map.VectorMap([("a", 1), ("b", 2), ("c", 3)])
  // replacing in place: "a" stays first
  debug_inspect(
    m.add("a", 10).keys().to_array(),
    content=(
      #|["a", "b", "c"]
    ),
  )
  // a fresh key is appended
  debug_inspect(
    m.add("d", 4).keys().to_array(),
    content=(
      #|["a", "b", "c", "d"]
    ),
  )
  // remove-then-add moves it to the end
  debug_inspect(
    m.remove("a").add("a", 1).keys().to_array(),
    content=(
      #|["b", "c", "a"]
    ),
  )
}
```

## Add, get, remove

```mbt check
///|
test "add_get_remove" {
  let m = @vector_map.new().add("a", 1).add("b", 2)
  debug_inspect(m.get("a"), content="Some(1)")
  inspect(m["b"], content="2")
  inspect(m.contains("z"), content="false")
  let smaller = m.remove("a")
  debug_inspect(smaller.get("a"), content="None")
  // the original is unchanged
  debug_inspect(m.get("a"), content="Some(1)")
}
```

`update` covers insert, replace and remove in one call, which is convenient when folding a change into existing state:

```mbt check
///|
test "update" {
  let m = @vector_map.VectorMap([("hits", 1)])
  let bumped = m.update("hits", n => Some(n.unwrap_or(0) + 1))
  debug_inspect(bumped.get("hits"), content="Some(2)")
  let fresh = m.update("misses", n => Some(n.unwrap_or(0) + 1))
  debug_inspect(fresh.get("misses"), content="Some(1)")
  // returning None removes the key
  inspect(m.update("hits", _ => None).is_empty(), content="true")
}
```

## Traverse

Every traversal yields entries in insertion order.

```mbt check
///|
test "traverse" {
  let m = @vector_map.VectorMap([("c", 3), ("a", 1), ("b", 2)])
  debug_inspect(
    m.to_array(),
    content=(
      #|[("c", 3), ("a", 1), ("b", 2)]
    ),
  )
  inspect(m.fold(init=0, (acc, _, v) => acc + v), content="6")
  let labelled = []
  m.eachi((i, k, _) => labelled.push("\{i}:\{k}"))
  debug_inspect(
    labelled,
    content=(
      #|["0:c", "1:a", "2:b"]
    ),
  )
  for k, v in m {
    ignore((k, v))
  }
}
```

## Transform

`map` rewrites values, keeping every key where it is. `filter` keeps the entries you select, in their existing relative order.

```mbt check
///|
test "transform" {
  let m = @vector_map.VectorMap([("c", 3), ("a", 1), ("b", 2)])
  debug_inspect(
    m.map((_, v) => v * 10).to_array(),
    content=(
      #|[("c", 30), ("a", 10), ("b", 20)]
    ),
  )
  debug_inspect(
    m.filter((_, v) => v > 1).to_array(),
    content=(
      #|[("c", 3), ("b", 2)]
    ),
  )
}
```

## Equality, hashing and JSON

Order is part of the content: two maps holding the same entries in different orders are **not** equal, and generally do not hash alike. That is what you want when a reordering is a visible change.

```mbt check
///|
test "equality" {
  let ab = @vector_map.VectorMap([("a", 1), ("b", 2)])
  let ba = @vector_map.VectorMap([("b", 2), ("a", 1)])
  inspect(ab == ba, content="false")
  inspect(ab == @vector_map.new().add("a", 1).add("b", 2), content="true")
}
```

JSON is an array of `[key, value]` pairs rather than an object, so that the order survives the round trip and keys keep their type.

```mbt check
///|
test "json" {
  let m = @vector_map.VectorMap([(30, "c"), (10, "a")])
  json_inspect(m, content=[[30, "c"], [10, "a"]])
  let back : @vector_map.VectorMap[Int, String] = @json.from_json(Json(m))
  inspect(back == m, content="true")
}
```

## Skipping work on an unchanged map

Two operations are guaranteed to hand back the receiver itself rather than an equal copy: removing a key that is not there, and filtering with a predicate that rejects nothing. A caller that memoises on physical identity — re-rendering only when the map is a different object — is therefore not woken by either.

```mbt check
///|
test "no_op" {
  let m = @vector_map.VectorMap([("a", 1)])
  inspect(physical_equal(m.remove("absent"), m), content="true")
  inspect(physical_equal(m.filter((_, _) => true), m), content="true")
}
```

No such promise is made anywhere else, and in particular `add` always builds a new map even when the value it stores equals the one already there. Deciding otherwise would mean comparing values, and the only generic way to do that cheaply — `physical_equal` — is explicitly not something to hang semantics on. Check `get` yourself first if you need to skip a redundant write.

## How it works, and what it costs

Entries live in a persistent vector — the *spine* — in insertion order, and a persistent hash map — the *index* — maps each key to its slot. Iteration reads the spine straight through and never descends the hash trie, which is what makes traversing the whole map cheap; a lookup pays for both structures.

| Operation | Cost |
| --- | --- |
| `contains` | one trie descent |
| `get` | one trie descent, then one vector descent |
| `add` on an existing key | one trie descent, one vector descent to recover the stored key, then one vector path copied |
| `add` on a new key | one trie descent, one trie insertion, and usually only the vector's tail rewritten |
| `remove` | one trie descent, one trie removal, one vector write — plus the trimming or rebuild described below |
| `length`, `is_empty` | `O(1)` |
| iteration, `map`, `filter`, `to_array` | `O(n)` |

A trie descent is `O(log n)` for keys whose hashes are reasonably distributed. Keys that collide on the full hash share a bucket that is searched linearly, so an adversarial or badly written `Hash` degrades lookup, `add` and `remove` towards `O(n)` — this map inherits that from `@immut/hashmap` and does nothing to make it worse.

Removal punches a hole in the spine rather than shifting the entries after it, since shifting would invalidate the index entry for every one of them. Under continued removal, holes are reclaimed two ways:

- **Trimming.** A hole at the end of the spine is dropped at once, and dropping it can uncover more. Trimming `k` holes costs `k` vector pops, each of which may copy a tree path, so a single `remove` can cost `O(k log n)`.
- **Rebuilding.** Holes in the middle accumulate until the spine is **both** at least 32 slots long **and** holding more holes than live entries. Below that length the ratio is not worth acting on, so a small map really can sit on nine holes and one entry. When it does fire, the spine is rebuilt dense and the index renumbered onto the new slots, at `O(n)`.

Outside that cycle, a `filter` that rejects anything rebuilds the spine dense whatever its length, clearing every hole as a side effect; a `filter` that rejects nothing returns the receiver untouched, holes included.

Both reclamation paths above are amortised only along a single line of descent. Every hole trimmed or reclaimed was paid for by the removal that made it, but a program that repeatedly returns to a version from just before a trim or a rebuild and removes again will pay the same cost each time. This is a good trade when a map's history moves mostly forward — state that is updated, occasionally rewound — and a poor one under heavy branching with heavy deletion in each branch.

There is deliberately no positional lookup by rank. A slot is a physical position, holes and all, so exposing one would be either misleading or `O(n)`; iterate instead.

The design follows Immutable.js's `OrderedMap`, and answers the same problem as Scala's `VectorMap`.

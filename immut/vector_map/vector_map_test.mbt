// Copyright 2026 International Digital Economy Academy
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

///|
test "construction" {
  let empty : @vector_map.VectorMap[String, Int] = @vector_map.new()
  inspect(empty.length(), content="0")
  inspect(empty.is_empty(), content="true")
  let single = @vector_map.singleton("a", 1)
  debug_inspect(
    single.to_array(),
    content=(
      #|[("a", 1)]
    ),
  )
  let from_arr = @vector_map.VectorMap([("b", 2), ("a", 1), ("c", 3)])
  debug_inspect(
    from_arr.to_array(),
    content=(
      #|[("b", 2), ("a", 1), ("c", 3)]
    ),
  )
  let from_it = @vector_map.from_iter([|("b", 2), ("a", 1)|])
  debug_inspect(
    from_it.to_array(),
    content=(
      #|[("b", 2), ("a", 1)]
    ),
  )
}

///|
test "a repeated key keeps the first position and the last value" {
  let m = @vector_map.VectorMap([("a", 1), ("b", 2), ("a", 3), ("c", 4)])
  debug_inspect(
    m.to_array(),
    content=(
      #|[("a", 3), ("b", 2), ("c", 4)]
    ),
  )
  inspect(m.length(), content="3")
  // …exactly as repeated `add`s would leave it
  let built = @vector_map.new().add("a", 1).add("b", 2).add("a", 3).add("c", 4)
  assert_true(m == built)
}

///|
test "singleton builds a whole map, not just a spine" {
  // `to_array` reads only the spine, so a `singleton` that forgot to populate
  // its index would look right and then fail every keyed operation.
  let one = @vector_map.singleton("a", 1)
  inspect(one.length(), content="1")
  debug_inspect(one.get("a"), content="Some(1)")
  inspect(one.contains("a"), content="true")
  inspect(one["a"], content="1")
  inspect(one.remove("a").is_empty(), content="true")
  // replacing the value updates in place rather than appending a second entry
  debug_inspect(
    one.add("a", 2).to_array(),
    content=(
      #|[("a", 2)]
    ),
  )
  debug_inspect(
    one.update("a", v => Some(v.unwrap() + 10)).to_array(),
    content=(
      #|[("a", 11)]
    ),
  )
  assert_true(one == VectorMap([("a", 1)]))
}

///|
test "lookup" {
  let m = @vector_map.VectorMap([("a", 1), ("b", 2)])
  debug_inspect(m.get("a"), content="Some(1)")
  debug_inspect(m.get("z"), content="None")
  inspect(m["b"], content="2")
  inspect(m.contains("a"), content="true")
  inspect(m.contains("z"), content="false")
}

///|
test "panic at on a missing key" {
  let m : @vector_map.VectorMap[String, Int] = @vector_map.new()
  ignore(m["missing"])
}

///|
test "add keeps an existing key in place but appends a fresh one" {
  let m = @vector_map.VectorMap([("a", 1), ("b", 2), ("c", 3)])
  debug_inspect(
    m.add("b", 20).to_array(),
    content=(
      #|[("a", 1), ("b", 20), ("c", 3)]
    ),
  )
  debug_inspect(
    m.add("d", 4).to_array(),
    content=(
      #|[("a", 1), ("b", 2), ("c", 3), ("d", 4)]
    ),
  )
  // removing and re-adding moves the key to the end
  debug_inspect(
    m.remove("a").add("a", 1).to_array(),
    content=(
      #|[("b", 2), ("c", 3), ("a", 1)]
    ),
  )
  // the receiver is untouched throughout
  debug_inspect(
    m.to_array(),
    content=(
      #|[("a", 1), ("b", 2), ("c", 3)]
    ),
  )
}

///|
test "remove" {
  let m = @vector_map.VectorMap([("a", 1), ("b", 2), ("c", 3)])
  debug_inspect(
    m.remove("b").to_array(),
    content=(
      #|[("a", 1), ("c", 3)]
    ),
  )
  // removing the last entry, then the rest
  inspect(m.remove("c").remove("b").remove("a").is_empty(), content="true")
}

///|
test "a no-op returns the receiver itself" {
  // Callers that skip work when the map is physically unchanged depend on
  // these two, so they are contract rather than incidental optimisation.
  let m = @vector_map.VectorMap([("a", "x"), ("b", "y")])
  assert_true(physical_equal(m.remove("missing"), m))
  assert_true(physical_equal(m.filter((_, _) => true), m))
  // A holey receiver is handed back holes and all, rather than compacted.
  let holey = @vector_map.VectorMap([("a", "x"), ("gone", "z"), ("b", "y")]).remove(
    "gone",
  )
  assert_true(physical_equal(holey.filter((_, _) => true), holey))
  // …and a real change does not preserve identity
  assert_false(physical_equal(m.remove("a"), m))
  assert_false(physical_equal(m.filter((k, _) => k != "a"), m))
  // `add` makes no such promise, even when it stores the very value already
  // there: skipping the write would mean deciding equality with
  // `physical_equal`, which is documented as unsafe to hang semantics on. So it
  // allocates, and only compares equal.
  assert_true(m.add("a", m["a"]) == m)
  assert_false(physical_equal(m.add("a", m["a"]), m))
}

///|
test "update" {
  let m = @vector_map.VectorMap([("a", 1), ("b", 2)])
  // replace in place
  debug_inspect(
    m.update("a", v => Some(v.unwrap() + 10)).to_array(),
    content=(
      #|[("a", 11), ("b", 2)]
    ),
  )
  // insert, appending
  debug_inspect(
    m.update("c", _ => Some(3)).to_array(),
    content=(
      #|[("a", 1), ("b", 2), ("c", 3)]
    ),
  )
  // remove
  debug_inspect(
    m.update("a", _ => None).to_array(),
    content=(
      #|[("b", 2)]
    ),
  )
  // removing something absent is a no-op
  assert_true(m.update("z", _ => None) == m)
}

///|
test "traversals all agree on insertion order" {
  let m = @vector_map.VectorMap([("c", 3), ("a", 1), ("b", 2)])
  debug_inspect(
    m.keys().to_array(),
    content=(
      #|["c", "a", "b"]
    ),
  )
  debug_inspect(m.values().to_array(), content="[3, 1, 2]")
  let seen = []
  m.each((k, v) => seen.push("\{k}=\{v}"))
  debug_inspect(
    seen,
    content=(
      #|["c=3", "a=1", "b=2"]
    ),
  )
  let indexed = []
  m.eachi((i, k, _) => indexed.push("\{i}:\{k}"))
  debug_inspect(
    indexed,
    content=(
      #|["0:c", "1:a", "2:b"]
    ),
  )
  inspect(m.fold(init="", (acc, k, _) => acc + k), content="cab")
  let pairs = []
  for k, v in m {
    pairs.push((k, v))
  }
  debug_inspect(
    pairs,
    content=(
      #|[("c", 3), ("a", 1), ("b", 2)]
    ),
  )
}

///|
test "eachi numbers the live entries, not the underlying slots" {
  // "b" leaves a hole behind, which must not show up as a skipped index.
  let m = @vector_map.VectorMap([("a", 1), ("b", 2), ("c", 3)]).remove("b")
  let indexed = []
  m.eachi((i, k, _) => indexed.push("\{i}:\{k}"))
  debug_inspect(
    indexed,
    content=(
      #|["0:a", "1:c"]
    ),
  )
}

///|
test "map and filter preserve order" {
  let m = @vector_map.VectorMap([("c", 3), ("a", 1), ("b", 2)])
  debug_inspect(
    m.map((k, v) => "\{k}\{v}").to_array(),
    content=(
      #|[("c", "c3"), ("a", "a1"), ("b", "b2")]
    ),
  )
  debug_inspect(
    m.filter((_, v) => v != 1).to_array(),
    content=(
      #|[("c", 3), ("b", 2)]
    ),
  )
  // filtering everything out leaves an empty map
  inspect(m.filter((_, _) => false).is_empty(), content="true")
}

///|
test "equality is order sensitive" {
  let ab = @vector_map.VectorMap([("a", 1), ("b", 2)])
  let ba = @vector_map.VectorMap([("b", 2), ("a", 1)])
  assert_true(ab == ab)
  assert_false(ab == ba)
  assert_true(ab != ba)
  // equal content in equal order compares equal however it was built
  assert_true(ab == @vector_map.new().add("a", 1).add("b", 2))
  // A prefix is not equal to the whole — and this has to be checked from BOTH
  // sides. Comparing entry by entry only detects the short side running out
  // when it is on the right, so a length check that fired one way round would
  // leave `Eq` asymmetric.
  let a_only = @vector_map.singleton("a", 1)
  let empty : @vector_map.VectorMap[String, Int] = @vector_map.new()
  assert_false(ab == a_only)
  assert_false(a_only == ab)
  assert_false(ab == empty)
  assert_false(empty == ab)
  // same keys, same order, one different value
  assert_false(ab == VectorMap([("a", 1), ("b", 99)]))
  assert_false(ab == VectorMap([("a", 99), ("b", 2)]))
  // same order and values, one different key
  assert_false(ab == VectorMap([("a", 1), ("z", 2)]))
}

///|
test "equality ignores how the holes fell" {
  // Same live entries in the same order, but reached by different histories:
  // one spine carries a tombstone, the other does not.
  let punched = @vector_map.VectorMap([("a", 1), ("gone", 0), ("b", 2)]).remove(
    "gone",
  )
  let dense = @vector_map.VectorMap([("a", 1), ("b", 2)])
  assert_true(punched == dense)
  let h1 = Hasher()
  h1.combine(punched)
  let h2 = Hasher()
  h2.combine(dense)
  inspect(h1.finalize() == h2.finalize(), content="true")
}

///|
fn[K : Hash, V : Hash] hash_of(map : @vector_map.VectorMap[K, V]) -> Int {
  let hasher = Hasher()
  hasher.combine(map)
  hasher.finalize()
}

///|
test "every part of an entry feeds the hash" {
  // Only "equal maps hash equally" is a contract — unequal maps are always free
  // to collide. Each case below pins one concrete pair, so that a hash which
  // quietly stopped folding in the keys or the values would show up rather than
  // passing on the strength of the component it still folds in.
  let ab = @vector_map.VectorMap([("a", 1), ("b", 2)])
  // keys: same values, same order
  inspect(
    hash_of(ab) == hash_of(VectorMap([("x", 1), ("y", 2)])),
    content="false",
  )
  // values: same keys, same order
  inspect(
    hash_of(ab) == hash_of(VectorMap([("a", 9), ("b", 8)])),
    content="false",
  )
  // Shorter maps: nothing folds the length in explicitly, so these check that
  // feeding the entries in sequence is enough to separate a prefix anyway.
  inspect(
    hash_of(ab) == hash_of(@vector_map.singleton("a", 1)),
    content="false",
  )
  let empty : @vector_map.VectorMap[String, Int] = @vector_map.new()
  inspect(hash_of(ab) == hash_of(empty), content="false")
}

///|
test "hashing distinguishes the orderings" {
  // Guards against the hash silently becoming order-insensitive the way
  // `@immut/hashmap`'s deliberately is.
  let ab = @vector_map.VectorMap([("a", 1), ("b", 2)])
  let ba = @vector_map.VectorMap([("b", 2), ("a", 1)])
  let h1 = Hasher()
  h1.combine(ab)
  let h2 = Hasher()
  h2.combine(ba)
  inspect(h1.finalize() == h2.finalize(), content="false")
}

///|
test "Debug for VectorMap" {
  let m = @vector_map.VectorMap([(2, "b"), (1, "a")])
  @debug.debug_inspect(
    m,
    content=(
      #|<VectorMap: { 2: "b", 1: "a" }>
    ),
  )
}

///|
test "json round trip keeps the order and the key type" {
  let m = @vector_map.VectorMap([(30, "c"), (10, "a"), (20, "b")])
  json_inspect(m, content=[[30, "c"], [10, "a"], [20, "b"]])
  let back : @vector_map.VectorMap[Int, String] = @json.from_json(Json(m))
  assert_true(back == m)
}

///|
test "json decoding rejects malformed input, pointing at it" {
  // An object cannot carry an order, so it is refused outright.
  let bad : Json = { "a": 1 }
  try (@json.from_json(bad) : @vector_map.VectorMap[Int, Int]) |> ignore catch {
    JsonDecodeError((path, msg)) => {
      inspect(
        path,
        content=(
          #|
        ),
      )
      inspect(msg, content="@immut/vector_map.from_json: expected array")
    }
  } noraise {
    _ => fail("expected an object to be rejected")
  }
  // A pair of the wrong width is reported at the offending entry, not at the
  // root — the path is what makes a decode failure diagnosable.
  let ragged : Json = [[0, 0], [1]]
  try
    (@json.from_json(ragged) : @vector_map.VectorMap[Int, Int]) |> ignore
  catch {
    JsonDecodeError((path, msg)) => {
      inspect(
        path,
        content=(
          #|/1
        ),
      )
      inspect(
        msg,
        content="@immut/vector_map.from_json: expected [key, value] pair",
      )
    }
  } noraise {
    _ => fail("expected a one-element pair to be rejected")
  }
  // A malformed KEY is reported at position 0 of its pair, a malformed value
  // at position 1 — the two halves are decoded under different paths, so both
  // need pinning.
  let bad_key : Json = [[0, 0], ["not an int", 1]]
  try
    (@json.from_json(bad_key) : @vector_map.VectorMap[Int, Int]) |> ignore
  catch {
    JsonDecodeError((path, _)) =>
      inspect(
        path,
        content=(
          #|/1/0
        ),
      )
  } noraise {
    _ => fail("expected a mistyped key to be rejected")
  }
  // A value of the wrong type is reported inside the pair.
  let mistyped : Json = [[0, "not an int"]]
  try
    (@json.from_json(mistyped) : @vector_map.VectorMap[Int, Int]) |> ignore
  catch {
    JsonDecodeError((path, _)) =>
      inspect(
        path,
        content=(
          #|/0/1
        ),
      )
  } noraise {
    _ => fail("expected a mistyped value to be rejected")
  }
}

///|
test "json decoding applies the same duplicate-key rule as construction" {
  // Decoding goes through the same builder as `VectorMap([...])`, so a repeated
  // key keeps its first position and its last value rather than appearing twice.
  let dup : Json = [[1, "a"], [2, "b"], [1, "z"]]
  let m : @vector_map.VectorMap[Int, String] = @json.from_json(dup)
  debug_inspect(
    m.to_array(),
    content=(
      #|[(1, "z"), (2, "b")]
    ),
  )
  assert_true(m == VectorMap([(1, "a"), (2, "b"), (1, "z")]))
}

///|
test "removals past the compaction threshold keep every promise" {
  // 200 entries is well past `MIN_COMPACT_LENGTH`, so dropping most of them
  // forces at least one rebuild of both the spine and the index.
  let m = @vector_map.from_iter((0).until(200).map(i => (i, i * i)))
  let sparse = (0)
    .until(200)
    .fold(init=m, (acc, i) => if i % 5 == 0 { acc } else { acc.remove(i) })
  inspect(sparse.length(), content="40")
  debug_inspect(
    sparse.keys().to_array()[:5].to_owned(),
    content="[0, 5, 10, 15, 20]",
  )
  // Every survivor still resolves THROUGH THE INDEX, and to the value it was
  // given. Iterating would only read the spine, so it would not notice an index
  // left pointing at the pre-rebuild slots; `get` and `contains` are the only
  // black-box operations that go through it.
  for i in 0..<200 {
    if i % 5 == 0 {
      assert_true(sparse.contains(i))
      assert_eq(sparse.get(i), Some(i * i))
    } else {
      assert_false(sparse.contains(i))
      assert_eq(sparse.get(i), None)
    }
  }
  // and the surviving order matches a map built dense from the start
  assert_true(sparse == @vector_map.from_iter(sparse.iter()))
  // the original is untouched by all of it
  inspect(m.length(), content="200")
}

///|
/// A key whose identity is its `name` alone: two `TaggedKey`s with the same
/// name are `Eq` and hash alike, but carry a `tag` that says which of them a
/// map actually kept. Without a key like this, "the first key is retained" is
/// unobservable — repeating an identical `String` proves nothing.
priv struct TaggedKey {
  name : String
  tag : Int
}

///|
impl Eq for TaggedKey with fn equal(self, other) {
  self.name == other.name
}

///|
impl Hash for TaggedKey with fn hash_combine(self, hasher) {
  hasher.combine_string(self.name)
}

///|
test "a replaced entry keeps the key it was first inserted with" {
  let first = { name: "k", tag: 1 }
  let second = { name: "k", tag: 2 }
  let third = { name: "k", tag: 3 }
  // Bulk construction: last value wins, but the key stays the first one, so
  // that the retained key and the retained position come from one insertion.
  let built = @vector_map.VectorMap([(first, "x"), (second, "y")])
  inspect(built.length(), content="1")
  inspect(built.to_array()[0].0.tag, content="1")
  inspect(built.to_array()[0].1, content="y")
  // `add` over an existing key behaves the same way.
  let updated = built.add(third, "z")
  inspect(updated.to_array()[0].0.tag, content="1")
  inspect(updated.to_array()[0].1, content="z")
  // …and after the key has been removed, the next one inserted is kept,
  // because there is no earlier key left to retain.
  let reinserted = built.remove(first).add(third, "z")
  inspect(reinserted.to_array()[0].0.tag, content="3")
}

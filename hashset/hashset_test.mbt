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
let default_init_capacity = 8

///|
priv struct HashSetKey(Int, Int) derive(Eq)

///|
impl Hash for HashSetKey with fn hash(self) {
  let HashSetKey(_, hash) = self
  hash
}

///|
impl Hash for HashSetKey with fn hash_combine(self, hasher) {
  let HashSetKey(_, hash) = self
  hasher.combine_int(hash)
}

///|
test "new_with_capacity_then_add " {
  let set : @hashset.HashSet[(String, String)] = HashSet([], capacity=20)
  set.add(("None", "Hash"))
  debug_inspect(
    set,
    content=(
      #|<HashSet: [("None", "Hash")]>
    ),
  )
}

///|
test "to_array" {
  let v = @hashset.from_array([1, 2, 3, 4])
  let arr = v.to_array()
  arr.sort()
  debug_inspect(arr, content="[1, 2, 3, 4]")
}

///|
test "add_and_check" {
  let set : @hashset.HashSet[String] = HashSet([])
  inspect(set.add_and_check("key"), content="true") // First insertion
  inspect(set.add_and_check("key"), content="false") // Already exists
  inspect(set.length(), content="1")
}

///|
test "remove_and_check" {
  let set = @hashset.from_array(["a", "b"])
  inspect(set.remove_and_check("a"), content="true") // Successfully removed
  inspect(set.remove_and_check("a"), content="false") // Already removed
  inspect(set.length(), content="1")
}

///|
test "copy" {
  let set = @hashset.from_array(["a", "b", "c"])
  let copied = set.copy()
  inspect(copied.length(), content="3")
  inspect(copied.contains("a"), content="true")
  inspect(copied.contains("b"), content="true")
  inspect(copied.contains("c"), content="true")
  // Modify original, copy should be unaffected
  set.remove("a")
  inspect(set.length(), content="2")
  inspect(copied.length(), content="3")
}

///|
test "to_json" {
  let data = [1, 2, 3]
  let set = @hashset.from_array([1, 2, 3])
  let json = @json.to_json(set)
  guard json is Array(array) else { fail("Expected JSON array") }
  for item in data {
    assert_true(array.contains(Json(item)))
  }
  @test.assert_eq(array.length(), 3)
}

///|
test "new" {
  let m : @hashset.HashSet[Int] = HashSet([])
  @test.assert_eq(m.capacity(), default_init_capacity)
  inspect(m.length(), content="0")
}

///|
test "new with zero capacity grows on insert" {
  let m : @hashset.HashSet[Int] = HashSet([], capacity=0)
  m.add(1)
  assert_true(m.contains(1))
  assert_true(m.capacity() > 0)
}

///|
test "default" {
  let m : @hashset.HashSet[Int] = Default::default()
  inspect(m.length(), content="0")
}

///|
test "insert" {
  let m = @hashset.HashSet([])
  m.add("a")
  m.add("b")
  m.add("c")
  assert_true(m.contains("a"))
  assert_true(m.contains("b"))
  assert_true(m.contains("c"))
  assert_false(m.contains("d"))
}

///|
test "of" {
  let m = @hashset.from_array(["a", "b", "c"])
  assert_true(m.contains("a"))
  assert_true(m.contains("b"))
  assert_true(m.contains("c"))
  assert_false(m.contains("d"))
}

///|
test "from_array" {
  let arr : ReadOnlyArray[String] = ["a", "b", "c"]
  let m = @hashset.from_array(arr)
  assert_true(m.contains("a"))
  assert_true(m.contains("b"))
  assert_true(m.contains("c"))
  assert_false(m.contains("d"))
}

///|
test "HashSet constructor" {
  let m = @hashset.HashSet(["a", "b", "c"])
  assert_true(m.contains("a"))
  assert_true(m.contains("b"))
  assert_true(m.contains("c"))
  assert_false(m.contains("d"))
}

///|
test "size" {
  let m = @hashset.HashSet([])
  inspect(m.length(), content="0")
  m.add("a")
  inspect(m.length(), content="1")
}

///|
test "is_empty" {
  let m = @hashset.HashSet([])
  inspect(m.is_empty(), content="true")
  m.add("a")
  inspect(m.is_empty(), content="false")
  m.remove("a")
  inspect(m.is_empty(), content="true")
}

///|
test "iter" {
  let m = @hashset.from_array(["a", "b", "c"]).iter().collect()
  m.sort()
  debug_inspect(
    m,
    content=(
      #|["a", "b", "c"]
    ),
  )
}

///|
test "iteri" {
  let m = @hashset.from_array(["1", "2", "3"])
  let s = []
  let mut sum = 0
  m.eachi((i, k) => {
    sum += i
    s.push(k)
  })
  s.sort()
  debug_inspect(
    s,
    content=(
      #|["1", "2", "3"]
    ),
  )
  inspect(sum, content="3")
}

///|
test "union" {
  let m1 = @hashset.from_array(["a", "b", "c"])
  let m2 = @hashset.from_array(["b", "c", "d"])
  let m = m1.union(m2)
  inspect(m.length(), content="4")
  assert_true(m.contains("a"))
  assert_true(m.contains("b"))
  assert_true(m.contains("c"))
  assert_true(m.contains("d"))
}

///|
test "intersection" {
  let m1 = @hashset.from_array(["a", "b", "c"])
  let m2 = @hashset.from_array(["b", "c", "d"])
  let m = m1.intersection(m2)
  inspect(m.length(), content="2")
  assert_false(m.contains("a"))
  assert_true(m.contains("b"))
  assert_true(m.contains("c"))
  assert_false(m.contains("d"))
}

///|
test "difference" {
  let m1 = @hashset.from_array(["a", "b", "c"])
  let m2 = @hashset.from_array(["b", "c", "d"])
  let m = m1.difference(m2)
  inspect(m.length(), content="1")
  assert_true(m.contains("a"))
  assert_false(m.contains("b"))
  assert_false(m.contains("c"))
  assert_false(m.contains("d"))
}

///|
test "symmetric_difference" {
  let m1 = @hashset.from_array(["a", "b", "c"])
  let m2 = @hashset.from_array(["b", "c", "d"])
  let m = m1.symmetric_difference(m2)
  inspect(m.length(), content="2")
  assert_true(m.contains("a"))
  assert_false(m.contains("b"))
  assert_false(m.contains("c"))
  assert_true(m.contains("d"))
}

///|
test "is_disjoint" {
  let m1 = @hashset.from_array(["a", "b", "c"])
  let m2 = @hashset.from_array(["b", "c", "d"])
  inspect(m1.is_disjoint(m2), content="false")
  let m1 = @hashset.from_array(["a", "b", "c"])
  let m2 = @hashset.from_array(["e", "f", "g"])
  inspect(m1.is_disjoint(m2), content="true")
}

///|
test "is_subset" {
  let m1 = @hashset.from_array(["a", "b", "c"])
  let m2 = @hashset.from_array(["b", "c", "d"])
  inspect(m1.is_subset(m2), content="false")
  let m1 = @hashset.from_array(["a", "b", "c"])
  let m2 = @hashset.from_array(["a", "b", "c", "d"])
  inspect(m1.is_subset(m2), content="true")
}

///|
test "is_superset" {
  let m1 = @hashset.from_array(["a", "b", "c"])
  let m2 = @hashset.from_array(["b", "c", "d"])
  inspect(m1.is_superset(m2), content="false")
  let m1 = @hashset.from_array(["a", "b", "c", "d"])
  let m2 = @hashset.from_array(["a", "b", "c"])
  inspect(m1.is_superset(m2), content="true")
}

///|
test "land" {
  let m1 = @hashset.from_array(["a", "b", "c"])
  let m2 = @hashset.from_array(["b", "c", "d"])
  let m = m1 & m2
  inspect(m.length(), content="2")
  assert_false(m.contains("a"))
  assert_true(m.contains("b"))
  assert_true(m.contains("c"))
  assert_false(m.contains("d"))
}

///|
test "lor" {
  let m1 = @hashset.from_array(["a", "b", "c"])
  let m2 = @hashset.from_array(["b", "c", "d"])
  let m = m1 | m2
  inspect(m.length(), content="4")
  assert_true(m.contains("a"))
  assert_true(m.contains("b"))
  assert_true(m.contains("c"))
  assert_true(m.contains("d"))
}

///|
test "lxor" {
  let m1 = @hashset.from_array(["a", "b", "c"])
  let m2 = @hashset.from_array(["b", "c", "d"])
  let m = m1 ^ m2
  inspect(m.length(), content="2")
  assert_true(m.contains("a"))
  assert_false(m.contains("b"))
  assert_false(m.contains("c"))
  assert_true(m.contains("d"))
}

///|
test "sub" {
  let m1 = @hashset.from_array(["a", "b", "c"])
  let m2 = @hashset.from_array(["b", "c", "d"])
  let m = m1 - m2
  inspect(m.length(), content="1")
  assert_true(m.contains("a"))
  assert_false(m.contains("b"))
  assert_false(m.contains("c"))
  assert_false(m.contains("d"))
}

///|
test "insert_and_grow" {
  let m = @hashset.HashSet([])
  for i in 0..<10 {
    m.add(i.to_string())
  }
  inspect(m.length(), content="10")
  inspect(m.capacity(), content="16")
}

///|
test "grow rehashes collision cluster" {
  let set : @hashset.HashSet[HashSetKey] = HashSet([], capacity=2)
  for i in 0..<12 {
    set.add(HashSetKey(i, i % 4))
  }
  inspect(set.length(), content="12")
  for i in 0..<12 {
    assert_true(set.contains(HashSetKey(i, i % 4)))
  }
  set.remove(HashSetKey(5, 1))
  assert_false(set.contains(HashSetKey(5, 1)))
  set.add(HashSetKey(12, 0))
  assert_true(set.contains(HashSetKey(12, 0)))
  inspect(set.length(), content="12")
}

///|
test "remove_and_shift_back" {
  let m = @hashset.HashSet([])
  m.add("a")
  m.add("b")
  m.add("c")
  m.add("d")
  m.remove("b")
  assert_false(m.contains("b"))
  assert_true(m.contains("a"))
  assert_true(m.contains("c"))
  assert_true(m.contains("d"))
}

///|
test "capacity_and_size" {
  let m = @hashset.HashSet([])
  @test.assert_eq(m.capacity(), default_init_capacity)
  inspect(m.length(), content="0")
  m.add("a")
  inspect(m.length(), content="1")
}

///|
test "clear_and_reinsert" {
  let m = @hashset.HashSet([])
  m.add("a")
  m.add("b")
  m.clear()
  inspect(m.length(), content="0")
  m.add("c")
  inspect(m.length(), content="1")
  assert_true(m.contains("c"))
}

///|
test "from_iter multiple elements iter" {
  let array = @hashset.from_iter([|1, 2, 3|]).to_array()
  array.sort()
  debug_inspect(array, content="[1, 2, 3]")
}

///|
test "from_iter single element iter" {
  debug_inspect(
    @hashset.from_iter([|1|]),
    content=(
      #|<HashSet: [1]>
    ),
  )
}

///|
test "from_iter empty iter" {
  let map : @hashset.HashSet[Int] = @hashset.from_iter([||])
  debug_inspect(
    map,
    content=(
      #|<HashSet: []>
    ),
  )
}

///|
test "@hashset.to_array/empty" {
  let set : @hashset.HashSet[Int] = HashSet([])
  debug_inspect(set.to_array(), content="[]")
}

///|
test "@hashset.to_array/single" {
  let set = @hashset.HashSet([])
  set.add(42)
  debug_inspect(set.to_array(), content="[42]")
}

///|
test "@hashset.to_array/multiple" {
  let set = @hashset.HashSet([])
  set.add(1)
  set.add(2)
  set.add(3)
  set.add(4)
  let arr = set.to_array()
  arr.sort()
  debug_inspect(arr, content="[1, 2, 3, 4]")
}

///|
test "retain/partial" {
  let set = @hashset.from_array([1, 2, 3, 4, 5, 6])
  set.retain(x => x % 2 == 0)
  @test.assert_eq(set.length(), 3)
  assert_true(set.contains(2))
  assert_true(set.contains(4))
  assert_true(set.contains(6))
  assert_false(set.contains(1))
  assert_false(set.contains(3))
  assert_false(set.contains(5))
}

///|
test "retain/all_removed" {
  let set = @hashset.from_array([1, 2, 3])
  set.retain(_x => false)
  @test.assert_eq(set.length(), 0)
  assert_true(set.is_empty())
}

///|
test "retain/none_removed" {
  let set = @hashset.from_array([1, 2, 3])
  set.retain(_x => true)
  @test.assert_eq(set.length(), 3)
}

///|
test "retain/empty_set" {
  let set : @hashset.HashSet[Int] = HashSet([])
  set.retain(_x => true)
  @test.assert_eq(set.length(), 0)
}

///|
test "filter keeps lookups working after removals and collisions" {
  // Small table, colliding hashes, and elements removed before filtering.
  let s : @hashset.HashSet[Int] = HashSet([], capacity=2)
  for i in 0..<200 {
    s.add(i * 64)
  }
  for i in 0..<200 {
    if i % 7 == 0 {
      s.remove(i * 64)
    }
  }
  let kept = s.filter(k => k % 3 == 0)
  for i in 0..<200 {
    assert_eq(kept.contains(i * 64), i % 7 != 0 && i * 64 % 3 == 0)
  }
  let actual = kept.to_array()
  actual.sort()
  let expected = [ for k in s if k % 3 == 0 => k ]
  expected.sort()
  assert_eq(actual, expected)
  // The result is an independent, growable set.
  kept.add(-1)
  assert_true(kept.contains(-1))
  assert_false(s.contains(-1))
}

///|
test "filter sizes the result for the kept elements" {
  let s : @hashset.HashSet[Int] = HashSet([ for i in 0..<10000 => i ])
  for keep in [0, 1, 10, 5000, 10000] {
    let kept = s.filter(k => k < keep)
    let rebuilt = @hashset.HashSet([ for k in s if k < keep => k ])
    assert_eq(kept.length(), keep)
    assert_eq(kept.capacity(), rebuilt.capacity())
  }
}

///|
test "filter propagates errors" {
  let s = @hashset.HashSet(["a", "b"])
  let raised = try {
    ignore(s.filter(k => if k == "b" { raise Failure("no") } else { true }))
    false
  } catch {
    _ => true
  }
  assert_true(raised)
}

///|
test "equal ignores order, capacity and removal history" {
  let a : @hashset.HashSet[Int] = HashSet([], capacity=2)
  for i in 0..<100 {
    a.add(i)
  }
  for i in 0..<100 {
    if i % 3 == 0 {
      a.remove(i)
    }
  }
  let b : @hashset.HashSet[Int] = HashSet(
    [
      for i in 0..<100 if i % 3 != 0 => 99 - i
    ],
    capacity=1024,
  )
  assert_true(a == b)
  assert_true(b == a)
  assert_true(a == a)
  let empty1 : @hashset.HashSet[Int] = HashSet([])
  let empty2 : @hashset.HashSet[Int] = HashSet([], capacity=64)
  assert_true(empty1 == empty2)
}

///|
test "equal detects a different element or size" {
  let a = @hashset.from_array(["x", "y", "z"])
  // Same size, one element differs.
  assert_false(a == @hashset.from_array(["x", "y", "w"]))
  // Subset and superset.
  assert_false(a == @hashset.from_array(["x", "y"]))
  assert_false(a == @hashset.from_array(["x", "y", "z", "w"]))
  let empty : @hashset.HashSet[String] = HashSet([])
  assert_false(a == empty)
  assert_false(empty == a)
}

///|
fn sorted_elements(set : @hashset.HashSet[Int]) -> Array[Int] {
  let elements = set.to_array()
  elements.sort()
  elements
}

///|
test "from_json round-trips whatever to_json produced" {
  for set in (@quickcheck.samples(50) : Array[@hashset.HashSet[Int]]) {
    let restored : @hashset.HashSet[Int] = @json.from_json(@json.to_json(set))
    assert_eq(sorted_elements(restored), sorted_elements(set))
  }
}

///|
test "from_json drops repeated elements" {
  let set : @hashset.HashSet[Int] = @json.from_json([3, 1, 3, 2, 1])
  assert_eq(sorted_elements(set), [1, 2, 3])
  let empty : @hashset.HashSet[Int] = @json.from_json([])
  assert_eq(empty.length(), 0)
  let nested : @hashset.HashSet[Array[Int]] = @json.from_json([[1], [], [1]])
  assert_eq(nested.length(), 2)
  assert_true(nested.contains([1]) && nested.contains([]))
}

///|
test "from_json sizes the set like the constructor" {
  for n in [0, 1, 2, 13, 100, 1000] {
    let set : @hashset.HashSet[Int] = @json.from_json(
      [
        for i in 0..<n => Json(i)
      ],
    )
    assert_eq(
      set.capacity(),
      @hashset.HashSet([ for i in 0..<n => i ]).capacity(),
    )
  }
}

///|
test "from_json rejects a non-array" {
  let bad : Json = { "a": 1 }
  try (@json.from_json(bad) : @hashset.HashSet[Int]) catch {
    err =>
      inspect(
        err,
        content="JsonDecodeError((, @hashset.from_json: expected array))",
      )
  } noraise {
    _ => fail("expected JsonDecodeError")
  }
}

///|
test "from_json reports the index of the element that failed" {
  let bad : Json = [1, "two", 3]
  try (@json.from_json(bad) : @hashset.HashSet[Int]) catch {
    err =>
      inspect(
        err,
        content="JsonDecodeError((/1, Int::from_json: expected number))",
      )
  } noraise {
    _ => fail("expected JsonDecodeError")
  }
}

///|
test "new" {
  let m : HashSet[Int32] = HashSet([])
  @test.assert_eq(m.capacity, default_init_capacity)
  inspect(m.length(), content="0")
}

///|
test "insert_and_grow" {
  let m = HashSet([])
  for i in 0..<10 {
    m.add(i.to_string())
  }
  inspect(m.length(), content="10")
  inspect(m.capacity, content="16")
}

///|
test "capacity_and_size" {
  let m = HashSet([])
  @test.assert_eq(m.capacity, default_init_capacity)
  inspect(m.length(), content="0")
  m.add("a")
  inspect(m.length(), content="1")
}

///|
test "filter sizes the result for the kept elements" {
  let s : HashSet[Int32] = HashSet([ for i in 0..<10000 => i ])
  for keep in [0, 1, 10, 5000, 10000] {
    let kept = s.filter(k => k < keep)
    let rebuilt = HashSet([ for k in s if k < keep => k ])
    @test.assert_eq(kept.length(), keep)
    @test.assert_eq(kept.capacity, rebuilt.capacity)
  }
}

///|
test "from_json sizes the set like the constructor" {
  for n in [0, 1, 2, 13, 100, 1000] {
    let set : HashSet[Int32] = @json.from_json(
      [
        for i in 0..<n => @json.Json(i)
      ],
    )
    @test.assert_eq(set.capacity, HashSet([ for i in 0..<n => i ]).capacity)
  }
}

///|
test "union_in_place with itself is a no-op" {
  // Six elements fill a capacity-8 set exactly to its grow threshold, so one
  // more insertion attempt would grow it: without the self check, absorbing
  // itself would resize the set while iterating its own entries.
  let s = from_array([ for i in 0..<6 => i ])
  let capacity = s.capacity
  s.union_in_place(s)
  @test.assert_eq(sorted_elements(s), [0, 1, 2, 3, 4, 5])
  @test.assert_eq(s.capacity, capacity)
}

///|
test "retain visits each element once when a cluster wraps around the table" {
  let s : HashSet[Int32] = HashSet([])
  let mask = s.capacity - 1
  // Two elements whose home is the last slot: the second one wraps to slot 0.
  let keys = []
  for k = 0; keys.length() < 2; k = k + 1 {
    if (Hash::hash(k) & mask) == mask {
      keys.push(k)
    }
  }
  s.add(keys[0])
  s.add(keys[1])
  let calls = []
  s.retain(k => {
    calls.push(k)
    k != keys[0]
  })
  calls.sort()
  let expected = [keys[0], keys[1]]
  expected.sort()
  @debug.assert_eq(calls, expected)
  @debug.assert_eq(s.to_array(), [keys[1]])
}

///|
fn sorted_elements(set : HashSet[Int32]) -> Array[Int32] {
  let elements = set.to_array()
  elements.sort()
  elements
}

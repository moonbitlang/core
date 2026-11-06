///|
test "add of a present key does not grow a full HashSet" {
  let set : HashSet[Int32] = HashSet([])
  for i in 0..<set.grow_at {
    set.add(i)
  }
  let buckets = set.capacity
  inspect(set.size == set.grow_at, content="true")
  for i in 0..<set.size {
    set.add(i)
  }
  assert_true(set.capacity == buckets)
  // The next new key still triggers growth.
  set.add(set.size)
  assert_true(set.capacity == buckets * 2)
  for i in 0..<set.size {
    assert_true(set.contains(i))
  }
}

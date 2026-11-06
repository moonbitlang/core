///|
test "add of a present key does not grow a full Set" {
  let set : Set[Int32] = Set([])
  for i in 0..<set.grow_at {
    set.add(i)
  }
  let buckets = set.capacity
  inspect(set.size == set.grow_at, content="true")
  for i in 0..<set.size {
    set.add(i)
    assert_false(set.add_and_check(i))
  }
  assert_true(set.capacity == buckets)
  // The next new key still triggers growth, and order is preserved.
  assert_true(set.add_and_check(set.size))
  assert_true(set.capacity == buckets * 2)
  assert_true(set.iter().collect() == [0, 1, 2, 3, 4, 5, 6])
}

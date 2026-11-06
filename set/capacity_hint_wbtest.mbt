///|
test "capacity hint reserves room for that many entries" {
  for n in [0, 1, 2, 3, 6, 7, 12, 13, 14, 16, 100, 1000] {
    let m : Set[Int32] = Set([], capacity=n)
    let buckets = m.capacity
    for i in 0..<n {
      m.add(i)
    }
    assert_true(m.capacity == buckets)
  }
}

///|
test "capacity hint counts the initial entries" {
  for n in [1, 2, 13, 16, 100] {
    // One entry comes from the array, so n - 1 more fit without growing.
    let m : Set[Int32] = Set([-1], capacity=n)
    let buckets = m.capacity
    for i in 0..<(n - 1) {
      m.add(i)
    }
    assert_true(m.capacity == buckets)
  }
}

///|
test {
  let a = ['a', 'b', 'c', 'd', 'e', 'f', 'a'].map(x => String::make(3, x))
  let b = ['a', 'b', 'x', 'y', 'e', 'f'].map(x => String::make(3, x))
  assert_false(physical_equal(a[0], b[0]))
  assert_false(physical_equal(a[6], b[0]))
  assert_false(physical_equal(a[0], a[6]))
  assert_false(physical_equal(a[1], b[1]))
  assert_false(physical_equal(a[4], b[4]))
  inspect(
    make_indexer(
      a.mut_view(start=0, end=a.length()),
      b.mut_view(start=0, end=b.length()),
    ),
    content="[0, 1, 4, 5, 6]",
  )
  // after call make_indexer, equal items are physically equal
  assert_true(physical_equal(a[0], b[0]))
  assert_true(physical_equal(a[6], b[0]))
  assert_true(physical_equal(a[0], a[6]))
  assert_true(physical_equal(a[1], b[1]))
  assert_true(physical_equal(a[4], b[4]))
}

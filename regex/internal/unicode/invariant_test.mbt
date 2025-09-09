///|
test "category names" {
  for key in general_category_ranges.keys() {
    assert_true(general_category_property_value_alises.contains(key))
  }
}

///|
test "category names" {
  for key in @unicode.general_category_ranges.keys() {
    assert_true(@unicode.general_category_property_value_alises.contains(key))
  }
}

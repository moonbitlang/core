# Strconv

This package implements conversions to and from string representations of basic data types.

# Usage

## Parse

Use `parse_bool`, `parse_double`, `parse_int`, and `parse_int64` convert strings to values.

```moonbit
///|
test {
  let b = @strconv.parse_bool("true")
  assert_eq(b, true)
  let i1 = @strconv.parse_int("1234567")
  assert_eq(i1, 1234567)
  let i2 = @strconv.parse_int("101", base=2)
  assert_eq(i2, 5)
  let d = @strconv.parse_double("123.4567")
  assert_eq(d, 123.4567)
}
```

For types that implement the `FromStr` trait, you can also use helper function `parse` to convert a string to a value.

```moonbit
///|
test {
  let a : Int = @strconv.parse("123")
  assert_eq(a, 123)
  let b : Bool = @strconv.parse("true")
  assert_eq(b, true)
}
```

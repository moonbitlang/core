# Strconv

This package implements conversions to and from string representations of basic data types.

# Usage

## Parse

Use `parse_bool`, `parse_double`, `parse_int`, and `parse_int64` convert strings to values.

```moonbit
let b = @strconv.parse_bool("true")?         // true
let i1 = @strconv.parse_int("1234567")?      // 1234567
let i2 = @strconv.parse_int("101", 2)?       // 5
let d = @strconv.parse_double("123.4567")?   // 123.4567
```

For types that implement the `FromStr` trait, you can also use helper function `parse` to convert a string to a value.

```moonbit
let a : Int = @strconv.parse?("123").unwrap()   // 123 
let b : Bool = @strconv.parse?("true").unwrap() // true
```

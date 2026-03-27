# Strconv

Deprecated compatibility package. Use the matching APIs in `@string` instead:
`parse_bool`, `parse_int`, `parse_int64`, `parse_uint`, `parse_uint64`,
`parse_double`, and `from_str`.

## Parsing Integers

Parse integers in various bases:

```mbt check
///|
#warnings("-deprecated")
test "parse_int" {
  inspect(@strconv.parse_int("42"[:]), content="42")
  inspect(@strconv.parse_int("101"[:], base=2), content="5")
  inspect(@strconv.parse_int("ff"[:], base=16), content="255")
}
```

Parse 64-bit integers and unsigned integers:

```mbt check
///|
#warnings("-deprecated")
test "parse_int64_uint" {
  inspect(
    @strconv.parse_int64("9223372036854775807"[:]),
    content="9223372036854775807",
  )
  inspect(@strconv.parse_uint("42"[:]), content="42")
  inspect(
    @strconv.parse_uint64("18446744073709551615"[:]),
    content="18446744073709551615",
  )
}
```

## Parsing Other Types

```mbt check
///|
#warnings("-deprecated")
test "parse_other" {
  inspect(@strconv.parse_bool("true"[:]), content="true")
  inspect(@strconv.parse_double("3.14"[:]), content="3.14")
}
```

## FromStr Trait

Types implementing `FromStr` can be parsed using `from_str`.
Use `@string.from_str` in new code.

```mbt check
///|
#warnings("-deprecated")
test "from_str" {
  let i : Int = @strconv.from_str("123"[:])
  inspect(i, content="123")
  let b : Bool = @strconv.from_str("false"[:])
  inspect(b, content="false")
  let d : Double = @strconv.from_str("2.718"[:])
  inspect(d, content="2.718")
}
```

`FromStr` is implemented for `Bool`, `Int`, `Int64`, `UInt`, `UInt64`, and `Double`.
Prefer `@string.FromStr` in new code.

## Error Handling

Parse functions raise `StrConvError` on invalid input.
Use the `@string` versions in new code.

```mbt check
///|
#warnings("-deprecated")
test "error_handling" {
  let result : Result[Int, _] = try? @strconv.parse_int("abc"[:])
  inspect(result is Err(_), content="true")
}
```

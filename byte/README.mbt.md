# Byte

Constants for the `Byte` type (8-bit unsigned integer).

## Constants

```mbt check
///|
test {
  inspect(@byte.MIN_VALUE, content="b'\\x00'")
  inspect(@byte.MAX_VALUE, content="b'\\xFF'")
}
```

## Byte Literals

MoonBit provides byte literals with the `b` prefix:

```mbt check
///|
test {
  // ASCII character
  inspect(b'A'.to_uint64(), content="65")
  // Hex escape
  inspect(b'\x41'.to_uint64(), content="65")
  // Min and max
  inspect(b'\x00'.to_uint64(), content="0")
  inspect(b'\xff'.to_uint64(), content="255")
}
```

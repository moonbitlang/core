# Binary

Binary encoding and decoding for in-memory byte sequences.

This package covers the pieces of Go's `encoding/binary` that map directly to
MoonBit's core library today: fixed-width unsigned integers in explicit byte
orders, plus unsigned and signed varint helpers. Stream-oriented APIs and
reflection-based struct encoding are intentionally out of scope.

## Byte Order

Use `Big` or `Little` to encode and decode fixed-width unsigned integers.
Decoding reads from the start of a `BytesView` and leaves trailing bytes
untouched.

```mbt check
///|
test "byte_order_decode" {
  inspect(try! @binary.Big.decode_uint16(b"\x03\xe8"), content="1000")
  inspect(try! @binary.Little.decode_uint16(b"\xe8\x03"), content="1000")
}
```

Encoding returns a new byte sequence.

```mbt check
///|
test "byte_order_encode" {
  assert_eq(@binary.Big.encode_uint32(0x12345678U), b"\x12\x34\x56\x78")
  assert_eq(@binary.Little.encode_uint32(0x12345678U), b"\x78\x56\x34\x12")
}
```

## Varints

Use `encode_uvarint` and `uvarint` for unsigned 64-bit values. `uvarint`
returns both the decoded value and the number of bytes consumed.

```mbt check
///|
test "uvarint" {
  assert_eq(@binary.encode_uvarint(300UL), b"\xac\x02")
  let (value, consumed) = try! @binary.uvarint(b"\xac\x02rest")
  inspect(value, content="300")
  inspect(consumed, content="2")
}
```

Use `encode_varint` and `varint` for signed 64-bit values.

```mbt check
///|
test "varint" {
  assert_eq(@binary.encode_varint(-300L), b"\xd7\x04")
  let (value, consumed) = try! @binary.varint(b"\xd7\x04rest")
  inspect(value, content="-300")
  inspect(consumed, content="2")
}
```

Malformed fixed-width input, incomplete varints, and overflowing varints raise
`Malformed`.

```mbt check
///|
test "malformed" {
  try {
    let _ = @binary.uvarint(b"\x80")
    panic()
  } catch {
    Malformed(_) => ()
  }
}
```

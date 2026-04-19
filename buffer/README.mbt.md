# Buffer

A growable byte buffer for building binary data and serializing values. Supports writing integers, floats, strings, and raw bytes in both big-endian and little-endian byte orders.

## Create

Create an empty buffer, optionally with a capacity hint to reduce reallocations:

```mbt check
///|
test {
  let buf = @buffer.new()
  assert_eq(buf.is_empty(), true)
  let buf2 = @buffer.new(size_hint=1024)
  assert_eq(buf2.length(), 0)
}
```

Create from existing data:

```mbt check
///|
test {
  let buf = @buffer.from_bytes(b"hello")
  assert_eq(buf.length(), 5)
  let buf2 = @buffer.from_array([b'a', b'b', b'c'])
  assert_eq(buf2.length(), 3)
  let buf3 = @buffer.from_iter(b"hi".iter())
  assert_eq(buf3.length(), 2)
}
```

## Writing Bytes

Write individual bytes, byte slices, or byte iterators:

```mbt check
///|
test {
  let buf = @buffer.new()
  buf.write_byte(b'H')
  buf.write_byte(b'i')
  buf.write_bytes(b" world")
  inspect(buf.to_bytes(), content="b\"Hi world\"")
  // write a sub-range via BytesView
  let buf2 = @buffer.new()
  buf2.write_bytesview(b"Hello"[0:2])
  inspect(buf2.to_bytes(), content="b\"He\"")
  // write from an iterator
  let buf3 = @buffer.new()
  buf3.write_iter(b"ok".iter())
  inspect(buf3.to_bytes(), content="b\"ok\"")
}
```

## Writing Integers

All integer writes come in `_be` (big-endian) and `_le` (little-endian) variants.

```mbt check
///|
test {
  // 32-bit signed/unsigned
  let buf = @buffer.new()
  buf.write_int_be(0x01020304)
  inspect(buf.to_bytes(), content="b\"\\x01\\x02\\x03\\x04\"")
  let buf2 = @buffer.new()
  buf2.write_int_le(0x01020304)
  inspect(buf2.to_bytes(), content="b\"\\x04\\x03\\x02\\x01\"")
  // unsigned 32-bit
  let buf3 = @buffer.new()
  buf3.write_uint_be(0xAABBU)
  inspect(buf3.to_bytes(), content="b\"\\x00\\x00\\xaa\\xbb\"")
}
```

16-bit and 64-bit variants:

```mbt check
///|
test {
  // 16-bit signed
  let buf = @buffer.new()
  buf.write_int16_be((0x0102 : Int16))
  buf.write_int16_le((0x0102 : Int16))
  inspect(buf.to_bytes(), content="b\"\\x01\\x02\\x02\\x01\"")
  // 16-bit unsigned
  let buf2 = @buffer.new()
  buf2.write_uint16_be(Int::to_uint16(0x00AB))
  inspect(buf2.to_bytes(), content="b\"\\x00\\xab\"")
  // 64-bit signed
  let buf3 = @buffer.new()
  buf3.write_int64_be(0x0102030405060708L)
  inspect(
    buf3.to_bytes(),
    content="b\"\\x01\\x02\\x03\\x04\\x05\\x06\\x07\\x08\"",
  )
  // 64-bit unsigned
  let buf4 = @buffer.new()
  buf4.write_uint64_le(0xAABBUL)
  inspect(
    buf4.to_bytes(),
    content="b\"\\xbb\\xaa\\x00\\x00\\x00\\x00\\x00\\x00\"",
  )
}
```

## Writing Floats

```mbt check
///|
test {
  let buf = @buffer.new()
  buf.write_float_be(1.0)
  assert_eq(buf.length(), 4)
  let buf2 = @buffer.new()
  buf2.write_double_le(1.0)
  assert_eq(buf2.length(), 8)
}
```

## Writing Characters & Strings

Write individual characters or entire strings as UTF-8 or UTF-16 (LE/BE):

```mbt check
///|
test {
  // UTF-8
  let buf = @buffer.new()
  buf.write_char_utf8('A')
  buf.write_string_utf8("BC")
  inspect(buf.to_bytes(), content="b\"ABC\"")
  // UTF-16 little-endian
  let buf2 = @buffer.new()
  buf2.write_char_utf16le('A')
  inspect(buf2.to_bytes(), content="b\"A\\x00\"")
  // UTF-16 big-endian
  let buf3 = @buffer.new()
  buf3.write_string_utf16be("AB")
  inspect(buf3.to_bytes(), content="b\"\\x00A\\x00B\"")
}
```

## Writing Show Objects

Write any type that implements `Show` via `write_object()`. The buffer also implements the `Logger` trait, so it can be passed to `output()`.

```mbt check
///|
test {
  let buf = @buffer.new()
  buf.write_object(42)
  // write_object uses the Show trait, producing UTF-16LE string bytes
  assert_eq(buf.length(), 4) // "42" in UTF-16LE = 4 bytes
}
```

## LEB128 Encoding

Write integers in LEB128 variable-length encoding. Supported for `Int`, `UInt`, `Int64`, and `UInt64`.

```mbt check
///|
test {
  let buf = @buffer.new()
  buf.write_leb128(624485)
  inspect(buf.to_bytes(), content="b\"\\xe5\\x8e&\"")
  let buf2 = @buffer.new()
  buf2.write_leb128(300UL)
  inspect(buf2.to_bytes(), content="b\"\\xac\\x02\"")
}
```

## Reading Contents

`to_bytes()` (aliased as `contents()`) returns the buffer contents as `Bytes`. `view()` returns an `ArrayView[Byte]` without copying.

```mbt check
///|
test {
  let buf = @buffer.new()
  buf.write_bytes(b"hello")
  let bytes = buf.to_bytes()
  inspect(bytes, content="b\"hello\"")
  let v = buf.view()
  assert_eq(v.length(), 5)
}
```

## Reset

`reset()` clears the buffer contents, allowing it to be reused:

```mbt check
///|
test {
  let buf = @buffer.new()
  buf.write_bytes(b"data")
  assert_eq(buf.length(), 4)
  buf.reset()
  assert_eq(buf.is_empty(), true)
}
```

## Size Hints

Pre-allocate capacity to minimize reallocations when the final size is known:

```mbt check
///|
test {
  let buf = @buffer.new(size_hint=1024)
  for i in 0..<100 {
    buf.write_int_le(i)
  }
  assert_eq(buf.length(), 400) // 100 × 4 bytes
}
```

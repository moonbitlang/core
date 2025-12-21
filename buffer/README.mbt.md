# `buffer`

The buffer package provides a flexible byte buffer implementation for efficient binary data handling and serialization.

## Basic Usage

Create a new buffer and write basic data:

```mbt check
///|
test {
  // basic buffer operations
  let buf = @buffer.new()

  // Write some bytes
  buf..write_byte(b'H')..write_byte(b'i')

  // Check contents
  inspect(buf.is_empty(), content="false")
  inspect(buf.length(), content="2")

  // Get contents as bytes
  let bytes = buf.contents()
  inspect(
    bytes,
    content=(
      #|b"Hi"
    ),
  )

  // Reset buffer
  buf.reset()
  inspect(buf.is_empty(), content="true")
}
```

## Writing Numbers

Write numbers in different encodings:

```mbt check
///|
test {
  // number serialization

  inspect(
    @buffer.new()
    // Write integers in different byte orders
    ..write_int_be(42)
    ..write_int_le(42)
    .to_bytes(),
    content=(
      #|b"\x00\x00\x00**\x00\x00\x00"
    ),
  )
  inspect(
    @buffer.new()
    // Write floating point numbers
    ..write_float_be(3.14)
    ..write_float_le(3.14)
    .to_bytes(),
    content=(
      #|b"@H\xf5\xc3\xc3\xf5H@"
    ),
  )
  inspect(
    @buffer.new()
    // Write 64-bit integers
    ..write_int64_be(0xAABBCCDDEEL)
    ..write_int64_le(0xAABBCCDDEEL)
    .to_bytes(),
    content=(
      #|b"\x00\x00\x00\xaa\xbb\xcc\xdd\xee\xee\xdd\xcc\xbb\xaa\x00\x00\x00"
    ),
  )
  inspect(
    @buffer.new()
    // Write unsigned integers
    ..write_uint_be(0x2077U)
    ..write_uint_le(0x2077U)
    .to_bytes(),
    content=(
      #|b"\x00\x00 ww \x00\x00"
    ),
  )
}
```

## Writing Byte Sequences

Write sequences of bytes:

```mbt check
///|
test {
  // byte sequence writing

  let buf = @buffer.new()

  // Write byte array
  let bytes = b"Hello"
  buf.write_bytes(bytes)

  // Write byte iterator
  buf.write_iter(bytes.iter())
  let contents = buf.to_bytes()
  inspect(
    contents,
    content=(
      #|b"HelloHello"
    ),
  ) // "Hello" written twice
}
```

## Writing Structured Data

Write structured data that implements Show:

```mbt check
///|
test {
  // object writing

  let buf = @buffer.new()

  // Write int as object
  buf.write_object(42)

  // Contents will be "42" as bytes
  let contents = buf.contents()
  inspect(
    contents,
    content=(
      #|b"4\x002\x00"
    ),
  )
}
```

## Size Hints

Provide size hints for better performance:

```mbt check
///|
test {
  // buffer with size hint
  // Create buffer with initial capacity hint
  let buf = @buffer.new(size_hint=1024)

  // Write some data
  for i in 0..<100 {
    buf.write_int_le(i)
  }

  // Each integer takes 4 bytes
  inspect(buf.length(), content="400")
}
```

## Buffer as Logger

The buffer implements the Logger trait for Show:

```mbt check
///|
test {
  // buffer as logger
  let buf = @buffer.new()
  let array = [1, 2, 3]
  // Use buffer to log array
  array.output(buf)
  let contents = buf.contents()
  inspect(
    contents,
    content=(
      #|b"[\x001\x00,\x00 \x002\x00,\x00 \x003\x00]\x00"
    ),
  )
}
```

## Converting to String/Bytes

Methods for converting buffer contents:

```mbt check
///|
test {
  // buffer conversion
  let buf = @buffer.new()
  buf.write_byte(b'a')
  buf.write_byte(b'b')
  buf.write_byte(b'c')
  let bytes = buf.to_bytes()
  inspect(
    bytes,
    content=(
      #|b"abc"
    ),
  )
}
```

## Binary Viewing

Support for viewing subsets of bytes:

```mbt check
///|
test {
  /// byte view writing
  let buf = @buffer.new()
  let bytes = b"Hello World"

  // Write a view of the bytes
  buf.write_bytesview(bytes[0:5]) // Write "Hello"
  let contents = buf.to_bytes()
  inspect(
    contents,
    content=(
      #|b"Hello"
    ),
  )
}
```

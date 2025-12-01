# `bytes`

This package provides utilities for working with sequences of bytes, offering both mutable (`Bytes`) and immutable (`View`) representations.

## Creating Bytes

You can create `Bytes` from various sources including arrays, fixed arrays, and iterators:

```mbt check
///|
test "bytes creation" {
  // Create from array of bytes
  let arr = [b'h', b'e', b'l', b'l', b'o']
  let bytes1 = Bytes::from_array(arr)
  inspect(
    bytes1,
    content=(
      #|b"hello"
    ),
  )

  // Create from fixed array
  let fixed = FixedArray::make(3, b'a')
  let bytes2 = Bytes::from_array(fixed)
  inspect(
    bytes2,
    content=(
      #|b"aaa"
    ),
  )

  // Create empty bytes
  let empty = @bytes.default()
  inspect(
    empty,
    content=(
      #|b""
    ),
  )

  // Create from iterator
  let iter_bytes = Bytes::from_iter(arr.iter())
  inspect(
    iter_bytes,
    content=(
      #|b"hello"
    ),
  )
}
```

## Converting Between Formats

`Bytes` can be converted to and from different formats:

```mbt check
///|
test "bytes conversion" {
  let original = [b'x', b'y', b'z']
  let bytes = Bytes::from_array(original)

  // Convert to array
  let array = bytes.to_array()
  inspect(array, content="[b'\\x78', b'\\x79', b'\\x7A']")

  // Convert to fixed array
  let fixed = bytes.to_fixedarray()
  inspect(fixed, content="[b'\\x78', b'\\x79', b'\\x7A']")

  // Convert to iterator and collect back
  let collected = bytes.iter().to_array()
  inspect(collected, content="[b'\\x78', b'\\x79', b'\\x7A']")
}
```

## Working with Views

Views provide a way to work with portions of bytes and interpret them as various numeric types:

```mbt check
///|
test "bytes view operations" {
  // Create bytes with numeric data
  let num_bytes = Bytes::from_array([0x12, 0x34, 0x56, 0x78])

  // Create a view
  let view = num_bytes[:]

  // Get individual bytes
  inspect(view[0], content="b'\\x12'")

  // Interpret as integers (big-endian)
  guard view is [i32be(x), ..] else {
    fail("Failed to match big-endian integer pattern")
  }
  inspect(x, content="305419896")

  // Interpret as integers (little-endian)
  guard view is [i32le(y), ..] else {
    fail("Failed to match little-endian integer pattern")
  }
  inspect(y, content="2018915346")

  // Create a sub-view
  let sub_view = view[1:3]
  inspect(sub_view.length(), content="2")
}
```

## Binary Data Interpretation

Views provide methods to interpret byte sequences as various numeric types in both little-endian and big-endian formats:

```mbt check
///|
test "numeric interpretation" {
  // Create test data
  let int64_bytes = Bytes::from_array([
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x42,
  ])
  guard int64_bytes is [i64be(x), ..] else {
    fail("Failed to match big-endian int64 pattern")
  }
  inspect(x, content="66")
  guard int64_bytes is [u64le(x), ..] else {
    fail("Failed to match little-endian uint64 pattern")
  }
  inspect(x, content="4755801206503243776")
}
```

## Concatenation and Comparison

Bytes can be concatenated and compared:

```mbt check
///|
test "bytes operations" {
  let b1 = Bytes::from_array([b'a', b'b'])
  let b2 = Bytes::from_array([b'c', b'd'])

  // Concatenation
  let combined = b1 + b2
  inspect(
    combined,
    content=(
      #|b"abcd"
    ),
  )

  // Comparison
  let same = Bytes::from_array([b'a', b'b'])
  let different = Bytes::from_array([b'x', b'y'])
  inspect(b1 == same, content="true")
  inspect(b1 == different, content="false")
  inspect(b1 < b2, content="true")
}
```

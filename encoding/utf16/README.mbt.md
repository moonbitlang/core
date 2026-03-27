# UTF-16

Encoding and decoding between strings and UTF-16 byte sequences, with configurable byte order and BOM handling.

## Encoding

Use `encode` to convert a string to UTF-16 bytes. Default endianness is little-endian.

```mbt check
///|
test "encode" {
  let bytes = @utf16.encode("hi"[:])
  inspect(bytes, content="b\"h\\x00i\\x00\"")
}
```

Use `endianness` to specify byte order and `bom=true` to prepend a Byte Order Mark:

```mbt check
///|
test "encode_big_endian_with_bom" {
  let bytes = @utf16.encode("hi"[:], endianness=Big, bom=true)
  inspect(bytes, content="b\"\\xfe\\xff\\x00h\\x00i\"")
}
```

## Decoding

Use `decode` to convert UTF-16 bytes back to a string. Raises `Malformed` on invalid sequences.

```mbt check
///|
test "decode" {
  let bytes : Bytes = b"\x68\x00\x69\x00"
  let s = @utf16.decode(bytes[:])
  inspect(s, content="hi")
}
```

Set `ignore_bom=true` to strip a leading BOM, or use `endianness` to specify the byte order explicitly:

```mbt check
///|
test "decode_big_endian" {
  let bytes : Bytes = b"\x00\x68\x00\x69"
  let s = @utf16.decode(bytes[:], endianness=Big)
  inspect(s, content="hi")
}
```

## Lossy Decoding

Use `decode_lossy` to decode bytes that may contain invalid UTF-16, replacing invalid sequences with the Unicode replacement character (U+FFFD).

```mbt check
///|
test "decode_lossy" {
  let bytes : Bytes = b"\x00\xD8\x68\x00"
  let s = @utf16.decode_lossy(bytes[:])
  inspect(s, content="\u{FFFD}h")
}
```

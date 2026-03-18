# UTF-8

Encoding and decoding between strings and UTF-8 byte sequences.

## Encoding

Use `encode` to convert a string to UTF-8 bytes. Set `bom=true` to prepend the UTF-8 BOM (U+FEFF).

```mbt check
///|
test "encode" {
  let bytes = @utf8.encode("hi"[:])
  inspect(bytes, content="b\"\\x68\\x69\"")
}
```

```mbt check
///|
test "encode_with_bom" {
  let bytes = @utf8.encode("hi"[:], bom=true)
  inspect(bytes, content="b\"\\xEF\\xBB\\xBF\\x68\\x69\"")
}
```

## Decoding

Use `decode` to convert UTF-8 bytes back to a string. Raises `Malformed` on invalid UTF-8 sequences. Set `ignore_bom=true` to strip a leading BOM if present.

```mbt check
///|
test "decode" {
  let bytes : Bytes = b"\x68\x69"
  let s = @utf8.decode(bytes[:])
  inspect(s, content="hi")
}
```

## Lossy Decoding

Use `decode_lossy` to decode bytes that may contain invalid UTF-8, replacing invalid sequences with the Unicode replacement character (U+FFFD).

```mbt check
///|
test "decode_lossy" {
  let bytes : Bytes = b"\x68\x80\x69"
  let s = @utf8.decode_lossy(bytes[:])
  inspect(s, content="h\u{FFFD}i")
}
```

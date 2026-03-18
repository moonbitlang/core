# ASCII

Encoding and decoding between strings and ASCII byte sequences.

## Encoding

Use `encode` to convert a string to ASCII bytes. Panics if the string contains non-ASCII characters.

```mbt check
///|
test "encode" {
  let bytes = @ascii.encode("hello"[:])
  inspect(bytes, content="b\"\\x68\\x65\\x6C\\x6C\\x6F\"")
}
```

## Decoding

Use `decode` to convert ASCII bytes back to a string. Raises `Malformed` if any byte is outside the ASCII range (0-127).

```mbt check
///|
test "decode" {
  let bytes : Bytes = b"\x68\x65\x6C\x6C\x6F"
  let s = @ascii.decode(bytes[:])
  inspect(s, content="hello")
}
```

## Lossy Decoding

Use `decode_lossy` to decode bytes that may contain invalid ASCII, replacing invalid bytes with the Unicode replacement character (U+FFFD).

```mbt check
///|
test "decode_lossy" {
  let bytes : Bytes = b"\x68\x80\x6F"
  let s = @ascii.decode_lossy(bytes[:])
  inspect(s, content="h\u{FFFD}o")
}
```

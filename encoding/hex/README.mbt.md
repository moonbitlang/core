# Hexadecimal Encoding

Package `encoding/hex` implements lowercase hexadecimal encoding and decoding
for in-memory byte data.

The API follows the same core model as Go's `encoding/hex`: each source byte is
encoded as two hexadecimal characters, and decoding accepts both uppercase and
lowercase digits. Stream encoders and decoders are intentionally left out
because this package does not introduce an IO abstraction, and Go's
`EncodedLen`/`DecodedLen` sizing helpers are left out because `encode` and
`decode` allocate their own results (the lengths are simply `2 * n` and
`n / 2`).

## Encoding

Use `encode` to convert bytes into a lowercase hexadecimal string.

```mbt check
///|
test "encode" {
  let src : Bytes = b"Hello Gopher!"
  inspect(@hex.encode(src), content="48656c6c6f20476f7068657221")
}
```

## Decoding

Use `decode` to convert a hexadecimal string back to bytes.

```mbt check
///|
test "decode" {
  let decoded = @hex.decode("48656c6c6f20476f7068657221")
  inspect(decoded, content="b\"Hello Gopher!\"")
}
```

Uppercase hexadecimal digits are accepted too:

```mbt check
///|
test "decode_uppercase" {
  let decoded = @hex.decode("48656C6C6F")
  inspect(decoded, content="b\"Hello\"")
}
```

## Malformed Input

`decode` raises `Malformed` when the input has odd length or contains any
non-hexadecimal character.

```mbt check
///|
test "malformed" {
  try {
    let _ = @hex.decode("0g")
    panic()
  } catch {
    Malformed(input) => inspect(input, content="0g")
  }
}
```

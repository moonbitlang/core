# Hexadecimal Encoding

Package `encoding/hex` implements lowercase hexadecimal encoding and decoding
for in-memory byte data.

The API follows the same core model as Go's `encoding/hex`: each source byte is
encoded as two hexadecimal characters, decoding accepts both uppercase and
lowercase digits, `encoded_len` reports `n * 2`, and `decoded_len` reports
`n / 2`. Stream encoders and decoders are intentionally left out because this
package does not introduce an IO abstraction.

## Encoding

Use `encode` to convert bytes into a lowercase hexadecimal string.

```mbt check
///|
test "encode" {
  let src : Bytes = b"Hello Gopher!"
  inspect(@hex.encode(src), content="48656c6c6f20476f7068657221")
}
```

`encoded_len` returns the exact output length for a source byte count.

```mbt check
///|
test "encoded_len" {
  inspect(@hex.encoded_len(13), content="26")
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

`decoded_len` reports the destination length for a syntactically valid input of
that many characters. Odd lengths still raise `Malformed` when decoded.

```mbt check
///|
test "decoded_len" {
  inspect(@hex.decoded_len(27), content="13")
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

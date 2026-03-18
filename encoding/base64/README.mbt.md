# Base64

Base64 encoding and decoding following RFC 4648.

## Encoding

Use `encode` to convert bytes to a Base64 string. Padding with `=` is enabled by default.

```mbt check
///|
test "encode" {
  let bytes : Bytes = b"Hello"
  inspect(@base64.encode(bytes[:]), content="SGVsbG8=")
}
```

Disable padding by setting `padding=false`:

```mbt check
///|
test "encode_no_padding" {
  let bytes : Bytes = b"Hello"
  inspect(@base64.encode(bytes[:], padding=false), content="SGVsbG8")
}
```

## Decoding

Use `decode` to convert a Base64 string back to bytes. Both padded and unpadded input are accepted. Raises `Malformed` on invalid input.

```mbt check
///|
test "decode" {
  let bytes = @base64.decode("SGVsbG8="[:])
  inspect(bytes, content="b\"Hello\"")
}
```

Set `ignore_whitespace=true` to skip ASCII whitespace in the input:

```mbt check
///|
test "decode_ignore_whitespace" {
  let bytes = @base64.decode("SGVs bG8="[:], ignore_whitespace=true)
  inspect(bytes, content="b\"Hello\"")
}
```

## Lossy Decoding

Use `decode_lossy` to decode Base64 while skipping invalid characters instead of raising an error.

```mbt check
///|
test "decode_lossy" {
  let bytes = @base64.decode_lossy("SGVsbG8="[:])
  inspect(bytes, content="b\"Hello\"")
}
```

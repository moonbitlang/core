# Base64

Base64 encoding and decoding following RFC 4648.

## Encoding

Use `encode` to convert bytes to a Base64 string. Padding with `=` is enabled by default.

```mbt check
///|
test "encode" {
  let bytes : Bytes = b"Hello"
  inspect(@base64.encode(bytes), content="SGVsbG8=")
}
```

Disable padding by setting `padding=false`:

```mbt check
///|
test "encode_no_padding" {
  let bytes : Bytes = b"Hello"
  inspect(@base64.encode(bytes, padding=false), content="SGVsbG8")
}
```

Set `url_safe=true` to use the URL- and filename-safe alphabet (RFC 4648 §5),
which writes `-` and `_` in place of `+` and `/`. JWT segments, for example,
are URL-safe and unpadded:

```mbt check
///|
test "encode_url_safe" {
  let bytes : Bytes = b"\xfb\xff"
  inspect(@base64.encode(bytes), content="+/8=")
  inspect(@base64.encode(bytes, url_safe=true, padding=false), content="-_8")
}
```

## Decoding

Use `decode` to convert a Base64 string back to bytes. Both padded and unpadded input are accepted. Raises `Malformed` on invalid input.

```mbt check
///|
test "decode" {
  let bytes = @base64.decode("SGVsbG8=")
  inspect(bytes, content="b\"Hello\"")
}
```

Set `ignore_whitespace=true` to skip spaces, tabs, CR, and LF in the input:

```mbt check
///|
test "decode_ignore_whitespace" {
  let bytes = @base64.decode("SGVs bG8=", ignore_whitespace=true)
  inspect(bytes, content="b\"Hello\"")
}
```

Set `url_safe=true` to decode the URL-safe alphabet. Each alphabet is strict:
with `url_safe=true`, `+` and `/` raise `Malformed`, and without it `-` and `_`
do.

```mbt check
///|
test "decode_url_safe" {
  let bytes = @base64.decode("-_8", url_safe=true)
  inspect(bytes, content="b\"\\xfb\\xff\"")
}
```

## Lossy Decoding

Use `decode_lossy` to decode Base64 while skipping invalid characters instead of
raising an error. Padding ends decoding. Spaces, tabs, CR, and LF also end
decoding by default; set `ignore_whitespace=true` to skip them.

```mbt check
///|
test "decode_lossy" {
  let bytes = @base64.decode_lossy("SGVsbG8=")
  inspect(bytes, content="b\"Hello\"")
}
```

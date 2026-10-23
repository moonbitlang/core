# internal/bytes_util

Utilities for rendering raw bytes into a readable ASCII/escape string.

## Overview

This package is an internal helper for diagnostics and error messages. It
accepts `BytesView`, so callers can pass `Bytes`, `BytesView`, or slices without
allocation. It is not a general-purpose Unicode string escaper.

## API

`ascii_to_string(ascii : BytesView) -> String`

Converts bytes to a string using a simple ASCII-oriented escaping scheme.

## Output Format

- Bytes in `0x20..0x7e` are emitted as ASCII characters.
- `0x0a` is emitted as a newline character.
- `0x0d` and `0x09` are emitted as the escape sequences `\\r` and `\\t`.
- Other bytes are emitted as `\\x` followed by lowercase hex without padding.

## Examples

```mbt check
///|
test "printable and tab" {
  let bytes : Bytes = b"Hi\t!"
  let rendered = @bytes_util.ascii_to_string(bytes)
  inspect(rendered, content="Hi\\t!")
}
```

```mbt check
///|
test "non-printable bytes" {
  let bytes : Bytes = [0, 1, 15, 16, 31, 127]
  let rendered = @bytes_util.ascii_to_string(bytes)
  inspect(rendered, content="\\x0\\x1\\xf\\x10\\x1f\\x7f")
}
```

```mbt check
///|
test "newline is literal" {
  let bytes : Bytes = [65, 10, 66]
  let rendered = @bytes_util.ascii_to_string(bytes)
  inspect(rendered, content="A\nB")
}
```

## Notes

- Output uses lowercase hex and does not zero-pad values.
- Newlines are embedded as literal line breaks, so output can span multiple lines.

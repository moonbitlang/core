# Percent Encoding

Package `encoding/percent` implements RFC 3986 percent-encoding for URI
components: the escaping applied to a single path segment, query value or
fragment before it is spliced into a URL.

`encode` follows the strict rule of RFC 3986 section 2: the text is converted
to UTF-8 and every byte outside the unreserved set `A-Z a-z 0-9 - . _ ~` is
written as `%XX` with uppercase hexadecimal digits. This is the same set that
Go's `url.PathEscape` and `url.QueryEscape` start from and is slightly
stricter than JavaScript's `encodeURIComponent`, which leaves `!*'()`
unescaped. `decode` follows `decodeURIComponent`: every `%XX` is decoded, the
escaped bytes are interpreted as UTF-8, and malformed input raises.

The package does not parse URLs, does not apply per-component rules such as
keeping `/` in a path, and does not implement `application/x-www-form-urlencoded`
(where a space is `+`).

## Encoding

Use `encode` to escape one URI component. A space becomes `%20` and every
reserved delimiter (`/`, `?`, `#`, `&`, `=`, `:`, `@`, ...) is escaped, so the
result cannot terminate or split the component it is spliced into. It is still
the caller's job to reject values such as `.` and `..`, which contain only
unreserved characters and keep their meaning inside a path.

```mbt check
///|
test "encode" {
  inspect(
    @percent.encode("Application Support"),
    content="Application%20Support",
  )
  inspect(@percent.encode("a+b/c?d#e&f=g"), content="a%2Bb%2Fc%3Fd%23e%26f%3Dg")
  inspect(
    @percent.encode("中文🌙"),
    content="%E4%B8%AD%E6%96%87%F0%9F%8C%99",
  )
}
```

Unpaired surrogate code units are replaced by U+FFFD, so `encode` never
raises.

## Decoding

Use `decode` to reverse the escaping. Hexadecimal digits are accepted in
either case, escapes are decoded exactly once, and unescaped characters,
including `+` and non-ASCII text, are copied through unchanged.

```mbt check
///|
test "decode" {
  inspect(
    @percent.decode("Application%20Support"),
    content="Application Support",
  )
  inspect(@percent.decode("%e4%b8%ad%E6%96%87"), content="中文")
  inspect(@percent.decode("a+b%2520"), content="a+b%20")
}
```

## Malformed Input

`decode` raises `Malformed` when a `%` is not followed by two hexadecimal
digits, or when a run of escaped bytes is not valid UTF-8. The error carries
the whole input.

```mbt check
///|
test "malformed" {
  try {
    let _ = @percent.decode("a%zz")
    panic()
  } catch {
    Malformed(input) => inspect(input, content="a%zz")
  }
  try {
    let _ = @percent.decode("%C0%AF")
    panic()
  } catch {
    Malformed(input) => inspect(input, content="%C0%AF")
  }
}
```

`decode_lossy` repairs instead of raising: a malformed `%` is kept literally
and decoding resumes at the next character, and invalid escaped UTF-8 is
replaced by U+FFFD. It returns the same string as `decode` whenever `decode`
succeeds.

```mbt check
///|
test "decode_lossy" {
  inspect(@percent.decode_lossy("a%zz%20b"), content="a%zz b")
  inspect(@percent.decode_lossy("%2%41"), content="%2A")
  inspect(@percent.decode_lossy("%C0%AF"), content="\u{FFFD}\u{FFFD}")
}
```
